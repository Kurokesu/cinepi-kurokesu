#include "cinepi_controller.hpp"
#include "logging.h"

// IMX283 sensor-calibrated colour gains derived from the ct_curve in
// /usr/share/libcamera/ipa/rpi/pisp/imx283.json.  Values are 1/ct_ratio
// (the reciprocal of the raw R/G and B/G ratios at each colour temperature).
static void kelvinToColourGains(int kelvin, float &r_gain, float &b_gain)
{
    struct { int k; float r; float b; } const table[] = {
        { 2800, 1.17f, 2.86f },
        { 3200, 1.31f, 2.37f },
        { 4000, 1.55f, 1.91f },
        { 4500, 1.70f, 1.74f },
        { 5600, 1.90f, 1.57f },
        { 6500, 2.02f, 1.50f },
        { 7500, 2.14f, 1.44f },
        { 9000, 2.35f, 1.35f },
    };
    const size_t n = sizeof(table) / sizeof(table[0]);
    r_gain = 1.0f;
    b_gain = 1.0f;
    if (kelvin <= table[0].k)   { r_gain = table[0].r; b_gain = table[0].b; return; }
    if (kelvin >= table[n-1].k) { r_gain = table[n-1].r; b_gain = table[n-1].b; return; }
    for (size_t i = 0; i < n - 1; i++) {
        if (kelvin >= table[i].k && kelvin <= table[i+1].k) {
            float t = float(kelvin - table[i].k) / float(table[i+1].k - table[i].k);
            r_gain = table[i].r + t * (table[i+1].r - table[i].r);
            b_gain = table[i].b + t * (table[i+1].b - table[i].b);
            return;
        }
    }
}

CinePIController::CinePIController(CinePIRecorder *app)
    : CinePIState(),
      app_(app),
      options_(app->GetOptions())
{
    console = cinepi::getLogger("cinepi_controller");
    initHandlers();
}

void CinePIController::setInitialValues(int isoGain, float shutterAngle,
                                         float fps, int awb)
{
    iso_           = isoGain;
    shutter_angle_ = shutterAngle;
    framerate_     = fps;
    awb_           = awb;

    if (shutter_angle_ > 0)
        shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);

    console->info("Initial: ISO={} SHT={} FPS={} AWB={}",
                  gainToIso(iso_), shutter_angle_, framerate_, awb_);
}

void CinePIController::initHandlers()
{
    handlers_ = {
        { CONTROL_KEY_RECORD, [this](const std::string &v) {
            trigger_ = !is_recording_ ? 1 : -1;
            is_recording_ = (stoi(v) != 0);
            console->info("Record trigger: {}", is_recording_ ? "START" : "STOP");
        }},
        { CONTROL_KEY_ISO, [this](const std::string &v) {
            int val = stoi(v);
            if (val == 0) {
                console->warn("ISO: invalid value 0, ignoring");
                return;
            }
            iso_ = isoToGain(val);
            console->info("ISO: {}{}", val < 0 ? "AUTO" : std::to_string(val),
                          val > 0 ? " (gain=" + std::to_string(iso_) + ")" : "");
            libcamera::ControlList cl;
            if (iso_ < 0) {
                cl.set(libcamera::controls::AnalogueGainMode,
                       libcamera::controls::AnalogueGainModeAuto);
            } else {
                cl.set(libcamera::controls::AnalogueGainMode,
                       libcamera::controls::AnalogueGainModeManual);
                cl.set(libcamera::controls::AnalogueGain, iso_);
            }
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_WB, [this](const std::string &v) {
            awb_ = stoi(v);
            applyAwb();
        }},
        { CONTROL_KEY_COLORGAINS, [this](const std::string &v) {
            libcamera::ControlList cl;
            cl.set(libcamera::controls::AwbEnable, false);
            std::string cg = v;
            char *ptr = strtok(&cg[0], ",");
            uint8_t i = 0;
            while (ptr != NULL && i < 2) {
                cg_rb_[i] = static_cast<float>(stof(ptr));
                i++;
                ptr = strtok(NULL, ",");
            }
            cl.set(libcamera::controls::ColourGains,
                   libcamera::Span<const float, 2>({ cg_rb_[0], cg_rb_[1] }));
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_SHUTTER_ANGLE, [this](const std::string &v) {
            float val = stof(v);
            shutter_angle_ = val;
            libcamera::ControlList cl;
            if (shutter_angle_ < 0) {
                cl.set(libcamera::controls::ExposureTimeMode,
                       libcamera::controls::ExposureTimeModeAuto);
                console->info("Shutter: AUTO");
            } else if (shutter_angle_ > 0 && framerate_ > 0) {
                shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
                uint64_t shutterTime = shutter_speed_ * 1e+6;
                cl.set(libcamera::controls::ExposureTimeMode,
                       libcamera::controls::ExposureTimeModeManual);
                cl.set(libcamera::controls::ExposureTime, shutterTime);
                console->info("Shutter: {}deg -> {}us", shutter_angle_, shutterTime);
            } else {
                console->warn("Shutter: invalid angle {}, ignoring", shutter_angle_);
                return;
            }
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_WIDTH, [this](const std::string &v) {
            width_ = static_cast<uint16_t>(stoi(v));
            options_->Set().width = width_;
        }},
        { CONTROL_KEY_HEIGHT, [this](const std::string &v) {
            height_ = static_cast<uint16_t>(stoi(v));
            options_->Set().height = height_;
        }},
        { CONTROL_KEY_COMPRESSION, [this](const std::string &v) {
            compression_ = stoi(v);
            options_->compression = compression_;
            cameraInit_ = true;
        }},
        { CONTROL_KEY_FRAMERATE, [this](const std::string &v) {
            framerate_ = stof(v);
            console->info("Framerate: {:.1f}", framerate_);
            options_->Set().framerate = framerate_;
            long int durationValues[2] = {
                static_cast<long int>(1000000.0 / framerate_),
                static_cast<long int>(1000000.0 / framerate_)
            };
            libcamera::Span<const long int, 2> durationRange(durationValues, 2);
            libcamera::ControlList cl;
            cl.set(libcamera::controls::FrameDurationLimits, durationRange);
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_CAMERAINIT, [this](const std::string &) {
            cameraInit_ = true;
        }},
        { CONTROL_KEY_THUMBNAIL, [this](const std::string &v) {
            options_->thumbnail = stoi(v);
        }},
        { CONTROL_KEY_THUMBNAIL_SIZE, [this](const std::string &v) {
            options_->thumbnailSize = stoi(v);
            cameraInit_ = true;
        }},
        { "log_level", [this](const std::string &v) {
            spdlog::set_level(spdlog::level::from_str(v));
        }},
    };
}

void CinePIController::handleControl(const std::string &key, const std::string &value)
{
    auto it = handlers_.find(key);
    if (it != handlers_.end()) {
        it->second(value);
    } else {
        console->warn("Unknown control key: {}", key);
    }
}

void CinePIController::sync()
{
    libcamera::ControlList cl;
    cl.set(libcamera::controls::rpi::StatsOutputEnable, true);
    app_->SetControls(cl);

    options_->thumbnail    = thumbnail_;
    options_->thumbnailSize = thumbnail_size_;
    options_->compression  = compression_;
    options_->Set().framerate = framerate_;
    options_->Set().gain     = (iso_ < 0) ? 0 : iso_;
    options_->awbEn = (awb_ == 0);
    options_->Set().denoise  = "off";
    options_->Set().mode_string = "0:0:0:0";
}

void CinePIController::applyExposure()
{
    libcamera::ControlList cl;

    if (shutter_angle_ < 0) {
        cl.set(libcamera::controls::ExposureTimeMode,
               libcamera::controls::ExposureTimeModeAuto);
        console->info("Shutter: AUTO");
    } else if (shutter_angle_ > 0 && framerate_ > 0) {
        shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
        uint64_t shutterTime = shutter_speed_ * 1e+6;
        cl.set(libcamera::controls::ExposureTimeMode,
               libcamera::controls::ExposureTimeModeManual);
        cl.set(libcamera::controls::ExposureTime, shutterTime);
        console->info("Shutter: {}deg -> {}us", shutter_angle_, shutterTime);
    }

    if (iso_ < 0) {
        cl.set(libcamera::controls::AnalogueGainMode,
               libcamera::controls::AnalogueGainModeAuto);
        console->info("ISO: AUTO");
    } else {
        cl.set(libcamera::controls::AnalogueGainMode,
               libcamera::controls::AnalogueGainModeManual);
        cl.set(libcamera::controls::AnalogueGain, iso_);
        console->info("ISO: {} (gain={})", gainToIso(iso_), iso_);
    }

    app_->SetControls(cl);
}

void CinePIController::applyAwb()
{
    libcamera::ControlList cl;
    if (awb_ == 0) {
        console->info("AWB: AUTO");
        cl.set(libcamera::controls::AwbEnable, true);
    } else {
        float r_gain, b_gain;
        kelvinToColourGains(awb_, r_gain, b_gain);
        cg_rb_[0] = r_gain;
        cg_rb_[1] = b_gain;
        console->info("AWB: {}K -> ColourGains R={:.2f} B={:.2f}", awb_, r_gain, b_gain);
        cl.set(libcamera::controls::AwbEnable, false);
        cl.set(libcamera::controls::ColourGains,
               libcamera::Span<const float, 2>({ r_gain, b_gain }));
    }
    app_->SetControls(cl);
}

void CinePIController::process(CompletedRequestPtr &completed_request)
{
    CinePIFrameInfo info(completed_request);

    if (statsCallback_) {
        statsCallback_(
            completed_request->framerate,
            info.colorTemp,
            info.focus,
            app_->GetEncoder()->getFrameCount(),
            app_->GetEncoder()->bufferSize(),
            info.exposure_time,
            info.analogue_gain
        );
    }
}

void CinePIController::process_stream_info(libcamera::StreamConfiguration const &cfg)
{
    width_  = cfg.size.width;
    height_ = cfg.size.height;

    if (streamInfoCallback_)
        streamInfoCallback_(cfg.size.width, cfg.size.height);
}
