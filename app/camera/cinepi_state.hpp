#pragma once

#include <cstdint>

class CinePIState
{
public:
    CinePIState() = default;

    void setRecording(bool state) { is_recording_ = state; }
    bool isRecording() const { return is_recording_; }
    unsigned int getClipNumber() const { return clip_number_; }

protected:
    float framerate_ = 24.0f;
    bool is_recording_ = false;
    int iso_ = 8;               // analogue gain, or -1 = auto
    int awb_ = 0;               // Kelvin, or 0 = auto
    float shutter_speed_ = 0.0f;
    float shutter_angle_ = 180.0f; // degrees, or -1 = auto
    float cg_rb_[2] = {1.0f, 1.0f};

    uint16_t width_ = 1920;
    uint16_t height_ = 1080;
    int compression_ = 0;
    int thumbnail_ = 1;
    int thumbnail_size_ = 3;

    unsigned int clip_number_ = 0;
};
