    /*
       * Original shader from: https://www.shadertoy.com/view/mtBGR1
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
      // This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
      // Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
      // or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
      // =========================================================================================================

      #define sat(a) clamp(a, 0., 1.)

float _sqr(vec2 p, vec2 s) {
    vec2 l = abs(p) - s;
    return max(l.x, l.y);
}
      #define r2d(a) mat2(cos(a), -sin(a),sin(a), cos(a))
vec3 rdr(vec2 uv) {
    vec3 col = vec3(0.);

    float globalShape = 10000999.;
    const float cnt = 32.;
    for(float i = 0.; i < cnt; ++i) {
        uv *= r2d((i / cnt) * .5);
        float th = 0.0001;
        float sz = .1 + pow(mod(i + iTime * 5.000, cnt) / cnt, 1.5) * .5;
        float shape = abs(_sqr(uv, vec2(1., .6) * sz)) - th;
        globalShape = min(globalShape, shape);
        col += pow(1. - sat(shape * 5.), 4.) * vec3(0.506, 0.7199990, 0.99986) * .1;
    }
    float sharp = iResolution.x;
    col = mix(col, vec3(1.), 1. - sat(globalShape * sharp));

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.xx;
    vec3 col = rdr(uv * r2d(-.25));
    col = mix(col, col.yxz, 1. - sat((abs(uv.x) - .1) * iResolution.x * .01));
    fragColor = vec4(col, 1.098789);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}