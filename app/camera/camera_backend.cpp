/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * camera_backend.cpp - camera control handlers and per-frame stats.
 */

#include "camera_backend.hpp"
#include "logging.hpp"

CameraBackend::CameraBackend(CinePIRecorder *app)
    : CinePIState(),
      app_(app),
      options_(app->GetOptions())
{
    logger_ = cinepi::getLogger("camera.backend");
    initHandlers();
}

void CameraBackend::setInitialValues(int isoGain, float shutterAngle,
                                         float fps, int awb)
{
    iso_           = isoGain;
    shutter_angle_ = shutterAngle;
    framerate_     = fps;
    awb_           = awb;

    if (shutter_angle_ > 0)
        shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);

    logger_->info("Initial: ISO={} SHT={} FPS={} AWB={}",
                  gainToIso(iso_), shutter_angle_, framerate_, awb_);
}

void CameraBackend::initHandlers()
{
    handlers_ = {
        { CONTROL_KEY_RECORD, [this](const std::string &v) {
            trigger_ = !is_recording_ ? 1 : -1;
            is_recording_ = (std::stoi(v) != 0);
            logger_->info("Record trigger: {}", is_recording_ ? "START" : "STOP");
        }},
        { CONTROL_KEY_ISO, [this](const std::string &v) {
            int val = std::stoi(v);
            if (val == 0) {
                logger_->warn("ISO: invalid value 0, ignoring");
                return;
            }
            iso_ = isoToGain(val);
            logger_->info("ISO: {}{}", val < 0 ? "AUTO" : std::to_string(val),
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
            awb_ = std::stoi(v);
            applyAwb();
        }},
        { CONTROL_KEY_COLORGAINS, [this](const std::string &v) {
            libcamera::ControlList cl;
            cl.set(libcamera::controls::AwbEnable, false);
            std::string cg = v;
            char *ptr = strtok(&cg[0], ",");
            uint8_t i = 0;
            while (ptr != NULL && i < 2) {
                cg_rb_[i] = static_cast<float>(std::stof(ptr));
                i++;
                ptr = strtok(NULL, ",");
            }
            cl.set(libcamera::controls::ColourGains,
                   libcamera::Span<const float, 2>({ cg_rb_[0], cg_rb_[1] }));
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_SHUTTER_ANGLE, [this](const std::string &v) {
            float val = std::stof(v);
            shutter_angle_ = val;
            libcamera::ControlList cl;
            if (shutter_angle_ < 0) {
                cl.set(libcamera::controls::ExposureTimeMode,
                       libcamera::controls::ExposureTimeModeAuto);
                logger_->info("Shutter: AUTO");
            } else if (shutter_angle_ > 0 && framerate_ > 0) {
                shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
                uint64_t shutterTime = shutter_speed_ * 1e+6;
                cl.set(libcamera::controls::ExposureTimeMode,
                       libcamera::controls::ExposureTimeModeManual);
                cl.set(libcamera::controls::ExposureTime, shutterTime);
                logger_->info("Shutter: {}deg -> {}us", shutter_angle_, shutterTime);
            } else {
                logger_->warn("Shutter: invalid angle {}, ignoring", shutter_angle_);
                return;
            }
            app_->SetControls(cl);
        }},
        { CONTROL_KEY_WIDTH, [this](const std::string &v) {
            width_ = static_cast<uint16_t>(std::stoi(v));
            options_->Set().width = width_;
        }},
        { CONTROL_KEY_HEIGHT, [this](const std::string &v) {
            height_ = static_cast<uint16_t>(std::stoi(v));
            options_->Set().height = height_;
        }},
        { CONTROL_KEY_COMPRESSION, [this](const std::string &v) {
            compression_ = std::stoi(v);
            options_->compression = compression_;
            cameraInit_ = true;
        }},
        { CONTROL_KEY_FRAMERATE, [this](const std::string &v) {
            framerate_ = std::stof(v);
            logger_->info("Framerate: {:.1f}", framerate_);
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
            options_->thumbnail = std::stoi(v);
        }},
        { CONTROL_KEY_THUMBNAIL_SIZE, [this](const std::string &v) {
            options_->thumbnailSize = std::stoi(v);
            cameraInit_ = true;
        }},
        { "log_level", [this](const std::string &v) {
            spdlog::set_level(spdlog::level::from_str(v));
        }},
    };
}

void CameraBackend::handleControl(const std::string &key, const std::string &value)
{
    auto it = handlers_.find(key);
    if (it != handlers_.end()) {
        it->second(value);
    } else {
        logger_->warn("Unknown control key: {}", key);
    }
}

void CameraBackend::sync()
{
    libcamera::ControlList cl;
    cl.set(libcamera::controls::rpi::StatsOutputEnable, true);
    app_->SetControls(cl);

    options_->thumbnail    = thumbnail_;
    options_->thumbnailSize = thumbnail_size_;
    options_->compression  = compression_;
    options_->Set().framerate = framerate_;
    options_->Set().denoise  = "off";
}

void CameraBackend::applyExposure()
{
    libcamera::ControlList cl;

    if (shutter_angle_ < 0) {
        cl.set(libcamera::controls::ExposureTimeMode,
               libcamera::controls::ExposureTimeModeAuto);
        logger_->info("Shutter: AUTO");
    } else if (shutter_angle_ > 0 && framerate_ > 0) {
        shutter_speed_ = 1.0 / ((framerate_ * 360.0) / shutter_angle_);
        uint64_t shutterTime = shutter_speed_ * 1e+6;
        cl.set(libcamera::controls::ExposureTimeMode,
               libcamera::controls::ExposureTimeModeManual);
        cl.set(libcamera::controls::ExposureTime, shutterTime);
        logger_->info("Shutter: {}deg -> {}us", shutter_angle_, shutterTime);
    }

    if (iso_ < 0) {
        cl.set(libcamera::controls::AnalogueGainMode,
               libcamera::controls::AnalogueGainModeAuto);
        logger_->info("ISO: AUTO");
    } else {
        cl.set(libcamera::controls::AnalogueGainMode,
               libcamera::controls::AnalogueGainModeManual);
        cl.set(libcamera::controls::AnalogueGain, iso_);
        logger_->info("ISO: {} (gain={})", gainToIso(iso_), iso_);
    }

    app_->SetControls(cl);
}

void CameraBackend::applyAwb()
{
    libcamera::ControlList cl;
    if (awb_ == 0) {
        logger_->info("AWB: AUTO");
        cl.set(libcamera::controls::AwbEnable, true);
    } else {
        logger_->info("AWB: {}K", awb_);
        cl.set(libcamera::controls::AwbEnable, false);
        cl.set(libcamera::controls::ColourTemperature, awb_);
    }
    app_->SetControls(cl);
}

void CameraBackend::process(CompletedRequestPtr &completed_request)
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

void CameraBackend::process_stream_info(libcamera::StreamConfiguration const &cfg)
{
    width_  = cfg.size.width;
    height_ = cfg.size.height;

    if (streamInfoCallback_)
        streamInfoCallback_(cfg.size.width, cfg.size.height);
}
