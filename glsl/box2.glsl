        /*
       * Original shader from: https://www.shadertoy.com/view/7tScRt
       */

      #ifdef GL_ES
precision highp float;
      #endif

      // glslsandbox uniforms
uniform float time;
uniform vec2 resolution;

      // shadertoy emulation
      #define iTime time
      #define iResolution resolution

      // --------[ Original ShaderToy begins here ]---------- //
vec3 gl1 = vec3(0.);
vec3 gl2 = vec3(0.);
vec3 gl3 = vec3(0.);
vec3 gl4 = vec3(0.);

mat2 r2d(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

float vma(vec3 v) {
    return max(v.x, max(v.y, v.z));
}

      // from hg_sdf
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vma(min(d, vec3(0)));
}

vec2 de(vec3 p) {

    float d = 0.;

    p.xz *= r2d(iTime * .5);
    p.zy *= r2d(iTime * .5);

    vec3 q = p;
    vec3 z = p;

    vec2 a = vec2(9999.);
    vec2 b = vec2(9999.);

    float h = .5;
    vec3 k = vec3(.2);

    a.x = max(fBox(p, vec3(h + .18, h + .18, h + .18)), -length(p) + .8);
    a.x = max(a.x, -fBox(abs(p) - vec3(h, h, h), k));

    gl1 += (0.0004 / (0.03 + a.x * a.x)) * vec3(0, 1, 1);
    a.y = .5;

    b.x = fBox(abs(p) - vec3(h, h, h), k);
    b.y = .3;
    gl3 += (0.0004 / (0.03 + b.x * b.x)) * vec3(0, 1, 0);
    a = (a.x < b.x) ? a : b;

    p = q;
    p.xz *= r2d(iTime * 2.);
    b.x = length(abs(p) - vec3(.5, 0., 0.)) - .2;
    gl4 += (0.0004 / (0.03 + b.x * b.x)) * vec3(0, 0, 1);
    b.y = .3;
    a = (a.x < b.x) ? a : b;

    p = q;
    p.xy *= r2d(iTime * 2.);
    b.x = length(abs(p) - vec3(0., .5, 0.)) - .2;
    gl4 += (0.0004 / (0.03 + b.x * b.x)) * vec3(0, 0, 1);
    b.y = .5;
    a = (a.x < b.x) ? a : b;

    return a;
}

const vec2 e = vec2(.000035, -.000035);
vec3 norm(vec3 po) {
    return normalize(e.yyx * de(po + e.yyx).x + e.yxy * de(po + e.yxy).x +
        e.xyy * de(po + e.xyy).x + e.xxx * de(po + e.xxx).x);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    float time = iTime * 2.;

    vec3 ro = vec3(0., 0., 7.);
    vec3 ta = vec3(0.);

    vec3 vd = normalize(ta - ro);
    vec3 ri = normalize(cross(vd, vec3(.0, 1., 0.)));
    vec3 dw = normalize(cross(ri, vd));
    vec3 rd = normalize(ri * uv.x + dw * uv.y + 3. * vd);

    float t = 0.;
    vec2 h;
    vec3 po = vec3(0.);

    for(int i = 0; i < 64; i++) {
        po = ro + rd * t;
        h = de(po);
        if(h.x < .001) {
            if(h.y == .5) {
                vec3 n = norm(po);
                rd = reflect(rd, n);
                ro = po + n * .01;
                t = .0;
            } else if(h.y == .3)
                h.x = abs(h.x) + .001;
        }
        t += h.x;
    }

    vec3 c = vec3(.1);

    c += gl1 * .7;
    c += gl2 * .9;
    c += gl3 * .5;
    c += gl4 * .9;

    fragColor = vec4(c, 1.);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}