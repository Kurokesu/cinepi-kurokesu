#include "CameraWorker.h"
#include "logging.h"

#include "camera/cinepi_sound.hpp"
#include "camera/cinepi_controller.hpp"
#include "camera/dng_encoder.hpp"
#include <rpicam-apps/output/output.hpp>
#include <rpicam-apps/core/rpicam_app.hpp>

using namespace std::placeholders;

CameraWorker::CameraWorker(const QString &configDir, QObject *parent)
    : QThread(parent), configDir_(configDir)
{
}

CameraWorker::~CameraWorker()
{
    requestStop();
    wait();
}

void CameraWorker::requestStop()
{
    stopRequested_ = true;
}

void CameraWorker::setInitialSettings(int isoGain, int shutterAngle,
                                       int fps, int colorTemp)
{
    isoGain_ = isoGain;
    shutterAngle_ = shutterAngle;
    fps_ = fps;
    colorTemp_ = colorTemp;
}

void CameraWorker::handleControl(const QString &key, const QString &value)
{
    std::lock_guard<std::mutex> lock(controlMutex_);
    pendingControls_.emplace_back(key.toStdString(), value.toStdString());
}

void CameraWorker::run()
{
    auto log = cinepi::getLogger("camera.worker");

    try {
        CinePIRecorder app;
        CinePISound sound(&app);
        CinePIController controller(&app);

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
        sound.start();

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

        bool initialSync = false;
        for (unsigned int count = 0; !stopRequested_; count++) {
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

            if (stopRequested_)
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
                sound.record_start();
            } else if (trigger < 0) {
                log->info("Recording stopped");
                controller.folderOpen = false;
                sound.record_stop();
            }

            if (controller.isRecording() && sound.isRecording() &&
                controller.folderOpen) {
                if (app.GetEncoder()->buffer_full()) {
                    log->warn("Disk buffer full, stopping recording");
                    controller.setRecording(false);
                }
                app.EncodeBuffer(completed_request, app.RawStream(),
                                 app.LoresStream());
            }

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

        if (controller.cameraRunning) {
            app.StopCamera();
            app.Teardown();
        }

        log->info("Camera worker stopped");
    }
    catch (std::exception const &e) {
        cinepi::getLogger("camera.worker")->error("Camera error: {}", e.what());
        Q_EMIT cameraError(QString::fromStdString(e.what()));
    }
}
