/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * camera_backend.hpp - camera control handlers and per-frame stats.
 */

#pragma once

#include <algorithm>
#include <cstdint>
#include <functional>
#include <string>
#include <unordered_map>

#include <spdlog/spdlog.h>

#include "cinepi_recorder.hpp"
#include "cinepi_frameinfo.hpp"
#include "cinepi_state.hpp"
#include "raw_options.hpp"
#include "dng_encoder.hpp"
#include "utils.hpp"

#define CONTROL_KEY_RECORD "is_recording"
#define CONTROL_KEY_ISO "iso"
#define CONTROL_KEY_WB "awb"
#define CONTROL_KEY_COLORGAINS "cg_rb"
#define CONTROL_KEY_SHUTTER_ANGLE "shutter_a"
#define CONTROL_KEY_FRAMERATE "fps"
#define CONTROL_KEY_WIDTH "width"
#define CONTROL_KEY_HEIGHT "height"
#define CONTROL_KEY_COMPRESSION "compress"
#define CONTROL_KEY_CAMERAINIT "cam_init"
#define CONTROL_KEY_THUMBNAIL "thumbnail"
#define CONTROL_KEY_THUMBNAIL_SIZE "thumbnail_size"

inline int isoToGain(int iso) { return iso > 0 ? std::max(1, iso / 100) : iso; }
inline int gainToIso(int gain) { return gain > 0 ? gain * 100 : gain; }

class CameraBackend : public CinePIState
{
public:
    using StatsCallback = std::function<void(float framerate, int colorTemp,
                                              float focus, int frameCount,
                                              int bufferSize,
                                              float exposureTime,
                                              float analogueGain)>;
    using StreamInfoCallback = std::function<void(int width, int height)>;

    CameraBackend(CinePIRecorder *app);

    void setInitialValues(int isoGain, float shutterAngle, float fps, int awb);
    void sync();

    void handleControl(const std::string &key, const std::string &value);

    void applyAwb();
    void applyExposure();
    void process(CompletedRequestPtr &completed_request);
    void process_stream_info(libcamera::StreamConfiguration const &cfg);

    void setStatsCallback(StatsCallback cb) { statsCallback_ = std::move(cb); }
    void setStreamInfoCallback(StreamInfoCallback cb) { streamInfoCallback_ = std::move(cb); }

    bool folderOpen = false;
    bool cameraRunning = false;

    bool configChanged() {
        bool c = cameraInit_;
        cameraInit_ = false;
        return c;
    }

    void requestReconfigure() { cameraInit_ = true; }

    int triggerRec() {
        if (!disk_mounted(const_cast<RawOptions *>(options_)))
            return 0;
        int state = trigger_;
        if (state < 0)
            clip_number_++;
        trigger_ = 0;
        return state;
    }

    int getGain() const { return iso_; }
    int getColorTemperature() const { return awb_; }
    float getFramerate() const { return framerate_; }
    float getShutterAngle() const { return shutter_angle_; }
    float getColorGainR() const { return cg_rb_[0]; }
    float getColorGainB() const { return cg_rb_[1]; }
    int getCompression() const { return compression_; }
    uint16_t getWidth() const { return width_; }
    uint16_t getHeight() const { return height_; }

private:
    void initHandlers();

    std::shared_ptr<spdlog::logger> logger_;

    int trigger_ = 0;
    bool cameraInit_ = true;

    CinePIRecorder *app_;
    RawOptions *options_;

    using MessageHandler = std::function<void(const std::string &)>;
    std::unordered_map<std::string, MessageHandler> handlers_;

    StatsCallback statsCallback_;
    StreamInfoCallback streamInfoCallback_;
};
