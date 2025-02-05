const float PI = 3.1415926;
vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//球体，p坐标点，s半径
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}
//平面，p坐标点 
float sdPlane(vec3 p) {
    return p.y;
}
//立方体 p坐标点 b的xyz对应长宽高
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

vec2 minV(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}
//相交
float intersectionShape(vec3 p) {
    return max(sdSphere(p - vec3(0., 1., 0.), 1.), sdBox(p - vec3(0., 1., 0.), vec3(0.5, 1., 1.5)));
}
//场景形状组合
vec2 scene(vec3 p) {
    vec2 a = vec2(intersectionShape(p), 2.0);
    vec2 b = vec2(sdPlane(p), 1.);

    return minV(a, b);
}

//https://www.shadertoy.com/view/tdS3DG
const float minDistance = 0.01;//最小距离
const float maxDistance = 100.0;//最远距离
const int rayCount = 128;//光线步进移动次数
//pos像素点位置，direction视线方向
vec2 raymarching(vec3 pos, vec3 direction) {
    float t = 0.0;
    float y = 0.;
    for(int i = 0; i < rayCount; i++) {
        //移动后的点坐标
        vec3 p = pos + direction * t;
        vec2 a = scene(p);
        //坐标点与场景距离
        float d = a.x;
        y = a.y;

        if(d < minDistance //判断是否在场景内
        || t > maxDistance//判断是否在可视范围外
        )//符合条件，停止移动
            break;
        //增加距离成为下一个点做准备
        t += d;

    }
    return vec2(t, y);
}

//https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal(in vec3 p) // for function f(p)
{
    const float eps = 0.0005; // or some other value
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(scene(p + h.xyy).x - scene(p - h.xyy).x, scene(p + h.yxy).x - scene(p - h.yxy).x, scene(p + h.yyx).x - scene(p - h.yyx).x));
}

//https://iquilezles.org/articles/rmshadows/
//柔和阴影 
float softshadow(in vec3 ro, in vec3 rd, float k) {
    float res = 1.0;
    float t = 0.;
    for(int i = 0; i < 256 && t < maxDistance; i++) {
        float h = scene(ro + rd * t).x;
        if(h < minDistance)
            return minDistance;
        res = min(res, k * h / t);
        t += h;
    }
    return res;
}
//环境光遮蔽 AO是来描绘物体和物体相交或靠近的时候遮挡周围漫反射光线的效果，增加明暗的层次感，特别是阴影的细节。
float calcAO(in vec3 pos, in vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3 aopos = nor * hr + pos;
        float dd = scene(aopos).x;
        occ += (hr - dd) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 2.0 * occ, 0.0, 1.0);
}
//黑白网格
vec3 groundGrid(vec3 p) {
    vec3 c1 = vec3(1.0);
    vec3 c2 = vec3(0.);
    float s = mod(floor(p.x + floor(p.z)), 2.);
    return mix(c1, c2, s);
}

// nor是法向量，t物体数值标志
vec3 setLight(vec3 p, float t) {
    vec3 color = vec3(0.);

    if(t > 1.5) {//球体 红色
        color = vec3(1.0, 0.0, 0.0);
    } else {//平面 黑白网格
        color = groundGrid(p);
    }
 //计算相交点的法向量
    vec3 nor = calcNormal(p);
//点光源位置
    const vec3 lightPos = vec3(2., 3., -3.);
    //光照强度和颜色,强度1.0 
    float intensity = 1.5;
    vec3 lightColor = intensity * vec3(1.0, 1.0, 1.);
//光线方向，归一化
    vec3 lightNor = normalize(lightPos - p);
 //计算光线方向和法向量的点积
    float nDotL = max(dot(lightNor, nor), 0.0);
//计算漫反射颜色
    vec3 diffuse = lightColor * nDotL;
    //环境光
    vec3 amb = vec3(0.3);

    //环境光遮蔽，丰富阴影细节
    amb *= calcAO(p, nor);

//相交点偏移一点点
    vec3 p1 = p + nor * minDistance;
//阴影，从相交点偏移点出发，沿着光线方向，与场景的相交情况
    float shadow = softshadow(p1, lightNor, 1.);
    //光的漫反射与阴影距离相乘，得到阴影投射后的颜色
    diffuse *= shadow;
    vec3 result = amb + diffuse;
    return result * color;
}

// target相机看向的目标坐标，position相机位置 
mat3 setCamera(vec3 target, vec3 position) {
    //z轴向量
    vec3 z = normalize(target - position);
     //x轴向量
    vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
    //y轴向量
    vec3 y = normalize(cross(x, z));
    return mat3(x, y, z);
}
//Anti-Aliasing抗锯齿
const int AA = 2;
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.);
    float isColor = 0.;
    float a = iTime * PI * 0.2;
    //相机位置动起来
    vec3 ro = vec3(3. * sin(a), 1., 3. * cos(a));

    mat3 camera = setCamera(vec3(0.), ro);

    vec3 total = vec3(0.);
    //抗锯齿：上下左右偏移一个像素，分别计算颜色值，加起来再取平均值
    for(int i = 0; i < AA; i++) {
        for(int j = 0; j < AA; j++) {
            vec2 offset = vec2(float(i), float(j)) / float(AA) - 0.5;
            vec2 uv = getUV(fragCoord + offset);
    //视线方向
            vec3 rd = normalize(camera * vec3(uv, 1.0));
    //采用光线步进算法，计算与场景相交点距离
            vec2 f = raymarching(ro, rd);
            float d = f.x;
            if(d < maxDistance) {//可视范围内进行着色处理
     //相交点坐标
                vec3 p = ro + rd * d;
                total += setLight(p, f.y);
                isColor++;
            }
        }
    }
    if(isColor == float(AA * AA))
        color = total / isColor;
    fragColor = vec4(color, 1.);
}