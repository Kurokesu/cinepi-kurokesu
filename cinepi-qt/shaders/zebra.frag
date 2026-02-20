// Zebra pattern overlay - highlights overexposed areas
// Port of eglYuv.frag zebra pattern for Qt 5 ShaderEffect
varying highp vec2 qt_TexCoord0;
uniform sampler2D source;
uniform lowp float qt_Opacity;

uniform lowp float zebraThreshold;  // default 0.95
uniform highp float time;           // animated time for stripe motion

void main() {
    lowp vec4 color = texture2D(source, qt_TexCoord0);
    highp float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    if (brightness > zebraThreshold) {
        highp float speedFactor = 0.1;
        highp float stripeSize = 0.01;
        highp float stripePattern = mod(
            (qt_TexCoord0.x + qt_TexCoord0.y + time * speedFactor) / stripeSize,
            2.0
        );
        if (stripePattern < 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0) * qt_Opacity;
        } else {
            gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0) * qt_Opacity;
        }
    } else {
        gl_FragColor = color * qt_Opacity;
    }
}
