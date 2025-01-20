vec2 getUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);
}
//https://iquilezles.org/articles/distfunctions2d/ 

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float shape(in vec2 p) {
    float d = sdCircle(p - vec2(-0.5, 0.5), 0.2);
    d = min(d, sdCircle(p - vec2(0.5, 0.5), 0.2));
    return min(d, sdCircle(p - vec2(0., 0.), 0.5));
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