precision mediump float;
uniform float time;
uniform vec2 resolution;

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y); // r は resolution
    float l = .3 * abs(sin(time)) / length(p);
    gl_FragColor = vec4(vec3(0, l, 2), 1.0);
}