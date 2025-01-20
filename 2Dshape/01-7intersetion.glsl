vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
float sdHexagon(in vec2 p, in float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}
const float PI = 3.1415926;

float shape(in vec2 p) {
    //两个形状的交集，六边形与圆形的距离，取两者的最大值
    return max(sdHexagon(p - vec2(-0.3, 0), 0.5), sdCircle(p - vec2(0.3, 0), 0.5));
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