      // Original shader from: https://twigl.app/?ol=true&ss=-NPivuXkgj-je0DIXAPx

      #ifdef GL_ES
precision highp float;
      #endif

uniform float time;
uniform vec2 resolution;

mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void twigl(out vec4 o, vec4 FC, vec2 r, float t) {
    o = vec4(0);
    float e, a, w, x, g = 0.;
    for(float i = 1.; i <= 1e2; i++) {
        vec3 p = vec3((FC.xy - .5 * r) / r.y * g, g - 3.);
        p.zy *= rotate2D(.6);
        i < 1e2 ? p : p += 1e-4;
        e = p.y;
        a = .8;
        for(int j = 0; j < 26; j++) {
            p.xz *= rotate2D(5.), x = (++p.x + p.z) / a + t + t, w = exp(sin(x) - 2.5) * a, o.gb += w / 4e2, p.xz -= w * cos(x), e -= w;
            a *= .8;
        }
        g += e;
    }
    o += min(e * e * 4e6, 1. / g) + g * g / 2e2;
}

void main(void) {
    twigl(gl_FragColor, gl_FragCoord, resolution, time);
    gl_FragColor.a = 1.;
}