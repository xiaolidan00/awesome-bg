const float PI = 3.1415926;
vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions/
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

//https://www.shadertoy.com/view/ldfSWs
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
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);
    //相机位置
    vec3 ro = vec3(0., 1., -3.);
    //视线方向
    vec3 rd = normalize(vec3(uv, 1.0));
    //采用光线步进算法，计算与场景相交点距离
    float d = raymarching(ro, rd);
    //因为d的值有可能大于1，要缩小一下
    //d距离越远的值越大，(1.-d)后，距离越远值越小，符合近大远小的规律
    float m = (1.0 - d * 0.1);
     //背景与场景颜色混合成最终显示颜色
    vec3 color = vec3(m);
    fragColor = vec4(color, 1.);
}