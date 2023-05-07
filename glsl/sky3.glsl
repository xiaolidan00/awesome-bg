     /*
       * Original shader from: https://www.shadertoy.com/view/DsdXRX
       */

      #ifdef GL_ES
precision highp float;
      #endif

      // glslsandbox uniforms
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

      // shadertoy emulation
      #define iTime time
      #define iResolution resolution
vec4 iMouse = vec4(0.);

      // --------[ Original ShaderToy begins here ]---------- //

mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

const vec3 l = vec3(1.);
const vec3 sundir = normalize(vec3(.3, .1, 1.));
const vec3 suncol = vec3(1., .7, .4);
const float low = 5.;
const float high = 8.;
const float dens = 5.;

vec2 sn(vec2 x) {
    x = fract(x * .15);
    return 32. * x * (x - .5) * (x - 1.);
}
vec3 sn(vec3 x) {
    x = fract(x * .15);
    return 32. * x * (x - .5) * (x - 1.);
}

float cloud(in vec3 p) {
    float s = .5, e = max(low - p.y, 0.) + max(p.y - high, 0.) + dens, h = smoothstep(0., 2., 2. * (p.y - low));
    p.xz *= .7;
    for(int i = 0; i < 7; i++) p.xz *= rot(1.), e -= h * abs(dot(sn(p * s + sn(1.7 * p.zxy * s)), l * .5)) / s, s *= 1.7;
    return .7 * e;
}

float cloud1(in vec3 p) {
    float s = .5, e = max(low - p.y, 0.) + max(p.y - high, 0.) + dens, h = smoothstep(0., 2., 2. * (p.y - low));
    p.xz *= .7;
    for(int i = 0; i < 4; i++) p.xz *= rot(1.), e -= h * abs(dot(sn(p * s + sn(1.7 * p.zxy * s)), l * .5)) / s, s *= 1.7;
    return .7 * e;
}

float sea(in vec3 p) {
    float s = 1., f;
    f = p.y;
    for(int i = 0; i < 50; ++i) {
        if(s >= 1e2)
            break;
        p.xz *= rot(1.), f += dot(sn(p.xz * s * .4 + 2. * sn(.7 * p.zx * s * .4)) / s, l.xz);
        s *= 1.7;
    }
    return f * .7;
}

vec3 sky(in vec3 ro, in vec3 rd, in vec2 res) {
          // background sky : modified from IQ clouds
    float sun = max(dot(sundir, rd), 0.0);
    vec3 col = vec3(0.6, 0.6, 0.78) - abs(rd.y) * 0.5 * vec3(1.0, 0.4, .05);

          // clouds
    float k = res.x, c = res.y;
    col += suncol * pow(sun + .001, 500.0) * (1. - 4. * c);
    if(c > .0)
        col *= 1. - .7 * c, col += 3.5 * (.5 + k) * c * suncol, col += 2. * vec3(0.2, 0.08, 0.04) * pow(sun, 3.0) * k;
          // sunrays
    float sh = 0., t, d;
    vec3 q = ro + 10. * rd;
    for(int i = 0; i < 20; ++i) {
        t = 1.;
        for(int j = 0; j < 5; ++j) d = cloud1(q + sundir * t), t += 1.8 * d;
        d = cloud(q + sundir * t);
        sh += 1. / (1. + exp(2. * d));
        q += .7 * rd;
    }
    col += 1.5 / (1. + exp(1. * sh)) * suncol;

    return col;
}

vec3 raycast(in vec3 ro, vec3 rd) {
    float t = 4., e, e1, f, de = 0., df, d, c = 1., dt = .1, r = 1., t0;
    vec3 col = vec3(0.), p, skycol, q;
    for(int i = 0; i < 64; i++) {
        p = ro + t * rd;
        if(p.y < 0.)
            rd.y = -rd.y + .5 * (sea(p + .05 * rd) - sea(p)), ro = p, t0 = t, t = .1, r = .7, q = p;
        e = cloud(p), d = min(p.y + .1, max(e, .06));
        t += d;
        if(e < .001)
            e1 = cloud(p + dt * sundir), de += max(e1 - e, 0.) / dt / (1. + exp(-16. * e1));
        c *= 1. / (1. + exp(-16. * e));
    }
    skycol = sky(ro, rd, vec2(.1 * de, (1. - c) * .25));
    if(r > .9)
        return skycol;
    df = max(sea(q + .005 * sundir) - sea(q), .0) * 1.5 + .7;
    col = skycol * df;
    float maxd = 40.;
    col = mix(r * col, skycol, smoothstep(.1, .99, t0 / maxd));
    return col;
}

void mainImage(out vec4 fragColor, in vec2 u) {
    float t = iTime;
    vec2 R = iResolution.xy, q = (u + u - R) / R.y;

    vec2 m = iMouse.xy / iResolution.xy;

          // camera

    vec3 ro = vec3(0.), rd = normalize(vec3(q, 3.));
    rd.yz *= rot(-.05);
    rd.xz *= rot(2.5 * m.x);
    ro.x -= t * .4;
    ro.y += 2.;

      	// raymarch

    vec3 col = raycast(ro, rd);

      	// shade

    col = log(1. + col);
    col = clamp(col, 0., 1.);
    fragColor = vec4(col, 1.0);

}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    iMouse = vec4(mouse * resolution, 0., 0.);
    mainImage(gl_FragColor, gl_FragCoord.xy);
}