// False color overlay - maps brightness to diagnostic colors
// Port of eglYuv.frag false color mapping for Qt 5 ShaderEffect
varying highp vec2 qt_TexCoord0;
uniform sampler2D source;
uniform lowp float qt_Opacity;

vec3 falseColorMap(highp float brightness) {
    if (brightness > 0.95) return vec3(1.0, 0.0, 0.0);       // Clipping - Red
    if (brightness > 0.90) return vec3(1.0, 0.5, 0.0);       // Near clip - Orange
    if (brightness > 0.80) return vec3(1.0, 1.0, 0.0);       // Highlights - Yellow
    if (brightness > 0.70) return vec3(1.0, 1.0, 0.5);       // Bright - Light yellow
    if (brightness > 0.50) return vec3(0.7, 0.7, 0.7);       // Mid-high - Light grey
    if (brightness > 0.45) return vec3(1.0, 0.6, 0.6);       // Mid - Pink (skin tone)
    if (brightness > 0.40) return vec3(0.5, 0.5, 0.5);       // Mid - Grey
    if (brightness > 0.35) return vec3(0.0, 1.0, 0.0);       // Mid-low - Green
    if (brightness > 0.20) return vec3(0.0, 0.5, 0.5);       // Shadows - Teal
    if (brightness > 0.10) return vec3(0.0, 1.0, 1.0);       // Deep shadow - Cyan
    if (brightness > 0.05) return vec3(0.0, 0.6, 0.8);       // Near black - Blue-cyan
    if (brightness > 0.02) return vec3(0.0, 0.0, 1.0);       // Near black - Blue
    return vec3(0.5, 0.0, 0.5);                               // Black - Purple
}

void main() {
    lowp vec4 color = texture2D(source, qt_TexCoord0);
    highp float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    gl_FragColor = vec4(falseColorMap(brightness), 1.0) * qt_Opacity;
}
