vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
//平滑最小值，融合形状
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
const float PI = 3.1415926;
float shape(in vec2 p) {
    //平滑融合程度
    float k = 0.5 * abs(sin(iTime * PI));
    float d = sdCircle(p - vec2(-0.5, 0.5), 0.2);
    d = smin(d, sdCircle(p - vec2(0.5, 0.5), 0.2), k);
    return smin(d, sdCircle(p - vec2(0., 0.), 0.5), k);
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