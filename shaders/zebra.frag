#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float zebraThreshold;
    float time;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 color = texture(source, qt_TexCoord0);
    float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    if (brightness > zebraThreshold) {
        float speedFactor = 0.1;
        float stripeSize = 0.01;
        float stripePattern = mod(
            (qt_TexCoord0.x + qt_TexCoord0.y + time * speedFactor) / stripeSize,
            2.0
        );
        if (stripePattern < 1.0) {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0) * qt_Opacity;
        } else {
            fragColor = vec4(1.0, 1.0, 1.0, 1.0) * qt_Opacity;
        }
    } else {
        fragColor = color * qt_Opacity;
    }
}
