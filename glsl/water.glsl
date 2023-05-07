      // Original shader from: https://twitter.com/natchinoyuchi/status/1623349898967138304

      #ifdef GL_ES
precision highp float;
      #endif

uniform float time;
uniform vec2 resolution;

vec3 hsv(float h, float s, float v) {
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void twigl(out vec4 o, vec4 FC, vec2 r, float t) {
    o = vec4(0);
    float e, s = 0., g = 0.;
    for(float i = 1.; i <= 75.; i++) {
        mat2 m = rotate2D(t + i * .1);
        vec3 p = vec3((FC.xy / r - .5) * g * m, g - 5.);
        p.xz *= m;
        p /= i * .02;
        s = 5.;
        for(int j = 0; j < 7; j++) p.xy = abs(p.xy - i / 1e2) - i / 120., p.yz = abs(p.yz - i / 2e2) - i / 110., p *= e = 5. / dot(p, p), s *= e;
        g += min(.3, length(p) / s);
        o.xyz += hsv(s / 7e4, -i * .1, s / 2e5);
    }
}

void main(void) {
    twigl(gl_FragColor, gl_FragCoord, resolution, time);
    gl_FragColor.a = 1.;
}