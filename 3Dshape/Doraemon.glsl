const float PI = 3.1415926;
const float MIND = 0.01;//最小距离
const float MAXD = 100.0;//最远距离
const int COUNT = 128;//光线步进移动次数
vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/smin/
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
vec4 minV(vec4 a, vec4 b) {
    return a.x < b.x ? a : b;
}
vec2 minV(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}
mat2 rotmat(float a) {
    a *= PI;
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}
//https://iquilezles.org/articles/distfunctions2d/
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
float sdCutDisk(in vec2 p, in float r, in float h) {
    float w = sqrt(r * r - h * h);
    p.x = abs(p.x);
    float s = max((h - r) * p.x * p.x + w * w * (h + r - 2.0 * p.y), h * p.x - w * p.y);
    return (s < 0.0) ? length(p) - r : (p.x < w) ? h - p.y : length(p - vec2(w, h));
}
float sdBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
//https://iquilezles.org/articles/distfunctions/
float sdTorus(vec3 p, vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}
float sdRoundBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}
float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}
float sdCappedCone(vec3 p, vec3 a, vec3 b, float ra, float rb) {
    float rba = rb - ra;
    float baba = dot(b - a, b - a);
    float papa = dot(p - a, p - a);
    float paba = dot(p - a, b - a) / baba;
    float x = sqrt(papa - paba * paba * baba);
    float cax = max(0.0, x - ((paba < 0.5) ? ra : rb));
    float cay = abs(paba - 0.5) - 0.5;
    float k = rba * rba + baba;
    float f = clamp((rba * (x - ra) + paba * baba) / k, 0.0, 1.0);
    float cbx = x - ra - f * rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
}
//平面，p坐标点 
float body(vec3 p) {
    float a = sdSphere(p - vec3(0., -0.2, 0.), 0.8);
    float b = sdCappedCone(p, vec3(-0.5, 0.1, 0.2), vec3(-1.2, -0.2, 0.5), 0.2, 0.2);
    float c = sdCappedCone(p, vec3(0.5, 0.1, 0.2), vec3(1.2, -0.2, 0.5), 0.2, 0.2);
    float h = 0.8, x = 0.30, xx = 0.5, z = 0.0, zz = 1.;
    float b1 = sdCappedCone(p, vec3(-x, -0.5, z), vec3(-xx, -h - zz, z), 0.4, 0.35);
    float c1 = sdCappedCone(p, vec3(x, -0.5, z), vec3(xx, -h - zz, z), 0.4, 0.35);
    float bb = smin(smin(a, b, 0.1), c, 0.1);
    return smin(smin(b1, bb, 0.3), c1, 0.3);
}

float huxu(vec3 p) {
    float r = 0.0001, h = 1.3, z = 0.97, x = 0.6, xx = 0.2;
    float a = sdCapsule(p, vec3(-x, h, z - 0.1), vec3(-xx, h - 0.05, z), r);
    float b = sdCapsule(p, vec3(x, h, z - 0.1), vec3(xx, h - 0.05, z), r);
    float h1 = 1.15, z1 = 0.98, x1 = 0.7, xx1 = 0.2;
    float a1 = sdCapsule(p, vec3(-x1, h1, z1 - 0.1), vec3(-xx1, h1, z1), r);
    float b1 = sdCapsule(p, vec3(x1, h1, z1 - 0.1), vec3(xx1, h1, z1), r);
    float h2 = 1.0, z2 = 1., x2 = 0.6, xx2 = 0.2;
    float a2 = sdCapsule(p, vec3(-x2, h2 - 0.05, z2 - 0.1), vec3(-xx2, h2, z2), r);
    float b2 = sdCapsule(p, vec3(x2, h2 - 0.05, z2 - 0.1), vec3(xx2, h2, z2), r);
    return min(min(min(a, b), min(a1, b1)), min(a2, b2));
}

float hand(vec3 p) {
    float s = 0.3, x = 1.2, y = 0.2, z = 0.5;
    float a = sdSphere((p - vec3(-x, -y, z)), s);
    float b = sdSphere((p - vec3(x, -y, z)), s);
    return min(a, b);
}
float jio(vec3 p) {
    float r = 0.4, x = 0.5, y = 2.3, z = 0.0;
    vec3 size = vec3(0.45, 0.4, 0.6);
    float a = sdRoundBox(p - vec3(-x, -y, z), size, r);
    float b = sdRoundBox(p - vec3(x, -y, z), size, r);
    return min(a, b);
}

//场景形状组合
vec2 scene(vec3 p) {     
    //脑袋
    float a = sdSphere(p - vec3(0., 1., 0.), 1.);
    //项圈
    vec2 b = vec2(sdTorus(p - vec3(0., 0.3, 0.), vec2(0.7, 0.06)), 1.);
   //鼻子
    vec2 c = vec2(sdSphere(p - vec3(0., 1.5, 0.9), 0.08), 1.);
    //胡须
    vec2 h = vec2(huxu(p), 0.0); 
    //手
    vec2 hh = vec2(hand(p), 4.);
    //脚
    vec2 j = vec2(jio(p), 4.);
    //身体
    vec2 bb = vec2(body(p), 11.);
    vec2[] list = vec2[](b, c, h, hh, j, bb);
    vec2 res = vec2(a, 10.);
    for(int i = 0; i < list.length(); i++) res = minV(res, list[i]);
    return res;
} 
//https://www.shadertoy.com/view/tdS3DG
vec2 raymarching(vec3 pos, vec3 direction) {
    float t = 0.0, y = 0.;
    for(int i = 0; i < COUNT; i++) {
        vec2 a = scene(pos + direction * t);
        float d = a.x;
        y = a.y;
        if(d < MIND || t > MAXD)
            break;
        t += d;
    }
    return vec2(t, y);
} 
//https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal(in vec3 p) {
    const float eps = 0.0005; // or some other value
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(scene(p + h.xyy).x - scene(p - h.xyy).x, scene(p + h.yxy).x - scene(p - h.yxy).x, scene(p + h.yyx).x - scene(p - h.yyx).x));
}
vec3 shape(in vec3 rp) {
    vec3 color = vec3(0.05, 0.59, 0.9);
    vec2 uv = rp.xy;
    if(rp.z > 0.) {
        float a = sdCircle(uv - vec2(-0.21, 1.6), 0.2);
        float b = sdCircle(uv - vec2(0.21, 1.6), 0.2);
        float c = sdCircle(uv - vec2(0., 0.8), 0.75);
        float e = sdCircle(uv - vec2(-0.1, 1.55), 0.05);
        float e1 = sdCircle(uv - vec2(0.1, 1.55), 0.05);
        vec2 p = (uv - vec2(0., 0.96)) * rotmat(1.);
        float m = sdCutDisk(p, 0.4, 0.1);
        float eye1 = min(e, e1);
        float eye = max(min(a, b), -1. * eye1);
        float l = sdBox(uv - vec2(0., 1.15), vec2(0.005, 0.29));
        float face = max(max(max(max(c, -1. * m), -1. * eye), -1. * eye1), -1. * l);
        vec4 res = vec4(100.);
        vec4[] list = vec4[](vec4(eye, vec3(1.)), vec4(eye1, vec3(0.)), vec4(m, vec3(1.0, 0., 0.)), vec4(face, vec3(0.9)), vec4(l, vec3(0.85)));
        for(int i = 0; i < list.length(); i++) res = minV(list[i], res);
        if(sign(res.x) == -1.)
            color = res.yzw;

    }
    return color;
}
vec3 shapedai(in vec3 rp) {
    vec3 color = vec3(0.05, 0.59, 0.9);
    vec2 uv = rp.xy;
    if(rp.z > 0.) {
        vec2 p = rotmat(1.) * (uv - vec2(0., -0.1));
        float b = sdCutDisk(p, 0.45, 0.);
        float a = sdCircle(uv - vec2(0., -0.1), 0.5);
        vec4 res = minV(vec4(b, vec3(1.0)), vec4(max(a, -1. * b), vec3(0.9)));
        if(sign(res.x) == -1.)
            color = res.yzw;
    }
    return color;
}
// nor是法向量，t物体数值标志
vec3 setLight(vec3 p, float t) {
    vec3 color = vec3(0.);
    if(t > 10.5 && t < 11.5) {//身体
        color = shapedai(p);
    } else if(t > 0.5 && t < 1.5) {//项圈，鼻子
        color = vec3(1., 0., 0.);
    } else if(t > 3.5 && t < 4.5) {//手脚
        color = vec3(0.9, 0.9, 0.9);
    } else if(t > 9.5 && t < 10.5)//头
        color = shape(p);
    vec3 nor = calcNormal(p);
    const vec3 lightDir = vec3(3., 3., 3.);
    float intensity = 1.0;
    vec3 lightColor = intensity * vec3(1.0, 1.0, 1.);
    vec3 lightNor = normalize(lightDir);
    float nDotL = max(dot(lightNor, nor), 0.0);
    vec3 diffuse = lightColor * nDotL;
    vec3 amb = vec3(0.3);
    vec3 result = amb + diffuse;
    return result * color;
}

mat3 setCamera(vec3 target, vec3 position) {
    vec3 z = normalize(target - position);
    vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
    vec3 y = normalize(cross(x, z));
    return mat3(x, y, z);
}
//Anti-Aliasing抗锯齿
const int AA = 2;
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.);
    float isColor = 0., x = PI * iTime * 0.2, y = 0.;
    if(iMouse.z > 0.1) {
        x = (iMouse.x / iResolution.x) * PI * 2.;        
        // y = (iMouse.y / iResolution.y - 0.5) * PI;
    }
    vec3 ro = vec3(3. * sin(x) * cos(y), 2. * sin(y) + 1., 3. * cos(x) * cos(y));
    mat3 camera = setCamera(vec3(0.), ro);
    vec3 total = vec3(0.);
    for(int i = 0; i < AA; i++) {
        for(int j = 0; j < AA; j++) {
            vec2 offset = vec2(float(i), float(j)) / float(AA) - 0.5;
            vec2 uv = getUV(fragCoord + offset);
            vec3 rd = normalize(camera * vec3(uv, 1.0));
            vec2 f = raymarching(ro, rd);
            if(f.x < MAXD) {
                total += setLight(ro + rd * f.x, f.y);
                isColor++;
            }
        }
    }
    if(isColor == float(AA * AA))
        color = total / isColor;
    else {
        vec3 c = vec3(1.0, 0.73, 0.0);
        vec2 uv = getUV(fragCoord);
        color = mix(vec3(1.), c, length(uv));
    }
    fragColor = vec4(color, 1.);
}