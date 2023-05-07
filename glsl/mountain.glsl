      /*
       * Original shader from: https://www.shadertoy.com/view/Nsc3DM
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
const vec4 iMouse = vec4(0.);

      // --------[ Original ShaderToy begins here ]---------- //
      #define R iResolution.xy
      #define KEY(v,m) texelFetch(iChannel1, ivec2(v, m), 0).x
      #define ss(a, b, t) smoothstep(a, b, t)
      #define ch(chan, p) texelFetch(chan,  ivec2(p), 0)
      #define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

vec2 hash22(vec2 x) {
    const vec2 k = vec2(0.3183099, 0.3678794);
    x = x * k + k.yx;
    return -1.0 + 2.0 * fract(16.0 * k * fract(x.x * x.y * (x.x + x.y)));
}

float hsh(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float perlin(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hsh(i);
    float b = hsh(i + vec2(1., .0));
    float c = hsh(i + vec2(0., 1));
    float d = hsh(i + vec2(1., 1.));

    vec2 u = smoothstep(0., 1., f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float octnse(vec2 p, int oct, float t) {
    float a = 1.;
    float n = 0.;

    for(int i = 0; i < 5; i++) {
        if(i >= oct)
            break;
        p.x += t;
        n += perlin(p) * a;
        p *= 2.;
        a *= .5;
    }

    return n;
}

      // https://iquilezles.org/articles/distfunctions
float smoothmin(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float line(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float gh(vec2 rp) {
    float h = 0.;

    float t = rp.x + rp.y * 1.2;
    h += cos(rp.y) + .5 * cos(t * 4.) + .3 * sin(rp.y * 3.);
    h += cos(rp.x) + .4 * sin(rp.x * 2.) + .3 * cos(t * 3.);
    h *= .3;

    return h;
}

      #define rad .016
      #define it 4.
      #define b vec3(1., 0., 1.)

float trees_kinda(vec3 p) {
    float scl = 0.33, d = 999., ts = 1.;

    for(float i = 0.; i < it; i++) {
        p.xz = -abs(p.xz);
        float a = 2.9;

        a -= cos(i) * .15;
        p.y -= scl * 2.;

        p.y += scl;
        p.xy *= rot(a);
        p.yz *= rot(a);
        p.y -= scl;

        scl *= .8;
    }

    d = smoothmin(d, length(p - vec3(0., ts, 0.)) - 0.23, .7);
    return d;
}

float map(vec3 rp) {
    rp.z += iTime;

    float h = gh(rp.xz);

    h -= .1 * octnse(rp.xz * 3.8, 3, 0.);
    h -= cos(rp.z * 2.) * .13;

    float d = rp.y + h;

    rp.xz *= rot(3.14 / 4.);
    d = smoothmin(trees_kinda(mod(rp - vec3(1., -3.4 + h, 0.), b) - b * .5), d, .9);

    return d;
}

vec3 normal(in vec3 pos) {
    vec2 e = vec2(0.002, -0.002);
    return normalize(e.xyy * map(pos + e.xyy) +
        e.yyx * map(pos + e.yyx) +
        e.yxy * map(pos + e.yxy) +
        e.xxx * map(pos + e.xxx));
}

void mainImage(out vec4 f, in vec2 u) {
    vec2 uv = vec2(u.xy - 0.5 * R.xy) / R.y;
    vec2 m = (iMouse.xy - .5 * R) / R.y;

    vec3 rd = normalize(vec3(uv, 2.4));
    vec3 ro = vec3(0., 2.15 + .1 * cos(iTime * .4), 0.);

    rd.yz *= rot(.1);
    rd.xz *= rot(.1);

    float d = 0.0, t = 0.0, ns = 0.;

    for(int i = 0; i < 61; i++) {
        d = map(ro + rd * t);
        if(d < 0.0025 || t > 30.)
            break;
        t += d * .7;
        ns++;
    }

    vec3 p = ro + rd * t;
    vec3 n = normal(p);

    p.z += iTime;

    vec3 ld = normalize(vec3(-0.8, 0.5, -2.));
    float dif = max(dot(n, ld), .1);
    float ao = ss(7., 2., ns * .3);

    float rnd = perlin(p.xz * 2.5);
    vec3 grass = mix(vec3(0), .23 * vec3(.1, .2, .1), rnd);

    float cloud = (1. - .17 * octnse(rd.xy * 10., 4, -iTime * .12));
    cloud = mix(cloud, 1., ss(19., 11., t));
    vec3 sky = cloud * vec3(.6, .7, .95);

    vec3 col = grass * dif * ao;

    float fd = 22.;
    float fog = ss(fd, fd - 16.4, t);

    col = mix(sky, col, fog);
    col = pow(col * 1.1, vec3(1.4));

    f = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}