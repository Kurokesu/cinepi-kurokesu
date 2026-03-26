#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <time.h>
#include <stdint.h>

#include <rpicam-apps/core/logging.hpp>

#include <chrono>
#include <iostream>
#include <stdexcept>

#include <mutex>
#include <queue>
#include <thread>

class CinePIState
{
    public:
        CinePIState() : is_recording_(false), clip_number_(0), still_number_(0) {};
        ~CinePIState() {};

        void setRecording(bool state){
            is_recording_ = state;
        }

        bool isRecording(){
            return is_recording_;
        }

        unsigned int getClipNumber(){
            return clip_number_;
        }

    protected:
        float framerate_;
        bool is_recording_;
        unsigned int iso_;
        unsigned int awb_;
        float shutter_speed_;
        float shutter_angle_;
        unsigned int color_temp_;
        float cg_rb_[2];

        uint16_t width_;
        uint16_t height_;
        int mode_;
        int compression_;

        int thumbnail_;
        int thumbnail_size_;

        unsigned int clip_number_;
        unsigned int still_number_;
};