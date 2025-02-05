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
vec2 minV(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}
vec2 scene(vec3 p) {
    vec2 a = vec2(sdSphere(p - vec3(0., 1., 0.), 1.), 2.);
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
    float m = 0.;
    for(int i = 0; i < rayCount; i++) {
        //移动后的点坐标
        vec3 p = pos + direction * t;
        vec2 a = scene(p);
        //坐标点与场景距离
        float d = a.x;
        m = a.y;

        if(d < minDistance //判断是否在场景内
        || t > maxDistance//判断是否在可视范围外
        )//符合条件，停止移动
            break;
        //增加距离成为下一个点做准备
        t += d;

    }
    return vec2(t, m);
}

//https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal(in vec3 p) // for function f(p)
{
    const float eps = 0.0005; // or some other value
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(scene(p + h.xyy).x - scene(p - h.xyy).x, scene(p + h.yxy).x - scene(p - h.yxy).x, scene(p + h.yyx).x - scene(p - h.yyx).x));
}
 //平行光方向
const vec3 lightDirection = vec3(3., 0.7, 0.8);
// nor是法向量，color是物体颜色
vec3 setLight(vec3 nor, vec3 color) {
    //平行光照强度和颜色,强度1.0，颜色黄色
    float intensity = 1.0;
    vec3 lightColor = intensity * vec3(1.0, 1.0, 0.);
//平行光方向，归一化
    vec3 lightNor = normalize(lightDirection);
 //计算光线方向和法向量的点积
    float nDotL = max(dot(lightNor, nor), 0.0);
//计算漫反射颜色
    vec3 diffuse = lightColor * color * nDotL;
    //环境光
    vec3 amb = vec3(0.3);
    return amb + diffuse;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);

    //相机位置
    vec3 ro = vec3(0., 1., -3.);
    //视线方向
    vec3 rd = normalize(vec3(uv, 1.0));
    //采用光线步进算法，计算与场景相交点距离
    vec2 a = raymarching(ro, rd);
    float d = a.x;
    //因为d的值有可能大于1，要缩小一下
    float m = d * 0.1;
    //相交点坐标
    vec3 p = ro + rd * d;
    //计算相交点的法向量
    vec3 n = calcNormal(p);
    //背景颜色 蓝色
    vec3 bg = vec3(0., 0., 1.);
    //场景颜色 白色
    vec3 objColor = vec3(0.);
    if(a.y > 1.5) {
        objColor = vec3(1.0, 0.68, 0.0);
    } else {
        objColor = vec3(1., 1., 1.);
    }

    //光线颜色
    vec3 result = setLight(n, objColor);
      //背景与场景颜色混合成最终显示颜色
    vec3 color = mix(result, bg, m);

    fragColor = vec4(color, 1.);

}