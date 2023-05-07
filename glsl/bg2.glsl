      /*
       * Original shader from: https://www.shadertoy.com/view/7s3cWM
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

      // Emulate a black texture
      #define texture(s, uv) vec4(0.0)

      // --------[ Original ShaderToy begins here ]---------- //
      //Credit to IQ for his raymarching primitives shader
      // This shader is trying to reproduce this image https://www.youtube.com/watch?v=k3WkJq478To

float sdPlane(vec3 p) {
    return p.y;
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float smax(float a, float b, float k) {
    return log(exp(k * a) + exp(k * b)) / k;
}

float smin(float a, float b, float k) {
    return -(log(exp(k * -a) + exp(k * -b)) / k);
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

float sdEllipsoid(in vec3 p, in vec3 r) {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;

}

float sdRoundBox(in vec3 p, in vec3 b, in float r) {
    vec3 q = abs(p) - b;
    return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

float sdTorus(vec3 p, vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float sdHexPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);

    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
    vec2 d = vec2(length(p.xy - vec2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x), p.z - h.y);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdRoundCone(in vec3 p, in float r1, float r2, float h) {
    vec2 q = vec2(length(p.xz), p.y);

    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, vec2(-b, a));

    if(k < 0.0)
        return length(q) - r1;
    if(k > a * h)
        return length(q - vec2(0.0, h)) - r2;

    return dot(q, vec2(a, b)) - r1;
}

float dot2(in vec3 v) {
    return dot(v, v);
}
float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2) {
          // sampling independent computations (only depend on shape)
    vec3 ba = b - a;
    float l2 = dot(ba, ba);
    float rr = r1 - r2;
    float a2 = l2 - rr * rr;
    float il2 = 1.0 / l2;

          // sampling dependant computations
    vec3 pa = p - a;
    float y = dot(pa, ba);
    float z = y - l2;
    float x2 = dot2(pa * l2 - ba * y);
    float y2 = y * y * l2;
    float z2 = z * z * l2;

          // single square root!
    float k = sign(rr) * rr * rr * x2;
    if(sign(z) * a2 * z2 > k)
        return sqrt(x2 + z2) * il2 - r2;
    if(sign(y) * a2 * y2 < k)
        return sqrt(x2 + y2) * il2 - r1;
    return (sqrt(x2 * a2 * il2) + y * rr) * il2 - r1;
}

float sdEquilateralTriangle(in vec2 p) {
    const float k = 1.73205;//sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if(p.x + k * p.y > 0.0)
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x += 2.0 - 2.0 * clamp((p.x + 2.0) / 2.0, 0.0, 1.0);
    return -length(p) * sign(p.y);
}

float sdTriPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    float d1 = q.z - h.y;
    h.x *= 0.866025;
    float d2 = sdEquilateralTriangle(p.xy / h.x) * h.x;
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

      // vertical
float sdCylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

      // arbitrary orientation
float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float baba = dot(ba, ba);
    float paba = dot(pa, ba);

    float x = length(pa * baba - ba * paba) - r * baba;
    float y = abs(paba - baba * 0.5) - baba * 0.5;
    float x2 = x * x;
    float y2 = y * y * baba;
    float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
    return sign(d) * sqrt(abs(d)) / baba;
}

float sdCone(in vec3 p, in vec3 c) {
    vec2 q = vec2(length(p.xz), p.y);
    float d1 = -q.y - c.z;
    float d2 = max(dot(q, c.xy), q.y);
    return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float dot2(in vec2 v) {
    return dot(v, v);
}
float sdCappedCone(in vec3 p, in float h, in float r1, in float r2) {
    vec2 q = vec2(length(p.xz), p.y);

    vec2 k1 = vec2(r2, h);
    vec2 k2 = vec2(r2 - r1, 2.0 * h);
    vec2 ca = vec2(q.x - min(q.x, (q.y < 0.0) ? r1 : r2), abs(q.y) - h);
    vec2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2(k2), 0.0, 1.0);
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(dot2(ca), dot2(cb)));
}

      #if 0
      // bound, not exact
float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}
      #else
      // exacy distance
float sdOctahedron(vec3 p, float s) {
    p = abs(p);

    float m = p.x + p.y + p.z - s;

    vec3 q;
    if(3.0 * p.x < m)
        q = p.xyz;
    else if(3.0 * p.y < m)
        q = p.yzx;
    else if(3.0 * p.z < m)
        q = p.zxy;
    else
        return m * 0.57735027;

    float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
    return length(vec3(q.x, q.y - s + k, q.z - k));
}
      #endif

float length2(vec2 p) {
    return sqrt(p.x * p.x + p.y * p.y);
}

float length6(vec2 p) {
    p = p * p * p;
    p = p * p;
    return pow(p.x + p.y, 1.0 / 6.0);
}

float length8(vec2 p) {
    p = p * p;
    p = p * p;
    p = p * p;
    return pow(p.x + p.y, 1.0 / 8.0);
}

float sdTorus82(vec3 p, vec2 t) {
    vec2 q = vec2(length2(p.xz) - t.x, p.y);
    return length8(q) - t.y;
}

float sdTorus88(vec3 p, vec2 t) {
    vec2 q = vec2(length8(p.xz) - t.x, p.y);
    return length8(q) - t.y;
}

float sdCylinder6(vec3 p, vec2 h) {
    return max(length6(p.xz) - h.x, abs(p.y) - h.y);
}

      //------------------------------------------------------------------

float opS(float d1, float d2) {
    return max(-d2, d1);
}

vec2 opU(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
}

vec3 opRep(vec3 p, vec3 c) {
    return mod(p, c) - 0.5 * c;
}

vec3 opTwist(vec3 p) {
    float c = cos(10.0 * p.y + 10.0);
    float s = sin(10.0 * p.y + 10.0);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

      #define AA 2   // make this 2 or 3 for antialiasing

      #define floor_mat 1.0
      #define sky_mat 2.0
      #define building_mat 3.0
      #define big_building_mat 4.0

      //------------------------------------------------------------------

      #define ZERO 0

      //------------------------------------------------------------------

float stripes(float y) {

    float b = clamp(0.0, 1.0, 1.0 - y * 2.0);
          //b = 1.0 - b;
    float h = y + 0.3;
    float s = smoothstep(0.3, 0.21, abs(sin(-iTime * 1.5 + h * h * 30.0)));
    return s * b;
}

vec2 hash(vec2 p) {
          //p = mod(p, 4.0); // tile
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 18.5453);
}

      // return distance, and cell id
vec2 voronoi(in vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    vec3 m = vec3(8.0);
    for(int j = -1; j <= 1; j++) for(int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash(n + g);
            //vec2  r = g - f + o;
            vec2 r = g - f + (0.5 + 0.5 * sin(6.2831 * o));
            float d = dot(r, r);
            if(d < m.x)
                m = vec3(d, o);
        }

    return vec2(sqrt(m.x), m.y + m.z);
}
float oscillate() {
    return sin(iTime * 1.0);
}

float mapBigBuildings(vec3 p) {
    float scale = 1.0 / 3.0;
    float id = floor(p.x / scale);
    float scale_fact = clamp(abs(id / 50.0), 0.5, 44.5);
    p.x = mod(p.x, scale) - scale / 2.0;

    float h = hash(vec2(id)).x;
    p.y += 0.6;
    p.y /= 13.0 / scale_fact;//
    p.x /= 7.0;
    p.z += 5.0;

    p.z /= 10.0;
    p.y += h / 5.0;
    float b1 = sdBox(p + vec3(0.1, 0.0, 0.0), vec3(0.05, 0.1, 0.02));
    float b2 = sdBox(p + vec3(0.0, 0.0, 0.0), vec3(0.05, 0.2, 0.05));
    float b3 = sdBox(p + vec3(-0.05, 0.0, -0.1), vec3(0.05, 0.1, 0.05));
    return min(b1, min(b2, b3));
}

float mapBuildings(vec3 p) {

    float scale = 1.0 / 3.0;
    float x = p.x;
    float z = p.z;
    p.x += iTime * 0.4;

    float angle = iTime / 10000.0;

          //p.x = cos(angle) * p.x - sin(angle) * p.z;
          //p.z = sin(angle)* x + cos(angle) * z;

    vec3 id = floor(p / scale);
    if(-id.z + 1.0 > 8.0)
        return 10000.0;
    float h = hash(id.xz).x;
    p.xz = mod(p.xz, scale) - scale / 2.0;
    p.x -= 0.05;
    p.y += 0.6;
    if(h < 0.1)
        p.y *= 0.6;
    p.x += h / 10.0;
    p *= 1.2;
    float b1 = sdBox(p + vec3(0.1, 0.0, 0.0), vec3(0.05, 0.1, 0.02));
    float b2 = sdBox(p + vec3(0.0, 0.0, 0.0), vec3(0.05, 0.2, 0.05));
    float b3 = sdBox(p + vec3(-0.05, 0.0, -0.1), vec3(0.05, 0.1, 0.05));
    if(h > 0.3)
        b2 = 10000.0;

    return min(b1, min(b2, b3));
}

vec2 map2(in vec3 pos) {
    vec2 res = vec2(1e10, 0.0);

    float dFloor = pos.y + 0.75;// + cos(pos.x / 35.0);

    res = opU(res, vec2(dFloor, floor_mat));
    float dSky = pos.z + 6.5;
    res = opU(res, vec2(dSky, sky_mat));
    return res;
}

vec2 map(in vec3 pos) {
    vec2 res = vec2(1e10, 0.0);

    float dFloor = pos.y + 0.75;// + cos(pos.x / 35.0);

    float dSky = pos.z + 6.5;
    res = opU(res, vec2(dSky, sky_mat));
    res = opU(res, vec2(mapBuildings(pos), building_mat));
    res = opU(res, vec2(mapBigBuildings(pos), big_building_mat));
          //res = opU(res, vec2(mapBigBuildings(pos), big_building_mat));
          //res = opU(res, vec2(mapBigBuildings(pos * vec3(1.0, 4.5, 1.0) + vec3(0.0, 0.0, -1.0)), big_building_mat));
          //res = opU(res, vec2(mapBigBuildings(pos * vec3(1.0, 6.5, 1.0) + vec3(-3.0, 0.0, -1.0)), big_building_mat));
          //res = opU(res, vec2(mapBigBuildings(pos * vec3(1.0, 2.0, 1.0) + vec3(3.0, 0.0, -1.0)), big_building_mat));
    return res;
}

const float maxHei = 0.8;

vec2 castRay(in vec3 ro, in vec3 rd) {
    float tmin = 1.0;
    float tmax = 200.0;

    float t = tmin;
    float m = -1.0;
    for(int i = 0; i < 256; i++) {
        float precis = 0.00005 * t;
        vec2 res = map(ro + rd * t);
        if(res.x < precis || t > tmax)
            break;
        t += res.x * 0.6;
        m = res.y;
    }

    if(t > tmax)
        m = -1.0;
    return vec2(t, m);
}

vec2 castRay2(in vec3 ro, in vec3 rd) {
    float tmin = 1.0;
    float tmax = 200.0;

    float t = tmin;
    float m = -1.0;
    for(int i = 0; i < 256; i++) {
        float precis = 0.00005 * t;
        vec2 res = map2(ro + rd * t);
        if(res.x < precis || t > tmax)
            break;
        t += res.x * 0.6;
        m = res.y;
    }

    if(t > tmax)
        m = -1.0;
    return vec2(t, m);
}

      // https://iquilezles.org/articles/rmshadows
float calcSoftshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax) {
          // bounding volume
    float tp = (maxHei - ro.y) / rd.y;
    if(tp > 0.0)
        tmax = min(tmax, tp);

    float res = 1.0;
    float t = mint;
    for(int i = ZERO; i < 16; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);
        if(res < 0.005 || t > tmax)
            break;
    }
    return clamp(res, 0.0, 1.0);
}

      // https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(in vec3 pos) {
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0005;
    return normalize(e.xyy * map(pos + e.xyy).x +
        e.yyx * map(pos + e.yyx).x +
        e.yxy * map(pos + e.yxy).x +
        e.xxx * map(pos + e.xxx).x);

}

float calcAO(in vec3 pos, in vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for(int i = ZERO; i < 5; i++) {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3 aopos = nor * hr + pos;
        float dd = map(aopos).x;
        occ += -(dd - hr) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * nor.y);
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = (cross(cu, cw));
    return mat3(cu, cv, cw);
}

vec3 shade_floor(vec3 pos) {
    vec3 col = vec3(0.0025, 0.0005, 0.002);
    pos.x += iTime * 0.4;
    float scale = 3.0;
    vec2 fuv = fract(scale * pos.xz);

    fuv = abs(abs(fuv) - 0.5);

    col += vec3(0.6, 0.01, 0.6) * 85.5 * smoothstep(0.47, 0.5, smax(fuv.x, fuv.y, 15.0));

          //col += col * 200.0 * smoothstep(.0, 1.5, min(fuv.x, fuv.y));
         // col += vec3(.3) * smoothstep(0.1, 0.35, abs(fuv.x)*abs(fuv.y) );

    float f = 1.0 / length(pos / 15.0 - vec3(0.0, 0.0, -0.1 * 20.0 + 1.0));
    f = clamp(0.0, 1.0, pow(f, 2.9));
    f = smoothstep(0.2, 0.9, f) * 0.7;
         // col += mix(vec3(250.0 / 255.0, 0.0 / 255.0, 124.0/255.0), vec3(0.0), 1.0-f);
    return col;
}

float window(vec2 uv, vec3 p) {

    float s = 1.0;
    vec3 id = floor(p);
    vec2 fuv = abs(fract(uv * s) - vec2(0.5));
    vec2 fid = uv - fract(uv);
    float size = 0.20;
    float f = smoothstep(size, size - 0.1, max(fuv.x, fuv.y));
    vec2 h = hash(fid + id.zx);
    f *= step(h.x, 0.6);
    return f;
}

vec3 shade_window(vec3 pos, vec3 nor, float r) {

    if(abs(nor.y) > 0.001)
        return vec3(.0);
    vec2 uv = vec2(pos.x * nor.z + pos.z * nor.x + pos.y * 0.0, pos.y * nor.z + pos.y * nor.x + pos.z * nor.y);
    float window_factor = window(uv * 40.0, pos);
    vec3 c_window = vec3(0.4, 0.4, 0.4) * 5.0;
    float d = 9.0;
    window_factor *= smoothstep(d, d - 10.0, r);
      //    return vec3(r/100.0);
    return c_window * window_factor;
}

vec3 shade_buildings(vec3 pos, float t) {
    float f = 1.0 / length(pos / 15.0 - vec3(0.0, 0.0, -0.1 * 20.0 + 1.0));
    f = clamp(0.0, 1.0, pow(f, 2.9));
    f = smoothstep(0.2, 0.9, f) * 0.7;
    vec3 nor = calcNormal(pos);
    vec3 col = mix(vec3(250.0 / 255.0, 0.0 / 255.0, 124.0 / 255.0), vec3(0.0), 1.0 - f);
    pos.x += 0.4 * iTime;

    vec3 c_window = shade_window(pos, nor, t);
    return c_window + col;
}

vec3 shade_sky(vec2 uv) {
    vec3 col;

    vec3 col_top = vec3(0.001, 0.0, 0.02);
    vec3 col_bot = vec3(0.1, 0.02, 0.24);
    vec3 col_light = vec3(420.0 / 255.0, 0.0 / 255.0, 104.0 / 255.0);

    col = mix(col_bot, col_top, min(1.0, 0.3 + uv.y * 1.3));
    float i = length(1.3 * (uv - vec2(0.0, -0.3)) * vec2(0.2, 2.0));
               //i = .8 / length(uv.y - 1.0);
      //        i = clamp(0.0, 1.0, i);
        //      col = col_sun * (1.0 - i) + col;
    vec3 col_sun = vec3(1.0, 0.3, 0.2) * 1.0;
             // col_sun = pow(col_sun, vec3(1.3 + 0.6 * oscillate()) );
    float j = length(4.0 * (uv - vec2(0.0, -0.2)) * vec2(0.6, .6));
    float sun_value = smoothstep(1.5, 1.4, j);
    sun_value *= smoothstep(0.9, 1.0, 1.0 - stripes(uv.y * 2.0));
    col = mix(col, col_sun, sun_value * 1.5);
    col = mix(col_light * 0.7, col, clamp(0.0, 1.0, i / 1.4));
              //uv.x += iTime * 0.05;
    float star = texture(iChannel0, texture(iChannel1, uv).xz).r;
    uv.xy += texture(iChannel1, uv * 200.0).xy / 10.0;
    uv.x += iTime * 0.01;
    vec2 closest_star = voronoi(uv * 100.0);
    star = (2.5 * pow(texture(iChannel1, uv * 1.0).x, 3.0)) / length(closest_star);
    star = pow(star, 1.0);
    float star_treshold = 3.9;
    star = mix(star, 0.0, smoothstep(1.5, 1.4, j));
    col = mix(col, vec3(0.4), smoothstep(star_treshold - 0.01, star_treshold, star));
    return col;
}

vec3 shade(vec2 res, vec3 pos, vec2 uv) {
    vec3 col;

    if(res.y == floor_mat) {
        col = vec3(0.2);
        col = shade_floor(pos);
    } else if(res.y == sky_mat) {
        col = shade_sky(uv);
    } else if(res.y == building_mat) {
        col = shade_buildings(pos, res.x);
    } else if(res.y == big_building_mat) {
        vec3 nor = calcNormal(pos);
        vec3 col_light = vec3(420.0 / 255.0, 0.0 / 255.0, 104.0 / 255.0);

        col = col_light * 0.2 + 0.3 * shade_window(pos / 10.0, nor, 0.0);
        col *= smoothstep(0.9, -0.3, uv.y * 4.0 + 0.6);
      //        col = calcNormal(pos);
    }

    return col;
}

vec3 render(in vec3 ro, in vec3 rd, vec2 uv) {
    vec3 col = vec3(.0);
    vec2 res = castRay(ro, rd);

    vec2 res2 = castRay2(ro, rd);
    float t = res.x;
    float m = res.y;
    if(res.y != sky_mat && !(res.y == big_building_mat && res2.y == floor_mat)) {
        vec3 pos = ro + rd * t;
        col = shade(res, pos, uv);
        if(res.y == building_mat) {
            col = mix(col, shade(res2, ro + rd * res2.x, uv), 0.01);
        }
    } else {
        vec3 pos = ro + rd * res2.x;
        col = shade(res2, pos, uv);
    }
    return vec3(col);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 mo = vec2(0.0);//iMouse.xy/iResolution.xy;
    float time = 15.0 + iTime;

    vec3 tot = vec3(0.0);
      #if AA>1
    for(int m = 0; m < AA; m++) for(int n = 0; n < AA; n++) {
              // pixel coordinates
            vec2 o = vec2(float(m), float(n)) / float(AA) - 0.5;
            vec2 p = (-iResolution.xy + 2.0 * (fragCoord + o)) / iResolution.y;
      #else
            vec2 p = (-iResolution.xy + 2.0 * fragCoord) / iResolution.y;
      #endif
            p.y += sin(p.x - 1.57) / -13.0;
      		// camera (ro = ray origin)
            vec3 ro = vec3(0.0, 0.5, 10.0);
            vec3 ta = vec3(0.0, 2.05, 1.0);
              // camera-to-world transformation
            mat3 ca = setCamera(ro, ta, 0.0);
              // ray direction
            vec3 rd = ca * normalize(vec3(p.xy, 0.8));

              // render
            vec3 col = render(ro, rd, p);
            col += vec3(0.1, 0.0, 0.07) / 2.0;

      		// gamma
            col = pow(col, vec3(0.6545 + 0.2 * oscillate()));
            tot += col;

      #if AA>1
        }
    tot /= float(AA * AA);
      #endif

    fragColor = vec4(tot, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}