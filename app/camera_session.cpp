#include "camera_session.hpp"
#include "logging.hpp"

#include "camera/cinepi_audio.hpp"
#include "camera/camera_backend.hpp"
#include "camera/dng_encoder.hpp"
#include <rpicam-apps/output/output.hpp>
#include <rpicam-apps/core/rpicam_app.hpp>

using namespace std::placeholders;

CameraSession::CameraSession(const QString &configDir, QObject *parent)
    : QThread(parent), configDir_(configDir)
{
}

CameraSession::~CameraSession()
{
    requestStop();
    wait();
}

void CameraSession::pause()
{
    std::lock_guard<std::mutex> lock(stateMutex_);
    if (state_ == State::Running)
        state_ = State::Paused;
}

void CameraSession::resume()
{
    {
        std::lock_guard<std::mutex> lock(stateMutex_);
        if (state_ == State::Paused)
            state_ = State::Running;
    }
    stateCV_.notify_one();
}

void CameraSession::requestStop()
{
    {
        std::lock_guard<std::mutex> lock(stateMutex_);
        state_ = State::Stopped;
    }
    stateCV_.notify_one();
}

void CameraSession::setInitialSettings(int isoGain, int shutterAngle,
                                       int fps, int colorTemp)
{
    Q_ASSERT(!isRunning());
    isoGain_ = isoGain;
    shutterAngle_ = shutterAngle;
    fps_ = fps;
    colorTemp_ = colorTemp;
}

void CameraSession::handleControl(const QString &key, const QString &value)
{
    std::lock_guard<std::mutex> lock(controlMutex_);
    pendingControls_.emplace_back(key.toStdString(), value.toStdString());
}

void CameraSession::run()
{
    auto log = cinepi::getLogger("camera.session");

    try {
        CinePIRecorder app;
        CinePIAudio audio(&app);
        CameraBackend controller(&app);

        RawOptions *options = app.GetOptions();

        std::string ppFile = (configDir_ + "/post-processing.json").toStdString();
        std::string tuningFile = "/usr/share/libcamera/ipa/rpi/pisp/imx283.json";

        std::vector<const char *> args = {
            "cinepi",
            "--post-process-file", ppFile.c_str(),
            "--tuning-file", tuningFile.c_str(),
            "-n",
            "--mode", "2784:1828:12:U",
            "--width", "960",
            "--height", "630",
            "--lores-width", "720",
            "--lores-height", "474",
        };
        int fake_argc = static_cast<int>(args.size());
        options->Parse(fake_argc, const_cast<char **>(args.data()));

        options->mediaDest = "/media/RAW";
        options->rawCrop[0] = 0;
        options->rawCrop[1] = 0;
        options->rawCrop[2] = 0;
        options->rawCrop[3] = 0;

        controller.setInitialValues(isoGain_, shutterAngle_, fps_, colorTemp_);

        controller.setStatsCallback(
            [this](float framerate, int colorTemp, float focus,
                   int frameCount, int bufferSize,
                   float exposureTime, float analogueGain) {
                Q_EMIT statsUpdated(framerate, colorTemp, focus,
                                   frameCount, bufferSize,
                                   exposureTime, analogueGain);
            });

        controller.setStreamInfoCallback(
            [this](int w, int h) {
                Q_EMIT streamInfoUpdated(w, h);
            });

        controller.sync();
        audio.start();

        std::unique_ptr<Output> output =
            std::unique_ptr<Output>(Output::Create(options));
        app.SetEncodeOutputReadyCallback(
            std::bind(&Output::OutputReady, output.get(), _1, _2, _3, _4));
        app.SetMetadataReadyCallback(
            std::bind(&Output::MetadataReady, output.get(), _1));

        log->info("Opening camera...");
        app.OpenCamera();
        log->info("Camera opened: {}", app.CameraModel());

        app.StartEncoder();
        auto cameras = app.GetCameras();
        if (cameras.empty())
            throw std::runtime_error("no cameras available");
        options->model = app.CameraModel();

        while (true) {
            if (state_.load() == State::Paused) {
                log->info("Camera session idle, waiting for resume");
                Q_EMIT sessionPaused();

                std::unique_lock<std::mutex> lock(stateMutex_);
                stateCV_.wait(lock, [this] {
                    return state_.load() != State::Paused;
                });
            }
            if (state_.load() == State::Stopped)
                break;

            Q_EMIT sessionResumed();

            bool initialSync = false;
            for (quint64 count = 0; state_.load() == State::Running; count++) {
                if (controller.configChanged()) {
                    log->info("Config changed, reconfiguring camera...");
                    if (controller.cameraRunning) {
                        app.StopCamera();
                        app.Teardown();
                    }
                    app.ConfigureVideo(CinePIRecorder::FLAG_VIDEO_RAW);
                    app.StartCamera();
                    controller.cameraRunning = true;
                    controller.applyAwb();
                    controller.applyExposure();

                    auto const &cfg = app.RawStream()->configuration();
                    log->info("Raw stream: {}x{} stride:{} fmt:{}",
                                  cfg.size.width, cfg.size.height,
                                  cfg.stride, cfg.pixelFormat.toString());
                    app.GetEncoder()->reset_encoder();
                    controller.process_stream_info(cfg);

                    if (!initialSync) {
                        initialSync = true;
                        Q_EMIT settingsLoaded(
                            gainToIso(controller.getGain()),
                            static_cast<int>(controller.getShutterAngle()),
                            static_cast<int>(controller.getFramerate()),
                            controller.getColorTemperature());
                    }
                }

                CinePIRecorder::Msg msg = app.Wait();

                if (state_.load() != State::Running)
                    break;

                if (msg.type == RPiCamApp::MsgType::Quit)
                    break;

                if (msg.type == RPiCamApp::MsgType::Timeout) {
                    log->error("Device timeout, restarting camera");
                    app.StopCamera();
                    app.StartCamera();
                    continue;
                }

                if (msg.type != CinePIRecorder::MsgType::RequestComplete)
                    throw std::runtime_error("unrecognised message");

                {
                    std::vector<std::pair<std::string, std::string>> controls;
                    {
                        std::lock_guard<std::mutex> lock(controlMutex_);
                        controls.swap(pendingControls_);
                    }
                    for (auto &[k, v] : controls)
                        controller.handleControl(k, v);
                }

                CompletedRequestPtr &completed_request =
                    std::get<CompletedRequestPtr>(msg.payload);

                controller.process(completed_request);

                int trigger = controller.triggerRec();
                if (trigger > 0) {
                    log->info("Recording started (clip #{})", controller.getClipNumber());
                    controller.folderOpen =
                        create_clip_folder(options, controller.getClipNumber());
                    app.GetEncoder()->resetFrameCount();
                    audio.record_start();
                } else if (trigger < 0) {
                    log->info("Recording stopped");
                    controller.folderOpen = false;
                    audio.record_stop();
                }

                if (controller.isRecording() && audio.isRecording() &&
                    controller.folderOpen) {
                    if (app.GetEncoder()->buffer_full()) {
                        log->warn("Disk buffer full, stopping recording");
                        controller.setRecording(false);
                    }
                    app.EncodeBuffer(completed_request, app.RawStream(),
                                     app.LoresStream());
                }

                if (state_.load() == State::Running) {
                    auto *stream = app.LoresStream();
                    if (!stream)
                        stream = app.GetMainStream();
                    if (stream) {
                        auto *buffer = completed_request->buffers[stream];
                        if (buffer) {
                            int fd = buffer->planes()[0].fd.get();
                            auto info = app.GetStreamInfo(stream);
                            Q_EMIT frameReady(fd, info.width, info.height,
                                            info.stride, count);
                        }
                    }
                }
            }

            if (controller.cameraRunning) {
                app.StopCamera();
                app.Teardown();
                controller.cameraRunning = false;
            }
            controller.requestReconfigure();
            log->info("Camera session paused");

            {
                std::lock_guard<std::mutex> lock(stateMutex_);
                if (state_ == State::Stopped)
                    break;
            }
        }
    }
    catch (std::exception const &e) {
        cinepi::getLogger("camera.session")->error("Camera error: {}", e.what());
        Q_EMIT cameraError(QString::fromStdString(e.what()));
    }

    log->info("Camera session thread exiting");
}
