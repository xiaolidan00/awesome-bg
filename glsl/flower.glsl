precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float MAX_ITER = 80.0;

float iteration(float a, float b, float c, float d) {
    for(float i = 0.0; i < MAX_ITER; i++) {
        if(a * a + b * b > 10.0) {
            return i;
        } else {
            float x = a * a - b * b + c;
            float y = 2.0 * a * b + d;
            a = x;
            b = y;
        }
    }
    return MAX_ITER;
}

void main(void) {

    vec2 position = (gl_FragCoord.xy / resolution.x) + mouse / 4.0;

    float delta = 1.25 * (sin(time * 0.2) + 1.0);

    float x = position.x - 0.92;
    float y = position.y + 0.00;

    float c_x = -0.54;
    float c_y = 0.54 - 0.015 * delta;

    float length = iteration(x, y, c_x, c_y);
          // float color   = 1.0 - length;
    float color = length / MAX_ITER;
    gl_FragColor = vec4(color - 0.9, color - 0.1 * delta, color, 1.0);
}