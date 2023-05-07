      // Original shader from: https://twitter.com/zozuar/status/1492217553103503363

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

void twigl(out vec4 o, vec4 FC, vec2 r, float t) {
    o = vec4(0);
    float e = 0., R = 0., s;
    vec3 q = vec3(0), p, d = vec3((FC.xy - .5 * r) / r.y, .7);
    q.z--;
    for(float i = 0.; i < 1e2; i++) {
        o.rgb += hsv(.1, e * .4, e / 1e2) + .005;
        p = q += d * max(e, .02) * R * .3;
        p = vec3(log(R = length(p)) - t, e = asin(-p.z / R) - 1., atan(p.x, p.y) + t / 3.);
        s = 1.;
        for(int j = 0; j < 10; j++) {
            e += cos(dot(sin(p * s), cos(p.zxy * s))) / s;
            s += s;
        }
        i > 50. ? d /= -d : d;
    }
}

void main(void) {
    twigl(gl_FragColor, gl_FragCoord, resolution, time);
    gl_FragColor.a = 1.;
}