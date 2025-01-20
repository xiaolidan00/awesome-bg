vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
const float PI = 3.1415926;
//r半径，a占角度的比例
vec2 anglePos(float r, float a) {
    a *= PI * 2.0;
    return r * vec2(sin(a), cos(a));
}
float shape(in vec2 p) {
    float d = 9.;
    //360度六等分
    float unit = 1. / 6.;
    //坐标偏移半径
    float radius = 0.5;
    //遍历绘制多个圆形
    for(int i = 0; i < 6; i++) {
        d = min(d, sdCircle(p - anglePos(radius, float(i) * unit), 0.2));
    }
    return d;
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