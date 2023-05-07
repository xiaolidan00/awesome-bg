    /*
       * Original shader from: https://www.shadertoy.com/view/7sBfDD
       */

  //定义精度
#ifdef GL_ES
precision highp float;
#endif
//传入的值
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;
//定义成shadertoy的变量名
//#define iMouse mouse
#define iTime time
#define iResolution resolution
//这里的iMouse需要转换
vec2 iMouse = vec2(0.0);

//--------------------- shadertoy start---------------------
#define pi 3.14159

mat2 Rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 ms = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

          // change me! (and uncomment for loop stuff below)
    float A = 1.;    // -1. // 0.
    float r = 0.3;   // 0.6
    float th = 0.02; // 0.12

    vec2 dir = uv - ms;
    float a = atan(dir.x, dir.y);
    float s = 0.;

          // n is higher than it needs to be but works fine
    const float n = 20.;
    float k = 6. / iResolution.y;

    for(float i = n; i > 0.; i--) {
        float io = A * 2. * pi * i / n;
        float sc = -4. - 0.5 * i + 0.9 * cos(io - 9. * length(dir) + iTime);
        vec2 fpos = fract(sc * uv + 0.5 * i * ms) - 0.5;
              //fpos = abs(fpos) - 0.25;
        fpos *= Rot(a); // a + io // 5. * a // a + 3. * atan(fpos.x, fpos.y)
        float d = abs(fpos.x);
        s *= 0.865;
        s += step(0., s) * smoothstep(-k, k, -abs(d - r) + th);
    }

    float val = s * 0.1 + 0.72 + 0. * iTime - 0.23 * pow(dot(dir, dir), 0.25);
    val = clamp(val, 0.4, 1.);
    vec3 e = vec3(1);
    vec3 col = 0.5 * pal(val, e, e, e, 0.24 * vec3(0, 1, 2) / 3.);
    col = smoothstep(0., 1., col);

    fragColor = vec4(col, 1.0);
}
//--------------------- shadertoy end---------------------

void main(void) {
    iMouse = mouse * resolution;
    mainImage(gl_FragColor, gl_FragCoord.xy);
}