   // Original shader from: https://twitter.com/zozuar/status/1473408479318753285

      #ifdef GL_ES
precision highp float;
      #endif

uniform float time;
uniform vec2 resolution;

mat3 rotate3D(float angle, vec3 axis) {
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(a.x * a.x * r + c, a.y * a.x * r + a.z * s, a.z * a.x * r - a.y * s, a.x * a.y * r - a.z * s, a.y * a.y * r + c, a.z * a.y * r + a.x * s, a.x * a.z * r + a.y * s, a.y * a.z * r - a.x * s, a.z * a.z * r + c);
}

void twigl(out vec4 o, vec4 FC, vec2 r, float t) {
    o = vec4(0);
    float e = 0., s, g = 0.;
    o++;
    for(float i = 0.; i < 1e2; i++) {
        vec3 q, p = (FC.rgb / r.y - .7) * g;
        e = p.y * .5;
        s = .1;
        for(int j = 0; j < 7; j++) {
            q = sin(p * rotate3D(s, p - p + s) * s + t * s) / s, e -= abs(q.x - q.y + q.z) - 4.;
            s += s;
        }
        o += o.w * min(0., e) / 8e2;
        g += max(e * .2, .1);
    }
    o -= log(g) / 35.;
}

void main(void) {
    twigl(gl_FragColor, gl_FragCoord, resolution, time);
    gl_FragColor.a = 1.;
}