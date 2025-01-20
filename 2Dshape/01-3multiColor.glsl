vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
vec4 minV(vec4 a, vec4 b) {
    return a.x < b.x ? a : b;
}
vec4 shape(in vec2 p) {
    //左上红色圆
    vec4 d = vec4(sdCircle(p - vec2(-0.5, 0.5), 0.2), vec3(1., 0., 0.));
    //右上绿色圆
    d = minV(d, vec4(sdCircle(p - vec2(0.5, 0.5), 0.2), vec3(0., 1.0, 0.)));
   //下中蓝色圆
    return minV(d, vec4(sdCircle(p - vec2(0., 0.), 0.5), vec3(0., 0., 1.)));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);
    //距离函数
    vec4 d = shape(uv);
    //形状的颜色
    vec3 shapeColor = d.yzw;
    vec3 color = (1. - sign(d.x)) * shapeColor;
    fragColor = vec4(color, 1.);
}