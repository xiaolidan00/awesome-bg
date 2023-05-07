        /*
       * Original shader from: https://www.shadertoy.com/view/stlBDl
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
      /*
          Heavy inspiration from Flopine, Kamoshika and 0b5vr. Greets & thanks to them !
      */
float fsnoise(vec2 c) {
    return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}
vec3 rot(vec3 p, vec3 ax, float t) {
    return mix(dot(ax, p) * ax, p, cos(t)) + cross(ax, p) * sin(t);
}
float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(vec3(0.), q)) + min(0., max(q.x, max(q.y, q.z)));
}
float box2(vec2 p, vec2 b) {
    vec2 q = abs(p) - b;
    return length(max(vec2(0.), q)) + min(0., max(q.x, q.y));
}
vec2 sdf(vec3 p) {
    p = rot(p, normalize(vec3(-sqrt(4.), sqrt(2.), 0.)), -.785 / 2.);
    p.z += iTime;
    float gy = dot(asin(sin(p * 3.)), asin(cos(p * 7.))) * .1;
    vec3 hp = p, tp = p;

    vec2 h;
    vec2 I = ceil(hp.xz);
    hp.xz -= I - .5;
    hp.y = abs(hp.y);
    hp.z *= fsnoise(I) < .5 ? -1. : 1.;
    hp.z *= sign(p.y);
    hp.xz += hp.z > -hp.x ? -.5 : .5;

    vec2 q = vec2(length(hp.xz) - .5, hp.y);
    h.x = abs(box2(q, vec2(.05)));
    h.y = 1.;

    vec2 t;

    tp.y += clamp(asin(sin(tp.z * 3.1415 - .95)), -.75, .75) * .25;
    tp.x = mod(tp.x, 2.) - 1.;
    t = vec2(.9 * box2(tp.xy + gy * .1, vec2(.05 - abs(gy) * .2)), 2.);

    h = t.x < h.x ? t : h;
    return h;
}
      #define q(s) s*sdf(p+s).x
vec3 norm(vec3 p, float ee) {
    vec2 e = vec2(-ee, ee);
    return normalize(q(e.xyy) + q(e.yxy) + q(e.yyx) + q(e.xxx));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;

    vec3 ro = vec3(uv * 5., -10.);
    vec3 rp = ro;
    vec3 light = vec3(1., 2., -3);
    vec3 rd = normalize(vec3(0, 0, 1.));
    vec3 col = vec3(0.1);
    float dd = 0.;
    vec3 acc = vec3(0.);
    for(float i = 0.; i < 64.; i++) {
        vec2 d = sdf(rp);
        if(d.y == 2. && d.x < .5) {
            float act = step(.5, sin(rp.z - iTime));
            if(act == 0.) {
                rp += rd * .1;
                continue;
            }
            acc += vec3(cos(rp.z + rp.x) * .5 + .5, .1, sin(rp.z) * .5 + .5) * act * exp(fract(iTime + floor(rp.z) * .5) * -abs(d.x) * i * i) / 20.;
            d.x = max(act > 0. ? .0005 : d.x, abs(d.x));

        }
        dd += d.x;
        if(dd > 50.)
            break;
        rp += rd * d.x;
        if(d.x < .0001 && d.y == 1.) {
            vec3 n = norm(rp, .001);
            vec3 n2 = norm(rp, .005);
            float dif = max(0., dot(normalize(light), n));
            float qq = length(n - n2);
            if(d.y == 1.) {
                col = dif * vec3(.1) + vec3(.1, .5, 1.1) * dif * smoothstep(.1, 0.35, qq);
            } else {
                col = dif * vec3(1.);

            }
            break;
        }

    }
    fragColor = vec4(col + sqrt(acc), 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}