 #ifdef GL_ES
precision mediump float;
      #endif

      #extension GL_OES_standard_derivatives : enable

      #define NUM_OCTAVES 16

uniform float time;//
uniform vec2 resolution;

mat3 rotX(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}
mat3 rotY(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

float getsat(vec3 c) {
    float mi = min(min(c.x, c.y), c.z);
    float ma = max(max(c.x, c.y), c.z);
    return (ma - mi) / (ma + 1e-7);
}

      //from my "Will it blend" shader (https://www.shadertoy.com/view/lsdGzN)
vec3 iLerp(in vec3 a, in vec3 b, in float x) {
    vec3 ic = mix(a, b, x) + vec3(1e-6, 0., 0.);
    float sd = abs(getsat(ic) - mix(getsat(a), getsat(b), x));
    vec3 dir = normalize(vec3(2. * ic.x - ic.y - ic.z, 2. * ic.y - ic.x - ic.z, 2. * ic.z - ic.y - ic.x));
    float lgt = dot(vec3(1.0), ic);
    float ff = dot(dir, normalize(ic));
    ic += 1.5 * dir * sd * ff * lgt;
    return clamp(ic, 0., 1.);
}

float random(vec2 pos) {
    return fract(sin(dot(pos.xy, vec2(1399.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    float a = random(i + vec2(0.0, 0.0));
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 pos) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for(int i = 0; i < NUM_OCTAVES; i++) {
        v += a * noise(pos);
        pos = rot * pos * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 1.0 - resolution.xy) / min(resolution.x, resolution.y);

    float t = 0.0, d;

    float time2 = 0.6 * time / 2.0;

    vec2 q = vec2(0.0);
    q.x = fbm(p + 0.30 * time2);
    q.y = fbm(p + vec2(1.0));
    vec2 r = vec2(0.0);
    r.x = fbm(p + q + vec2(2.2, 3.2) + 0.135 * time2);
    r.y = fbm(p + q + vec2(8.8, 2.8) + 0.126 * time2);
    float f = fbm(p + r);
    vec3 color = mix(vec3(0.9, 0.0, 0.1),
      	 //   iLerp(color.bgr, color.rgb, clamp(1.-(f*f),0.05,1.)),
    vec3(1, 0, 0.7), clamp((f * f) * 10.0, 0.0, 5.0));
    color = iLerp(color.bgr, color.rgb, clamp(1. - (f * f), 0.05, 1.));
    color = pow(color, vec3(.55, 0.65, 0.6)) * vec3(1., .97, .9);

    color = mix(
             // color,
             // vec3(1, 0.6, 0.3),
    iLerp(color.bgr, color.rgb, clamp(1. - (f * f), 0.05, 1.)), pow(color, vec3(.55, 0.65, 0.6)) * vec3(1., .97, .9) * 0.7 + 0.13,
      	   // vec3(.55,0.65,0.6)*vec3(1.,.97,.9) * 0.7 + 0.3,
    clamp(length(q), 0.0, 1.0));
    color *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.12) * 0.7 + 0.3; //Vign

    color = mix(color,
              //vec3(0.5 + 0.5*sin(time+p.yxx+vec3(0,2,4))),
    iLerp(color.bgr, color.rgb, clamp(1. - (f * f), 0.05, 1.)), clamp(length(p), 1.0, 1.0));

    color = (f * f * f + 1.0 * f * f + 1.0 * f) * color;

    gl_FragColor = vec4(color, 1.0);
}