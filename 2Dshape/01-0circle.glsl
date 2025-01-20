vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 
// p像素点坐标，center为圆的坐标，r为圆的半径,
//计算像素点到圆点的距离与半径的差
float sdCircle(vec2 p, vec2 center, float r) {
    return length(p - center) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);
    //圆的距离函数
    float d = sdCircle(uv, vec2(0.), 0.7);
    //圆的颜色
    vec3 circleColor = vec3(1., 0., 0.);
    //sign返回数值的正负符号，-1,1,0
    //sign(d)，-1在圆内，0在边上，1在圆外
    //1.-sign(d)取反，即1为在圆内显示圆的颜色
    vec3 color = (1. - sign(d)) * circleColor;
    fragColor = vec4(color, 1.);
}