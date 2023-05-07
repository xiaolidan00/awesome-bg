       /*
       * Original shader from: https://www.shadertoy.com/view/sdjyWc
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
      #define MARCHING_ITERATION 100
      #define MAX_DEPTH 100.0
      #define GODRAY_ITERATION 40
      #define VORONOI_TIME 0.5
      #define PI 3.141592
const vec3 LIGHT = normalize(vec3(0.2, 1.0, 0.0));
const float GODRAY_DENTISITY = 0.05;

      // Functions
float Hash1D(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.98823, 85.19235))) * 84252.01313);
}

vec2 Hash2D(vec2 uv) {
    vec2 st = vec2(dot(uv, vec2(134.4, 314.0)), dot(uv, vec2(932.9, 141.301)));
    return -1.0 + 2.0 * fract(sin(st) * 39145.295039);
}

vec2 rot2D(vec2 p, float theta) {
    mat2 rot = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
    return rot * p;
}

      // Voronoi Texture -----------
      // https://thebookofshaders.com/12/
float voronoi(vec2 uv, float offset) {
    vec2 i_ = floor(uv);
    vec2 f_ = fract(uv);
    float d = 1.0;
    float m_dist = 100.0;
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = Hash2D(i_ + neighbor);
            point = 0.5 + 0.5 * sin(6.423 * point + offset);
                  // point = 0.5 + 0.5 *sin(6.323 * point);
            vec2 diff = neighbor + point - f_;

            float dist = length(diff);
            m_dist = min(m_dist, dist);
        }
    }

    return m_dist;
}

      //refer to https://thebookofshaders.com/11/
float value_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = Hash1D(i);
    float b = Hash1D(i + vec2(1.0, 0.0));
    float c = Hash1D(i + vec2(0.0, 1.0));
    float d = Hash1D(i + vec2(1.0, 1.0));

          //smooth Interpolate

          //Cubic Hermine Curve.
          //エルミート補完でsmoothstepの二次元版と思われる。エルミート補完はエルミート多項式も関係するらしい https://qiita.com/Pctg-x8/items/47127a770b23b8934fff
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float perlin_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    vec2 a = Hash2D(i);
    vec2 b = Hash2D(i + vec2(1., 0.));
    vec2 c = Hash2D(i + vec2(0., 1.));
    vec2 d = Hash2D(i + vec2(1., 1.));

    vec2 u = f * f * (3.0 - 2.0 * f);

          //補完をグラディエントを考えて行うらしい
    return mix(mix(dot(a, f), dot(b, f - vec2(1., 0.)), u.x), mix(dot(c, f - vec2(0., 1.)), dot(d, f - vec2(1., 1.)), u.x), u.y) * 0.5 + 0.5;
}

      #define OCTAVES 6
float fbm(vec2 uv) {
    float value = 0.0;
          //振幅
    float amplitude = 0.5;
    float frequency = 0.0;

    for(int i = 0; i < OCTAVES; i++) {
        value += amplitude * value_noise(uv);
        uv *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

vec3 texture2d(vec2 uv) {
    return voronoi(uv, iTime * VORONOI_TIME) * vec3(1.0);
}

      // Ray struct-----------------
struct IntersectInfo {
    float d;
    vec3 normal;
    bool hit;
    vec3 diffuse;
    float iteration;
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

      // BSDF------------
vec3 diffuse(vec3 color, vec3 l, vec3 n) {
    return dot(l, n) * color;
}

      // SDF-------------
float sd_sphere(vec3 p) {
    return length(p) - 1.0;
}
float sd_Box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
float map(vec3 p) {
          // p.xz = mod(p.xz,4.0) - 2.0;
          // return sd_sphere(p);
    float d = p.y - 0.5 * fbm(p.xz);
    vec3 p1 = p;
    p.xz = mod(p.xz, 4.0) - 2.0;
    float index = Hash1D(floor(p1.xz / 4.0));
    if(Hash1D(vec2(index)) > 0.8) {
        p.xz = rot2D(p.xz, index * PI);
        p.xy = rot2D(p.xy, index * PI);
        d = min(d, sd_Box(p, vec3(1.0, 1.0, 1.0)));
    }
    return d - 0.001;
}

vec3 getNormal(vec3 pos) {
    float ep = 0.0001;
    return normalize(vec3(map(pos) - map(pos - vec3(ep, 0.0, 0.0)), map(pos) - map(pos - vec3(0.0, ep, 0.0)), map(pos) - map(pos - vec3(0.0, 0.0, ep))));
}

IntersectInfo ray_Marching(Ray ray) {
    IntersectInfo info;
    info.d = MAX_DEPTH;
    info.hit = false;
    float d;
    float totald = 0.;
    for(int i = 0; i < MARCHING_ITERATION; i++) {
        d = map(ray.origin + totald * ray.direction);
        if(d < 0.001) {
            info.d = totald;
            info.normal = getNormal(ray.origin + totald * ray.direction);
            info.hit = true;
            info.diffuse = vec3(1.0);
            info.iteration = float(i);
            return info;
        }
        totald += d;
    }
    info.iteration = float(MARCHING_ITERATION);
    return info;
}

vec3 scene_Color(vec3 rayPos, vec3 rayDir, inout float dist) {
    Ray ray;
    ray.origin = rayPos;
    ray.direction = rayDir;
    IntersectInfo info = ray_Marching(ray);
    if(info.hit) {
        dist = info.d;
        vec3 n = info.normal;
        vec3 position = rayPos + dist * rayDir;
        vec3 voro = texture2d(position.xz * 0.5);
        vec3 diff = diffuse(info.diffuse, LIGHT, n);
        float fog1 = min(1.0, (1.0 / float(MARCHING_ITERATION))) * info.iteration * 3.0;
        return vec3(0.3) * diff + pow(voro, vec3(5.0)) * vec3(0.8, 0.8, 1.0) + vec3(0.15, 0.15, 0.2) * fog1 * fog1 * 0.6;
    }
    dist = info.d;
    return vec3(0.0);
}

      // God Ray ----------------
      // refer to https://www.shadertoy.com/view/tt2fR3
      // refer to https://qiita.com/edo_m18/items/14f62a89c50a64b62891
      #define GODRAY_LIMIT 10.0
IntersectInfo causticsHit(Ray ray) {
    IntersectInfo info;
    ray.direction *= -1.0;
    vec3 n = vec3(0.0, 1.0, 0.0);
    float t = -dot(ray.origin, n) / dot(ray.direction, n);
    vec3 pos = ray.origin + t * ray.direction;
    vec3 voro = texture2d(pos.xz);
    info.hit = voro.x * voro.x < 0.6;
    return info;
}

vec3 godRay(vec3 rayPos, vec3 rayDir, vec2 uv, float dist, vec3 sceneColor) {
    float fogLitPercent = 0.0;
    if(dist > GODRAY_LIMIT)
        dist = GODRAY_LIMIT;
          //From Shane's comment. I appeciate Shane.
          //初期位置にノイズを加えることでゴッドレイのアーティファクトがノイズに従ってぼかしのような効果が出る（多分）
          //rayPos += Hash1D(uv) * rayDir;
    rayPos += rayDir * Hash1D(vec2(dot(rayPos, vec3(1.0)), dot(rayDir, vec3(1.0))));

          // using BlueNoise https://blog.demofox.org/2020/05/10/ray-marching-fog-with-blue-noise/
          // refer to https://www.shadertoy.com/view/WsfBDf
          //rayPos += fract(texture(iChannel0,uv).r + float(iFrame)) * rayDir;
    for(int i = 0; i < GODRAY_ITERATION; i++) {
        vec3 testPos = rayPos + rayDir * dist * (float(i) / float(GODRAY_ITERATION));
        Ray shadowRay;
        shadowRay.origin = testPos;
        shadowRay.direction = LIGHT;
        IntersectInfo info = causticsHit(shadowRay);
        fogLitPercent = mix(fogLitPercent, (!info.hit) ? 1.0 : 0.0, 1.0 / float(i + 1));
    }
          // if(dist == 10.0) dist = MAX_DEPTH;
    vec3 fogColor = mix(vec3(0.2, 0.2, 0.4), vec3(0.8, 0.8, 1.4) * 2.0, fogLitPercent);
    float absorb = exp(-dist * GODRAY_DENTISITY);
    return mix(fogColor, sceneColor, absorb);
}

      // Fog----------
      #define FOG_DENTISITY 0.05
const vec3 FOG_COLOR = vec3(0.1, 0.1, 0.3);
vec3 fog(vec3 color, float dist) {
    return mix(FOG_COLOR, color, exp(-dist * FOG_DENTISITY));
}
      // Camera Direction -----------------
vec3 camera_Direction(vec3 camDir, vec2 uv, float f) {
    vec3 camSide = cross(camDir, vec3(0, 1, 0));
    vec3 camUp = cross(camSide, camDir);
    vec3 imageDir = normalize(camUp * uv.y + camSide * uv.x + camDir * f);
    return imageDir;
}

vec3 RGBconvert(vec3 col) {
    return pow(col, vec3(1.2)) - vec3(0.2, 0.0, 0.0);
}
      // Main Function ---------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy * 2.0 - iResolution.xy) / iResolution.y;
    vec3 color = vec3(0.0);

    vec3 camPos = vec3(0, 2.0, 3.0 + iTime);
          // vec3 camPos = vec3(0,2.0,3.0);
    vec3 camDir = vec3(sin(iTime * 0.1), 0, cos(iTime * 0.1));

    vec3 rayPos = camPos;
    vec3 rayDir = camera_Direction(camDir, uv, 2.0);
    float dist = 0.0;
    color = scene_Color(rayPos, rayDir, dist);
    color = fog(color, dist);
    color = godRay(rayPos, rayDir, uv, dist, color);
    color = RGBconvert(color);
    fragColor = vec4(color, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}