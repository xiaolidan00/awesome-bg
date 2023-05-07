precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main(void) {
    vec2 position = (gl_FragCoord.xy / resolution.x);
    vec2 ms = (mouse * resolution / resolution.x);

    float d = length(position - ms);
    if(d <= 0.1) {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        gl_FragColor = vec4(1.0, 0, 0, 1.0);
    }

}