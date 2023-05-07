      /*
       * Original shader from: https://www.shadertoy.com/view/ftXyDr
       */

      #ifdef GL_ES
precision mediump float;
      #endif

      // glslsandbox uniforms
uniform float time;
uniform vec2 resolution;

      // shadertoy emulation
      #define iTime time
      #define iResolution resolution

      // --------[ Original ShaderToy begins here ]---------- //
      /*---------------------------------------------

      Giza Necropolis, Sandaruwan Silva 2022

      Nine pyramids of the Giza pyramid complex.

      1. Clouds and noise functions etc. based on Inigo Quilez's Rainforest
         https://www.shadertoy.com/view/4ttSWf
      2. Dust storm roughly based on VoidChicken's The Rude Sandstorm
         https://www.shadertoy.com/view/Mly3WG

      ---------------------------------------------*/

      #define PI 3.14159265359
      #define PI_4 0.78539816339

const vec3 sun_direction = normalize(vec3(0.8, 0.3, -0.6));

const mat3 m3 = mat3(0.00, 0.80, 0.60, -0.80, 0.36, -0.48, -0.60, -0.48, 0.64);
const mat3 m3i = mat3(0.00, -0.80, -0.60, 0.80, 0.36, -0.48, 0.60, -0.48, 0.64);
const mat2 m2 = mat2(0.80, 0.60, -0.60, 0.80);
const mat2 m2i = mat2(0.80, -0.60, 0.60, 0.80);

mat3 rotate_x(in float a) {
    float sa = sin(a);
    float ca = cos(a);
    return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, ca, sa), vec3(0.0, -sa, ca));
}

mat3 rotate_y(in float a) {
    float sa = sin(a);
    float ca = cos(a);
    return mat3(vec3(ca, 0.0, sa), vec3(0.0, 1.0, 0.0), vec3(-sa, 0.0, ca));
}

mat3 rotate_z(in float a) {
    float sa = sin(a);
    float ca = cos(a);
    return mat3(vec3(ca, sa, 0.0), vec3(-sa, ca, 0.0), vec3(0.0, 0.0, 1.0));
}

float opSmoothUnion(in float d1, in float d2, in float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

vec3 fog(in vec3 col, float t) {
    vec3 ext = exp2(-t * 0.0007 * vec3(2.0, 2.5, 4.0));
    return col * ext + (1.0 - ext) * vec3(0.75, 0.65, 0.58);
}

float hash1(float n) {
    return fract(n * 17.0 * fract(n * 0.3183099));
}

float hash1(vec2 p) {
    p = 50.0 * fract(p * 0.3183099);
    return fract(p.x * p.y * (p.x + p.y));
}

float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float n = 1.0 * p.x + 317.0 * p.y + 157.0 * p.z;

    float a = hash1(n + 0.0);
    float b = hash1(n + 1.0);
    float c = hash1(n + 317.0);
    float d = hash1(n + 318.0);
    float e = hash1(n + 157.0);
    float f = hash1(n + 158.0);
    float g = hash1(n + 474.0);
    float h = hash1(n + 475.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return -1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y +
        k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z +
        k6 * u.z * u.x + k7 * u.x * u.y * u.z);
}

float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 w = fract(x);
    vec2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

    float a = hash1(p + vec2(0, 0));
    float b = hash1(p + vec2(1, 0));
    float c = hash1(p + vec2(0, 1));
    float d = hash1(p + vec2(1, 1));

    return -1.0 + 2.0 * (a + (b - a) * u.x +
        (c - a) * u.y + (a - b - c + d) * u.x * u.y);
}

float fbm_9(in vec2 x) {
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;

    for(int i = 0; i < 9; i++) {
        float n = noise(x);
        a += b * n;
        b *= s;
        x = f * m2 * x;
    }
    return a;
}

float sdSphere(in vec3 p, in float radius) {
    return length(p) - radius;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdOctahedron(in vec3 p, in float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

float sdOctahedronStepped(in vec3 p, in float s) {
    p = abs(p);
    return (p.x + floor(p.y * 15.0) / 15.0 + p.z - s) * 0.47735027;
}

float sdGiza(in vec3 p, in float s, in float dmg) {
    p = abs(p);
    float v = (p.x + p.y + p.z - s) * 0.57735027;

    p.y -= s + 0.25 - dmg;

    float b = sdBox(p, vec3(0.25));
    v = max(v, -b);
    return v;
}

      // -- cloud generation -----------------------

vec4 sky(in vec3 ro, in vec3 rd) {
    vec3 col = vec3(0.3, 0.4, 1.0) - rd.y * 0.7;
    float t = (1000.0 - ro.y) / rd.y;

    if(t > 0.0) {
        vec2 uv = (ro + t * rd).xz;
        float cl = fbm_9(uv * 0.002 - iTime * 0.2);
        float dl = smoothstep(-0.2, 0.6, cl);
        col = mix(col, vec3(1.0), 0.12 * dl);
    }

    return vec4(col, t);
}

      // -- scene ----------------------------------

      // scene map
vec3 map(in vec3 p) {
    vec3 res = vec3(-1.0);

    vec3 offset = vec3(0.3, 0.0, -8.0);
    vec3 offset2 = vec3(0.6, 0.0, -8.0);

    float d = 0.0;

          // noise values
    float nv1 = noise(p * 0.25 + 2.1);
    float nv2 = noise(p * 230.0 + 2.1);
    float nv3 = noise(p * 12.5 + 2.1);
    float nv4 = noise(vec3(p.x, p.y, 0.0) * 1.5 + 2.1);
    float nv5 = noise(p * 49.5 + 2.1);
    float nv6 = noise(vec3(p.x, p.y, 0.0) * 0.5 + 2.1);

          // height map
    float heightMap = nv1 * 0.5 + nv2 * 0.002;
    float terrain = p.y + heightMap;

          // common values for pyramids
    vec3 mainOffset = p * rotate_y(PI_4) + offset;
    float mainNoise1 = nv3 * 0.02;
    float mainNoise2 = nv4 * 0.07;
    float mainNoiseTop = nv5 * 0.015;

    vec3 smallOffset = p * rotate_y(PI_4) + offset2;

    float ySin = smoothstep(0.93, 1.0, sin(p.y * 400.0)) * 0.01;
    float xSin = smoothstep(0.94, 1.0, sin(p.x * 260.0)) * 0.005;
    float zSin = smoothstep(0.94, 1.0, sin(p.z * 260.0)) * 0.005;
    float sinComb = ySin + xSin + zSin;

    float ySinM1 = smoothstep(0.2, 1.0, sin(p.y * 200.)) * 0.007;
    float xSinM1 = smoothstep(0.2, 1.0, sin(p.x * 200.)) * 0.005;
    float zSinM1 = smoothstep(0.2, 1.0, sin(p.z * 200.)) * 0.005;
    float sinMComb1 = ySinM1 + xSinM1 + zSinM1;

    float ySinM2 = smoothstep(0.2, 1.0, sin(p.y * 100.)) * 0.005;
    float xSinM2 = smoothstep(0.2, 1.0, sin(p.x * 100.)) * 0.005;
    float zSinM2 = smoothstep(0.2, 1.0, sin(p.z * 100.)) * 0.005;
    float sinMComb2 = ySinM2 * 4.0 + xSinM2 + zSinM2;

          // pyramid of Menkaure, one in the front
    float p1 = sdGiza(mainOffset + vec3(-3.0, 2.8, 1.0), 4.9 - sinMComb1 - mainNoise1 * 0.2 - nv5 * 0.01 - mainNoise2 * 0.2, 0.08);

          // pyramid of Khafre, one in the middle
    float p2 = sdOctahedron(mainOffset + vec3(0.0, 2.0, 15.0), 7.5 - sinMComb2 - mainNoise1 - mainNoise2);
          // pyramid top
    float ptop = sdGiza(mainOffset + vec3(0.01, -4.0, 14.98), 1.58 - mainNoiseTop, 0.05);
    ptop = max(ptop, -sdSphere(mainOffset + vec3(0.04, -1.8, 13.98), 2.8 + nv1 * 0.2 + nv3 * 0.1));

          // pyramid of Khufu, distant one
    float p3 = sdGiza(mainOffset + vec3(0.0, 2.0, 30.0), 8.0 - sinMComb2 - mainNoise1 - mainNoise2, 0.2);

          // queens' pyramids
    float p4 = sdOctahedronStepped(smallOffset + vec3(-5.6, 0.47, -4.4), 0.58 - sinComb - nv5 * 0.02 - nv6 * 0.07);
    float p5 = sdOctahedronStepped(smallOffset + vec3(-6.0, 0.37, -4.0), 0.58 - sinComb - nv5 * 0.02 - nv6 * 0.07);
    float p6 = sdOctahedronStepped(smallOffset + vec3(-6.4, 0.34, -3.6), 0.58 - sinComb - nv5 * 0.02 - nv6 * 0.07);

          // remove algorithmic artifacts on the top
    p5 = max(p5, -sdBox(smallOffset + vec3(-6.0, -0.3, -4.0), vec3(0.1)));

          // spheres to smoothen the pyramids
    float s4 = sdSphere(p + vec3(5.2, 0.2, -12.3), 0.3);
    float s5 = sdSphere(p + vec3(4.7, 0.1, -12.3), 0.22);
    float s6 = sdSphere(p + vec3(4.2, 0.1, -12.3), 0.22);

          // other pyramids in the complex
          // represent them with just spheres since they're far away
    float s7 = sdSphere(p + vec3(-22.2, -1.1, 11.0), 0.2 - ySin - xSin - zSin - nv5 * 0.01 - nv6 * 0.07);
    float s8 = sdSphere(p + vec3(-22.2, -0.7, 13.0), 0.5 - ySin - xSin - zSin - nv5 * 0.01 - nv6 * 0.07);
    float s9 = sdSphere(p + vec3(-22.2, -0.5, 15.0), 0.5 - ySin - xSin - zSin - nv5 * 0.01 - nv6 * 0.07);

    d = min(terrain, p1);
    d = min(d, p2);
    d = min(d, ptop);
    d = min(d, p3);

    d = opSmoothUnion(d, s7, 2.6);
    d = opSmoothUnion(d, s8, 1.2);
    d = opSmoothUnion(d, s9, 1.2);

          // add queens' pyramids
    d = opSmoothUnion(opSmoothUnion(d, p4, 0.05), s4, 0.2);
    d = opSmoothUnion(opSmoothUnion(d, p5, 0.05), s5, 0.2);
    d = opSmoothUnion(opSmoothUnion(d, p6, 0.05), s6, 0.2);

    res.x = d;
    return res;
}

      // ray marching through terrain and objects
vec3 trace(in vec3 ro, in vec3 rd) {
    float tMax = 1000.0;
    vec3 res = vec3(-1.0);
    vec3 last = vec3(0.0);
    float t = 0.0;

    vec3 dust = vec3(1.0);

    for(int i = 0; i < 150; i++) {
        vec3 pos = ro + t * rd;
        vec3 hit = map(pos);

        if(abs(hit.x) < 0.0001 * t || t > tMax)
            break;

        t += hit.x;
        last = hit;

              // add dust cloud
        vec3 a = vec3(noise(pos + iTime * 0.13) + 0.1);
        dust += a * sqrt(float(i)) * 1.0 *
            pow(smoothstep(0.0, 1.0, clamp(float(i) / 15.0, 0.0, 1.0)), 1.0 / 2.5);
    }

    if(t < tMax) {
        res = vec3(t, last.yz);
    }

    dust.x = clamp(dust.x, -200.0, 200.0);
    res.y = dust.x * 0.001;
    return res;
}

      // calculate normals
vec3 calcNormal(vec3 p, float t) {
    float d = 0.001 * t;
    vec2 e = vec2(1.0, -1.0) * 0.5773 * d;
    return normalize(e.xyy * map(p + e.xyy).x +
        e.yyx * map(p + e.yyx).x +
        e.yxy * map(p + e.yxy).x +
        e.xxx * map(p + e.xxx).x);
}

      // calculate ao
float calcAO(in vec3 pos, in vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;

    for(int i = 0; i < 5; i++) {
        float h = 0.001 + 0.15 * float(i) / 4.0;
        float d = map(pos + h * nor).x;
        occ += (h - d) * sca;
        sca *= 0.95;
    }

    return clamp(1.0 - 1.5 * occ, 0.0, 1.0);
}

      // camera/projection
mat3 camera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.0);
    float time = iTime;

          // set up camera/projection
    float an = -0.35;
    float ra = 17.0;
    float fl = 4.0;
    vec3 ta = vec3(sin(time * 0.13 - 0.1) * 0.1, cos(time * 0.1 - 4.0) * 0.05 + 0.1, 0.0);
    vec3 ro = ta + vec3(ra * sin(an), 0.0, ra * cos(an));
    mat3 ca = camera(ro, ta, 0.0);
    vec3 rd = ca * normalize(vec3(p.x + 0.3, p.y + 0.4, fl));

          // ray marching
    vec3 ray = trace(ro, rd);
    float resT = 1000.;

    if(ray.x >= 0.0) {
        float t = ray.x;
        vec3 pos = ro + t * rd;
        vec3 norm = calcNormal(pos, t);

              // prepare diffusion
        float sun_dif = clamp(dot(norm, sun_direction), 0.0, 1.0);
        vec3 sky_dir = normalize(vec3(0.0, 1.0, 0.0));
        float sky_dif = clamp(dot(norm, sky_dir), 0.0, 1.0);

              // set up cheap shadows
        float sun_sha = trace(pos + norm * 0.0001, sun_direction).x;
        float dif = clamp(sun_dif, 0.0, 1.0);

        col += vec3(0.6, 0.4, 0.2) * dif * 1.29;
        col += vec3(0.6, 0.4, 0.8) * sky_dif * 0.4;
        col *= calcAO(pos, norm);

        if(sun_sha > 0.0) {
            col *= 0.5;
        }

        col += ray.y * vec3(1.0, 0.8, 0.4) * 0.6;

        col = fog(col, t);
        col *= 0.5 + 0.5 * vec3(0.8, 0.3, 0.0);

    } else {
        vec4 sky_color = sky(ro, rd);
        col = sky_color.rgb;

        col = fog(col, sky_color.a * 0.01);
    }

          // gamma
    col = pow(clamp(col * 1.1 - 0.04, 0.0, 1.0), vec3(0.4545));

          // contrast
    col = col * col * (3.0 - 2.0 * col);

          // add sun glare
    float sun = clamp(dot(sun_direction, rd), 0.0, 1.0);
    col += 0.75 * vec3(0.8, 0.4, 0.2) * sun * sun * sun;

    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}