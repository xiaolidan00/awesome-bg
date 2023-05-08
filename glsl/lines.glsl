#extension GL_OES_standard_derivatives : enable

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution * .7) / max(resolution.x, resolution.y) * 3.0;
    uv *= 1.0;
    float e = .0;
    float a;
    for(float i = 2.0; i <= 104.0; i += 2.0) {
        float A = (i / 18.);
        float A2 = (i / 4.9);
        float A3 = (i * 0.15);
        float T = (time / 1.0);
        float T2 = (time / 9.0);
        e += .005 / abs(A + sin(T + A3 * uv.x * cos(A2 + T2 + uv.x * 2.2)) + 3.5 * uv.y);
        gl_FragColor = vec4(vec3(e / 3.1, e / 1.6, e / 2.6), 6.0);

    }
}