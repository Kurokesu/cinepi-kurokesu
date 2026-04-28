/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * focuspeaking.frag - viewfinder focus peaking overlay.
 */

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float texWidth;
    float texHeight;
    float threshold;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 texelSize = vec2(1.0 / texWidth, 1.0 / texHeight);

    float center = dot(texture(source, qt_TexCoord0).rgb, vec3(0.299, 0.587, 0.114));
    float right  = dot(texture(source, qt_TexCoord0 + vec2(texelSize.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float bottom = dot(texture(source, qt_TexCoord0 + vec2(0.0, texelSize.y)).rgb, vec3(0.299, 0.587, 0.114));

    float gx = right - center;
    float gy = bottom - center;
    float edgeStrength = abs(gx) + abs(gy);

    vec4 color = texture(source, qt_TexCoord0);

    if (edgeStrength > threshold) {
        fragColor = vec4(1.0, 0.0, 0.0, 1.0) * qt_Opacity;
    } else {
        fragColor = color * qt_Opacity;
    }
}
