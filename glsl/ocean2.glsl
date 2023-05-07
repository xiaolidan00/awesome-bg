       /*
       * Original shader from: https://www.shadertoy.com/view/NllBzM
       */

      #ifdef GL_ES
precision highp float;
      #endif

      // glslsandbox uniforms
uniform float time;
uniform vec2 resolution;

      // shadertoy emulation
      #define iTime time
      #define iResolution resolution

      // --------[ Original ShaderToy begins here ]---------- //
      // School's out by Kristian Sivonen (ruojake)
      // CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float thing(vec3 p) {
    float t = iTime * 3.141592;

    p.xy *= rot(p.z * .01);
    p.xz *= rot(t * -.1);

    vec3 i = floor(p / 16. + .5);
    p.xz += i.y * t;
    p = fract(p / 16. + .5) * 16. - 8.;

    float s = sin(t + dot(i, vec3(1)));
    float ns = s * -.5 + .5;

    p.xz *= rot(t * .3 + i.x - i.z);
    p.xz *= rot(p.y + t * .2);
    p.yx *= rot(p.z * .5);
    p.x -= clamp(p.x + .2, -.5, .5);
    p.z -= clamp(p.z - .4, -.5, .5);
    p = abs(p) - 1.7 - s * .55;

    return (length(p) - .6) * (.4 - s * .125);
}

float scene(vec3 p) {
    return min(thing(p), thing(-p + 8.)) - .05;
}

vec3 normal(vec3 p, float d) {
    vec2 e = vec2(.001, 0);

    return normalize(d - vec3(scene(p - e.xyy), scene(p - e.yxy), scene(p - e.yyx)));
}

float shadow(vec3 o, vec3 ld) {
    float d = 0.;
    float t = .1;
    vec3 p;
    for(int i = 0; i < 250; ++i) {
        p = o + t * ld;
        d = scene(p);
        if(abs(d) < .01 || t > 32.)
            return clamp((t - 24.) / 8., 0., 1.);
        t += d;
    }
    return 1.;
}

float lum(vec3 c) {
    return dot(c, vec3(.2126, .7152, .0722));
}

vec3 reinhard(vec3 c) {
    float l = lum(c);
    float n = l * (1. + l / 9.) / (1. + l);
    return c * n / l;
}

float vignette(vec2 fc) {
    vec2 uv = fc / iResolution.xy * 2. - 1.;
    float v = length(uv);
    return 1. - v * v * v * .25;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;
    ;

    vec3 ro = vec3(0, 0, -12);
    vec3 rd = normalize(vec3(uv, 2));
    vec3 p;
    float d, t = 0.;

    for(float i = 0.; i < 1.; i += 1. / 256.) {
        if(t >= 120.)
            break;
        p = ro + rd * t;
        d = scene(p);
        if(abs(d) < .0001 * t)
            break;
        t += d;
    }
    vec3 ld = normalize(vec3(1));
    vec3 n = normal(p, d);

    float l = dot(ld, n) * .5 + .5;
    float s = shadow(p + n * .01, ld);
    l *= s;
    float spec = pow(clamp(dot(reflect(rd, n), ld), 0., 1.), 32.) * s;
    float e = exp(-t * .05 + .3);
    vec3 fog = mix(vec3(.025, .1, .15), vec3(2., 1.55, 1.22), clamp(l * e + clamp(dot(rd, ld) * 2. - 1., 0., 1.) * .1, 0., 1.));
    vec3 col = mix(vec3(l) + spec * 3., fog, 1. - e);

    col = mix(vec3(lum(col)), col, 1.5);
    col = reinhard(col);
    col = pow(col, vec3(1. / 2.2));
    col *= vignette(fragCoord);
          //col = vec3(i);
    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}