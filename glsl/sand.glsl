#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;

const float Pi = 3.14159;
uniform vec2 mouse;

const int complexity = 100;    // More points of color.
const float mouse_factor = 20.0;  // Makes it more/less jumpy.
const float mouse_offset = 20.5;   // Drives complexity in the amount of curls/cuves.  Zero is a single whirlpool.
const float fluid_speed = 3.0;  // Drives speed, higher number will make it slower.
const float color_intensity = 5.0;

void main() {
    vec2 p = (2.0 * gl_FragCoord.xy - resolution) / max(resolution.x, resolution.y);
    for(int i = 1; i < complexity; i++) {
        vec2 newp = p + time * 0.001;
        newp.x += 0.6 / float(i) * sin(float(i) * p.y + time / fluid_speed + 0.3 * float(i)) + 0.5; // + mouse.y/mouse_factor+mouse_offset;
        newp.y += 0.6 / float(i) * sin(float(i) * p.x + time / fluid_speed + 0.3 * float(i + 10)) - 0.5; // - mouse.x/mouse_factor+mouse_offset;
        p = newp;
    }

  // Change the mix ratio to increase the marble feel and change the white color to a light blue color
    float mix_ratio = 0.9 * sin(1.0 * p.x) + 0.1;
    vec3 col = mix(vec3(0.1, 0.1, 1), vec3(0.3, 0.7, 1), mix_ratio);
    gl_FragColor = vec4(col, 1.0);
}