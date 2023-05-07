       /*
       * Original shader from: https://www.shadertoy.com/view/ftXcW2
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
      #define MAX_STEPS 100
      #define MAX_DIST 100.
      #define SURF_DIST .001

      #define S smoothstep
      #define T iTime
      #define TAU 6.281

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p) - s;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

float range(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    float oldRange = oldMax - oldMin;
    float newRange = newMax - newMin;
    return (((oldValue - oldMin) * newRange) / oldRange) + newMin;
}

vec3 range(vec3 oldValue, vec3 oldMin, vec3 oldMax, vec3 newMin, vec3 newMax) {
    vec3 v;
    v.x = range(oldValue.x, oldMin.x, oldMax.x, newMin.x, newMax.x);
    v.y = range(oldValue.y, oldMin.y, oldMax.y, newMin.y, newMax.y);
    v.z = range(oldValue.z, oldMin.z, oldMax.z, newMin.z, newMax.z);
    return v;
}

float cnoise(vec3 v) {
    float t = v.z * 0.3;
    v.y *= 0.8;
    float noise = 0.0;
    float s = 0.5;
    noise += range(sin(v.x * 0.9 / s + t * 10.0) + sin(v.x * 2.4 / s + t * 15.0) + sin(v.x * -3.5 / s + t * 4.0) + sin(v.x * -2.5 / s + t * 7.1), -1.0, 1.0, -0.3, 0.3);
    noise += range(sin(v.y * -0.3 / s + t * 18.0) + sin(v.y * 1.6 / s + t * 18.0) + sin(v.y * 2.6 / s + t * 8.0) + sin(v.y * -2.6 / s + t * 4.5), -1.0, 1.0, -0.3, 0.3);
    return noise;
}

float BallGyroid(vec3 p) {
    p.yz *= Rot(T * .2);
    p *= 10.;
    return abs(cnoise(p) * dot(sin(p), cos(p.yzx)) / 10.) - .02;
}

float smin(float a, float b, float k) {
    float h = clamp(.5 + .5 * (b - a) / k, 0., 1.);
    return mix(b, a, h) - k * h * (1. - h);
}

float GetDist(vec3 p) {
    float ball = length(p) - 1.;
    ball = abs(ball) - 0.02;
    float g = BallGyroid(p);

    ball = smin(ball, g, -.03);

    float ground = p.y + 1.;
    p *= 5.;
    p.z += T;
    p.y += sin(p.z) * .5;
    float y = abs(dot(sin(p), cos(p.yzx))) * .1;
    ground += y;

    float d = min(ball, ground * .9);

    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.;

    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO > MAX_DIST || abs(dS) < SURF_DIST)
            break;
    }

    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);

    vec3 n = d - vec3(GetDist(p - e.xyy), GetDist(p - e.yxy), GetDist(p - e.yyx));

    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p), r = normalize(cross(vec3(0, 1, 0), f)), u = cross(f, r), c = f * z, i = c + uv.x * r + uv.y * u, d = normalize(i);
    return d;
}

float Hash21(vec2 p) {
    p = fract(p * vec2(123.34, 254.98));
    p += dot(p, p + 45.6);
    return fract(p.x * p.y);
}

float Glitter(vec2 p, float a) {
    p *= 10.;
    vec2 id = floor(p);

    p = fract(p) - .5;
    float n = Hash21(id); //noise
    float d = length(p);
    float m = S(.5 * n, .0, d);
    m *= pow(sin(a + fract(n * 10.) * TAU) * .5 + .5, 100.);
    return m;
}

vec3 RayPlane(vec3 ro, vec3 rd, vec3 p, vec3 n) {
    float t = dot(p - ro, n) / dot(rd, n);
    t = max(0., t);
    return ro + rd * t;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy / iResolution.xy;
    float cds = dot(uv, uv); //center distance squared

    vec3 ro = vec3(0, 3, -3) * .6;
    ro.yz *= Rot(-m.y * 3.14 + 1.);
    ro.y = max(-.9, ro.y);
    ro.xz *= Rot(-m.x * 6.2831 + T * .3);

    vec3 rd = GetRayDir(uv, ro, vec3(0, 0., 0), 1.);
    vec3 col = vec3(0);

    float d = RayMarch(ro, rd);

    if(d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        vec3 lightDir = -normalize(p);
        float dif = dot(n, lightDir) * .5 + .5;
        float cd = length(p);

        col = vec3(dif);

        if(cd > 1.035) {
                  //col *= vec3(1,0,0);
            float s = BallGyroid(-lightDir);
            float w = cd * .02;
            float shadow = S(-w, w, s);
            col *= shadow * .9 + .1;

            p.z -= T * 0.01;
            col += Glitter(p.xz * 6., dot(ro, vec3(2)) - T) * 2. * shadow;
            col /= cd * cd;
        } else {
            float sss = S(.1, 0., cds);
            sss *= sss;

                  //float s = BallGyroid(p+sin(p*10.+T*.001)*.02);
                  //sss *= S(-.01, 0., s);
            col += sss * vec3(1., .1, .2);
        }
    }

          // center light
    float light = .005 / cds;
    vec3 lightCol = vec3(1., .8, .7);
    col += light * S(.0, .5, d - 2.) * lightCol;
          // center light glare
    float s = BallGyroid(normalize(ro));
    col += light * .5 * S(.0, .08, s) * lightCol;

          //volumetrics
    vec3 pp = RayPlane(ro, rd, vec3(0), normalize(ro));
    float sb = BallGyroid(normalize(pp));
    sb *= S(0., .4, cds);
    col += max(0., sb * 2.);

    col = pow(col, vec3(.4545));	// gamma correction
    col *= 1. - cds * .5;

    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}