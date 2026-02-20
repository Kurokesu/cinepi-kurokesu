// Focus peaking overlay - highlights in-focus edges in red
// Port of eglYuv.frag gradient edge detection for Qt 5 ShaderEffect
varying highp vec2 qt_TexCoord0;
uniform sampler2D source;
uniform lowp float qt_Opacity;

uniform highp float texWidth;   // source texture width in pixels
uniform highp float texHeight;  // source texture height in pixels
uniform lowp float threshold;   // edge detection threshold (default 0.08)

void main() {
    highp vec2 texelSize = vec2(1.0 / texWidth, 1.0 / texHeight);

    // Sample luminance at current pixel and neighbors
    highp float center = dot(texture2D(source, qt_TexCoord0).rgb, vec3(0.299, 0.587, 0.114));
    highp float right  = dot(texture2D(source, qt_TexCoord0 + vec2(texelSize.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    highp float bottom = dot(texture2D(source, qt_TexCoord0 + vec2(0.0, texelSize.y)).rgb, vec3(0.299, 0.587, 0.114));

    // Gradient magnitude (simple Sobel-like)
    highp float gx = right - center;
    highp float gy = bottom - center;
    highp float edgeStrength = abs(gx) + abs(gy);

    lowp vec4 color = texture2D(source, qt_TexCoord0);

    if (edgeStrength > threshold) {
        // Highlight edges in red
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0) * qt_Opacity;
    } else {
        gl_FragColor = color * qt_Opacity;
    }
}
