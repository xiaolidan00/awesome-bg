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
//场景形状组合
float scene(vec3 p) {
    return min(sdSphere(p - vec3(0., 1., 0.), 1.), sdPlane(p));
}

//https://www.shadertoy.com/view/tdS3DG
const float minDistance = 0.01;//最小距离
const float maxDistance = 100.0;//最远距离
const int rayCount = 128;//光线步进移动次数
//pos像素点位置，direction视线方向
float raymarching(vec3 pos, vec3 direction) {
    float t = 0.0;
    for(int i = 0; i < rayCount; i++) {
        //移动后的点坐标
        vec3 p = pos + direction * t;
        //坐标点与场景距离
        float d = scene(p);

        if(d < minDistance //判断是否在场景内
        || t > maxDistance//判断是否在可视范围外
        )//符合条件，停止移动
            break;
        //增加距离成为下一个点做准备
        t += d;

    }
    return t;
}

//https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal(in vec3 p) // for function f(p)
{
    const float eps = 0.0005; // or some other value
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(scene(p + h.xyy) - scene(p - h.xyy), scene(p + h.yxy) - scene(p - h.yxy), scene(p + h.yyx) - scene(p - h.yyx)));
}

// nor是法向量，color是物体颜色
vec3 setLight(vec3 p, vec3 color) {

 //计算相交点的法向量
    vec3 nor = calcNormal(p);
 //平行光方向
    const vec3 lightDirection = vec3(1., 2., -3.);
    //平行光照强度和颜色,强度1.0 
    float intensity = 1.0;
    vec3 lightColor = intensity * vec3(1.0, 1.0, 1.);
//平行光方向，归一化
    vec3 lightNor = normalize(lightDirection - p);
 //计算光线方向和法向量的点积
    float nDotL = max(dot(lightNor, nor), 0.0);
//计算漫反射颜色
    vec3 diffuse = lightColor * nDotL;
    //环境光
    vec3 amb = vec3(0.3);
    return (amb + diffuse) * color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.);
    vec2 uv = getUV(fragCoord);
    //相机位置
    vec3 ro = vec3(0., 1., -3.);
    //视线方向
    vec3 rd = normalize(vec3(uv, 1.0));
    //采用光线步进算法，计算与场景相交点距离
    float d = raymarching(ro, rd);
    if(d < maxDistance) {//可视范围内进行着色处理
     //相交点坐标
        vec3 p = ro + rd * d;
        color = setLight(p, vec3(1.0));
    }
    fragColor = vec4(color, 1.);
}