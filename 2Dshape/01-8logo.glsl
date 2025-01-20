vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 
float ndot(vec2 a, vec2 b) {
    return a.x * b.x - a.y * b.y;
}
//菱形 p像素坐标，b的x对应横向对角线长度，y对应纵向对角线长度
float sdRhombus(in vec2 p, in vec2 b) {
    p = abs(p);
    float h = clamp(ndot(b - 2.0 * p, b) / dot(b, b), -1.0, 1.0);
    float d = length(p - 0.5 * b * vec2(1.0 - h, 1.0 + h));
    return d * sign(p.x * b.y + p.y * b.x - b.x * b.y);
}
//两个菱形的差集即为一条有宽度折线
// a为第一个菱形的位置，b为第二个菱形的位置，size两个菱形的大小
float line(vec2 p, vec2 a, vec2 b, vec2 size) {
    float d1 = sdRhombus(p - a, size);
    float d2 = sdRhombus(p - b, size);
    return max(-1. * d1, d2);
}
const float PI = 3.1415926;

float shape(in vec2 p) {
    //绕圆移顺时针动起来
    vec2 m = vec2(-cos(iTime * PI * 0.5), sin(iTime * PI * 0.5)) * 0.5;
    p += m;
    //缩小成原来的1/2
    p *= 2.0;
    //顶部小菱形
    float d = sdRhombus(p - vec2(0., 0.2), vec2(0.12, 0.1));
    //折线1
    float l = line(p, vec2(0., 0.12), vec2(0., 0.0), vec2(0.36, 0.3));
   //折线2
    float ll = line(p, vec2(0., -0.12), vec2(0., -0.24), vec2(0.6, 0.5));
    //合并形状
    return min(ll, min(l, d));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = getUV(fragCoord);
    //距离函数
    float d = shape(uv);
    //背景颜色，蓝色
    vec3 bg = vec3(0.117, 0.5, 1.);
    //形状的颜色，白色
    vec3 shapeColor = vec3(1.0);
    vec3 color = (1. - sign(d)) * shapeColor + bg;
    fragColor = vec4(color, 1.);
}