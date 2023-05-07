     /*
       * Original shader from: https://www.shadertoy.com/view/7lBfR1
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
      #define MAX_STEPS 400.
      #define HIT_DISTANCE 0.0001

      #define PI 3.14159265359

      // Structs
struct camera {
    vec3 pos;
    vec3 fwd;
    vec3 right;
    vec3 up;
};

struct sdMap {
    vec3 col;
    float d;
};

struct rmRes {
    bool hasHit;
    vec3 col;
    vec3 pos;
};

      // Util functions
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

      // SDF's
float sphereSDF(vec3 p, vec3 c, float r) {
    return length(p - c) - r;
}

float boxSDF(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

sdMap map(vec3 p) {
    float modSize = 3.;

    vec3 q = vec3(mod(p.x + modSize / 2., modSize) - modSize / 2., p.y, mod(p.z + modSize / 2., modSize) - modSize / 2.);

    sdMap maps[2];
          // Spheres
    maps[0] = sdMap(vec3(1, 0.5, 0), sphereSDF(q, vec3(0, 0.8, 0), .6));

          // Ground
    maps[1] = sdMap(vec3(0.2), smin(boxSDF(q, vec3(0.4, 0.1, 0.4)) - 0.05, // Sphere base
    p.y + .1, // Ground plane
    0.5));

    sdMap m = sdMap(vec3(0), 1e6);

    for(int i = 0; i < 2; i++) {
        bool b = maps[i].d < m.d;

        m.d = b ? maps[i].d : m.d;
        m.col = b ? maps[i].col : m.col;
    }

    return m;
}

      // Raymarching
rmRes raymarch(vec3 o, vec3 d) {
    rmRes res = rmRes(false, vec3(0), vec3(0));

    vec3 cp = o;
    float cd = 0.;

    for(float i = 0.; i < MAX_STEPS; i++) {
        sdMap sd = map(cp);

        if(sd.d <= HIT_DISTANCE) {
            res.hasHit = true;
            res.col = sd.col;
            res.pos = cp;
            break;
        }

        cd += sd.d;
        cp += d * sd.d;
    }

    return res;
}

      // https://iquilezles.org/articles/rmshadows/
float softshadow(in vec3 ro, in vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float ph = 1e20;
    float t = 0.;
    for(int i = 0; i < 400; i++) {
        if(t >= MAX_STEPS)
            break;
        float h = map(ro + rd * t).d;

        if(h < HIT_DISTANCE)
            return 0.0;

        float y = h * h / (2.0 * ph);
        float d = sqrt(h * h - y * y);

        res = min(res, k * d / max(0.0, t - y));
        ph = h;
        t += h;
    }
    return res;
}

vec3 normal(vec3 p) {

    sdMap d0 = map(p);
    const vec2 epsilon = vec2(.0001, 0);
    vec3 d1 = vec3(map(p - epsilon.xyy).d, map(p - epsilon.yxy).d, map(p - epsilon.yyx).d);
    return normalize(d0.d - d1);
}

      // mainImage
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 mouse = (iMouse.xy - .5 * iResolution.xy) / iResolution.y;

    camera cam = camera(vec3(cos(mouse.x * PI * 2.) * 6., 4, sin(mouse.x * PI * 2.) * 6. + iTime), vec3(1, -1, 1), vec3(0), vec3(0));

    cam.fwd = normalize(vec3(0, 1, iTime) - cam.pos);
    cam.right = cross(cam.fwd, vec3(0, 1, 0));
    cam.up = cross(cam.right, cam.fwd);

    vec3 sunPos = vec3(cos(iTime) * 4., 2., sin(iTime) * 4. + iTime);
    vec3 rayDir = normalize(cam.fwd + cam.right * uv.x + cam.up * uv.y);

    rmRes r = raymarch(cam.pos, rayDir);

    vec3 sunCol = vec3(1, 0.6, 0.4);
    vec3 sunDir = normalize(sunPos - r.pos);
    float sunPow = (sin(iTime * 1.5) * .5 + .5) * 3. + 8.;

    float shadowAmt = softshadow(r.pos - rayDir * 0.001, sunDir, 0., 1., 4.);

    vec3 norm = normal(r.pos);

    vec3 col = r.col;

          // Specular highlight
    col += sunCol * smoothstep(0.9, 0.96, dot(reflect(rayDir, norm), normalize(sunPos - r.pos))) * sunPow / 10.;

          // Shadow
    col = mix(col, vec3(0), clamp(1. - shadowAmt, 0., 1.));

          // Diffuse
          // Added at the end for the illusion of global illumination. (This likely won't work for other scenes)
    col += sunCol / (length(r.pos - sunPos) / sunPow * 2.);

          // Light falloff
    col = mix(col, vec3(0), clamp(length(r.pos - sunPos) / sunPow, 0., 1.));

          // Black sky
    col = mix(col, vec3(0), 1. - float(r.hasHit));

    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}