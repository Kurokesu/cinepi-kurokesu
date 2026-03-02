#include "cinepi_controller.hpp"
#include "logging.h"

using namespace std;
using namespace std::chrono;

#define CP_DEF_WIDTH 1920

// IMX283 sensor-calibrated colour gains derived from the ct_curve in
// /usr/share/libcamera/ipa/rpi/pisp/imx283.json.  Values are 1/ct_ratio
// (the reciprocal of the raw R/G and B/G ratios at each colour temperature).
static void kelvinToColourGains(int kelvin, float& r_gain, float& b_gain) {
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
    if (kelvin <= table[0].k)       { r_gain = table[0].r; b_gain = table[0].b; return; }
    if (kelvin >= table[n-1].k)     { r_gain = table[n-1].r; b_gain = table[n-1].b; return; }
    for (size_t i = 0; i < n - 1; i++) {
        if (kelvin >= table[i].k && kelvin <= table[i+1].k) {
            float t = (float)(kelvin - table[i].k) / (float)(table[i+1].k - table[i].k);
            r_gain = table[i].r + t * (table[i+1].r - table[i].r);
            b_gain = table[i].b + t * (table[i+1].b - table[i].b);
            return;
        }
    }
}

#define CP_DEF_HEIGHT 1080
#define CP_DEF_FRAMERATE 30
#define CP_DEF_ISO 400
#define CP_DEF_SHUTTER 50
#define CP_DEF_AWB 0
#define CP_DEF_COMPRESS 0
#define CP_DEF_THUMBNAIL 1
#define CP_DEF_THUMBNAIL_SIZE 3

CinePIController::CinePIController(CinePIRecorder *app)
    : CinePIState(),
      app_(app),
      folderOpen(false),
      cameraRunning(false),
      trigger_(0),
      options_(app->GetOptions()),
      cameraInit_(true)
{
    console = cinepi::getLogger("cinepi_controller");
    initHandlers();
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
            iso_ = (unsigned int)(stoi(v) / 100.0);
            console->info("ISO: {} (gain={})", stoi(v), iso_);
            libcamera::ControlList cl;
            cl.set(libcamera::controls::AnalogueGain, iso_);
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_WB, [this](const std::string &v) {
            awb_ = (unsigned int)stoi(v);
            applyAwb();
        }},
        { CONTROL_KEY_COLORGAINS, [this](const std::string &v) {
            libcamera::ControlList cl;
            cl.set(libcamera::controls::AwbEnable, false);
            std::string cg = v;
            char *ptr = strtok(&cg[0], ",");
            uint8_t i = 0;
            while (ptr != NULL && i < 2) {
                cg_rb_[i] = (float)stof(ptr);
                i++;
                ptr = strtok(NULL, ",");
            }
            cl.set(libcamera::controls::ColourGains,
                   libcamera::Span<const float, 2>({ cg_rb_[0], cg_rb_[1] }));
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_SHUTTER_ANGLE, [this](const std::string &v) {
            shutter_angle_ = stof(v);
            shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
            uint64_t shutterTime = shutter_speed_ * 1e+6;
            console->info("Shutter: {}° -> {:.0f}us", shutter_angle_, (double)shutterTime);
            libcamera::ControlList cl;
            cl.set(libcamera::controls::AeEnable, false);
            cl.set(libcamera::controls::ExposureTime, shutterTime);
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_SHUTTER_SPEED, [this](const std::string &v) {
            shutter_speed_ = 1.0 / stof(v);
            uint64_t shutterTime = shutter_speed_ * 1e+6;
            libcamera::ControlList cl;
            cl.set(libcamera::controls::ExposureTime, shutterTime);
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_WIDTH, [this](const std::string &v) {
            width_ = (uint16_t)(stoi(v));
            options_->Set().width = width_;
            console->debug("Width: {}", width_);
        }},
        { CONTROL_KEY_HEIGHT, [this](const std::string &v) {
            height_ = (uint16_t)(stoi(v));
            options_->Set().height = height_;
            console->debug("Height: {}", height_);
        }},
        { CONTROL_KEY_COMPRESSION, [this](const std::string &v) {
            compression_ = stoi(v);
            console->debug("Compression: {}", compression_);
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

void CinePIController::loadSettings(const std::string &path)
{
    settingsPath_ = path;

    Json::Value root;
    std::ifstream file(path);
    if (file.is_open()) {
        Json::CharReaderBuilder builder;
        std::string errs;
        if (Json::parseFromStream(builder, file, &root, &errs)) {
            width_          = root.get("width", CP_DEF_WIDTH).asInt();
            height_         = root.get("height", CP_DEF_HEIGHT).asInt();
            framerate_      = root.get("fps", CP_DEF_FRAMERATE).asFloat();
            iso_            = root.get("iso", CP_DEF_ISO).asInt();
            shutter_angle_  = root.get("shutter_a", 180.0f).asFloat();
            shutter_speed_  = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
            awb_            = root.get("awb", CP_DEF_AWB).asInt();
            compression_    = root.get("compress", CP_DEF_COMPRESS).asInt();
            thumbnail_      = root.get("thumbnail", CP_DEF_THUMBNAIL).asInt();
            thumbnail_size_ = root.get("thumbnail_size", CP_DEF_THUMBNAIL_SIZE).asInt();

            std::string cg = root.get("cg_rb", "").asString();
            if (!cg.empty()) {
                auto pos = cg.find(',');
                if (pos != std::string::npos) {
                    cg_rb_[0] = stof(cg.substr(0, pos));
                    cg_rb_[1] = stof(cg.substr(pos + 1));
                }
            }
            console->info("Settings loaded from {}", path);
            return;
        }
        console->warn("Failed to parse {}: {}", path, errs);
    }

    // Defaults
    width_          = CP_DEF_WIDTH;
    height_         = CP_DEF_HEIGHT;
    framerate_      = CP_DEF_FRAMERATE;
    iso_            = CP_DEF_ISO;
    shutter_angle_  = 180.0f;
    shutter_speed_  = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
    awb_            = CP_DEF_AWB;
    compression_    = CP_DEF_COMPRESS;
    thumbnail_      = CP_DEF_THUMBNAIL;
    thumbnail_size_ = CP_DEF_THUMBNAIL_SIZE;
    cg_rb_[0]       = 1.0f;
    cg_rb_[1]       = 1.0f;

    console->info("Using default settings (no settings file)");
}

void CinePIController::saveSettings(const std::string &path)
{
    Json::Value root;
    root["width"]          = width_;
    root["height"]         = height_;
    root["fps"]            = framerate_;
    root["iso"]            = (int)iso_;
    root["shutter_a"]      = shutter_angle_;
    root["awb"]            = (int)awb_;
    root["compress"]       = compression_;
    root["thumbnail"]      = thumbnail_;
    root["thumbnail_size"] = thumbnail_size_;
    root["cg_rb"]          = std::to_string(cg_rb_[0]) + "," + std::to_string(cg_rb_[1]);

    std::ofstream file(path);
    if (file.is_open()) {
        Json::StreamWriterBuilder builder;
        builder["indentation"] = "  ";
        file << Json::writeString(builder, root);
        console->debug("Settings saved to {}", path);
    } else {
        console->warn("Failed to save settings to {}", path);
    }
}

void CinePIController::handleControl(const std::string &key, const std::string &value)
{
    auto it = handlers_.find(key);
    if (it != handlers_.end()) {
        it->second(value);
        if (!settingsPath_.empty())
            saveSettings(settingsPath_);
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
    options_->Set().gain     = iso_;
    options_->awbEn = (awb_ == 0);
    options_->Set().denoise  = "off";
    options_->Set().mode_string = "0:0:0:0";
}

void CinePIController::applyExposure() {
    shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
    uint64_t shutterTime = shutter_speed_ * 1e+6;
    console->info("Exposure: {}° {:.0f}us, ISO {} (gain={})",
                  shutter_angle_, (double)shutterTime, iso_ * 100, iso_);
    libcamera::ControlList cl;
    cl.set(libcamera::controls::AeEnable, false);
    cl.set(libcamera::controls::ExposureTime, shutterTime);
    cl.set(libcamera::controls::AnalogueGain, iso_);
    app_->SetControls(cl);
}

void CinePIController::applyAwb() {
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
            app_->GetEncoder()->bufferSize()
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
