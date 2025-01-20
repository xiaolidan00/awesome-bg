vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 
float sdHexagon(in vec2 p, in float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

const float PI = 3.1415926;
float shape(in vec2 p) {
    //沿着圆弧移动
    vec2 translate = vec2(cos(iTime * PI), sin(iTime * PI)) * 0.5;
    //坐标移动
    vec2 m = translate + p;
    //六边形
    return sdHexagon(m, 0.3);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);
    //圆的距离函数
    float d = shape(uv);
    //圆的颜色
    vec3 circleColor = vec3(1., 0., 0.);
    //sign返回数值的正负符号，-1,1,0
    //sign(d)，-1在圆内，0在边上，1在圆外
    //1.-sign(d)取反，即1为在圆内显示圆的颜色
    vec3 color = (1. - sign(d)) * circleColor;
    fragColor = vec4(color, 1.);
}