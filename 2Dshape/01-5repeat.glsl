vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
//圆半径
const float r = 0.3;
float shape(in vec2 p) {
    //像素坐标取模
    vec2 a = mod(p + r, 2. * r) - r;
    return sdCircle(a, r);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);
    //距离函数
    float d = shape(uv);
    //形状的颜色
    vec3 shapeColor = vec3(1., 0., 0.);
    vec3 color = (1. - sign(d)) * shapeColor;
    fragColor = vec4(color, 1.);
}