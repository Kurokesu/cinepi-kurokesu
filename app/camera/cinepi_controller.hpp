#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <chrono>
#include <functional>
#include <mutex>
#include <unordered_map>
#include <fstream>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <json/json.h>

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
#define CONTROL_KEY_SHUTTER_SPEED "shutter_s"
#define CONTROL_KEY_FRAMERATE "fps"
#define CONTROL_KEY_WIDTH "width"
#define CONTROL_KEY_HEIGHT "height"
#define CONTROL_KEY_MODE "mode"
#define CONTROL_KEY_COMPRESSION "compress"
#define CONTROL_KEY_THUMBNAIL "thumbnail"
#define CONTROL_KEY_THUMBNAIL_SIZE "thumbnail_size"
#define CONTROL_KEY_RAW_CROP "raw_crop"
#define CONTROL_KEY_CAMERAINIT "cam_init"

class CinePIController : public CinePIState
{
    public:
        using StatsCallback = std::function<void(float framerate, int colorTemp,
                                                  float focus, int frameCount,
                                                  int bufferSize)>;
        using StreamInfoCallback = std::function<void(int width, int height)>;

        CinePIController(CinePIRecorder *app);
        ~CinePIController() = default;

        void loadSettings(const std::string &path);
        void saveSettings(const std::string &path);

        void sync();

        void handleControl(const std::string &key, const std::string &value);

        void applyAwb();
        void applyExposure();
        void process(CompletedRequestPtr &completed_request);
        void process_stream_info(libcamera::StreamConfiguration const &cfg);

        void setStatsCallback(StatsCallback cb) { statsCallback_ = std::move(cb); }
        void setStreamInfoCallback(StreamInfoCallback cb) { streamInfoCallback_ = std::move(cb); }

        bool folderOpen;
        bool cameraRunning;

        bool configChanged(){
            bool c = cameraInit_;
            cameraInit_ = false;
            return c;
        }

        int triggerRec(){
            if(!disk_mounted(const_cast<RawOptions *>(options_))){
                return 0;
            }
            int state = trigger_;
            if(state < 0){
                clip_number_++;
            }
            trigger_ = 0;
            return state;
        }

        unsigned int getISO() const { return iso_; }
        unsigned int getAWB() const { return awb_; }
        float getFramerate() const { return framerate_; }
        float getShutterAngle() const { return shutter_angle_; }
        float getShutterSpeed() const { return shutter_speed_; }
        float getColorGainR() const { return cg_rb_[0]; }
        float getColorGainB() const { return cg_rb_[1]; }
        int getCompression() const { return compression_; }
        uint16_t getWidth() const { return width_; }
        uint16_t getHeight() const { return height_; }

    private:
        void initHandlers();

        std::shared_ptr<spdlog::logger> console;

        int trigger_;
        bool cameraInit_;

        CinePIRecorder *app_;
        RawOptions *options_;

        using MessageHandler = std::function<void(const std::string &)>;
        std::unordered_map<std::string, MessageHandler> handlers_;

        StatsCallback statsCallback_;
        StreamInfoCallback streamInfoCallback_;
        std::string settingsPath_;
};
