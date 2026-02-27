#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

layout(binding = 1) uniform sampler2D source;

vec3 falseColorMap(float brightness) {
    if (brightness > 0.95) return vec3(1.0, 0.0, 0.0);
    if (brightness > 0.90) return vec3(1.0, 0.5, 0.0);
    if (brightness > 0.80) return vec3(1.0, 1.0, 0.0);
    if (brightness > 0.70) return vec3(1.0, 1.0, 0.5);
    if (brightness > 0.50) return vec3(0.7, 0.7, 0.7);
    if (brightness > 0.45) return vec3(1.0, 0.6, 0.6);
    if (brightness > 0.40) return vec3(0.5, 0.5, 0.5);
    if (brightness > 0.35) return vec3(0.0, 1.0, 0.0);
    if (brightness > 0.20) return vec3(0.0, 0.5, 0.5);
    if (brightness > 0.10) return vec3(0.0, 1.0, 1.0);
    if (brightness > 0.05) return vec3(0.0, 0.6, 0.8);
    if (brightness > 0.02) return vec3(0.0, 0.0, 1.0);
    return vec3(0.5, 0.0, 0.5);
}

void main() {
    vec4 color = texture(source, qt_TexCoord0);
    float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    fragColor = vec4(falseColorMap(brightness), 1.0) * qt_Opacity;
}
