      /*
       * Original shader from: https://www.shadertoy.com/view/Dt33RS
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

      // Emulate a black texture
      #define texture(s, uv) vec4(0.0)

      // Emulate some GLSL ES 3.x
      #define round(x) (floor((x) + 0.5))

      // --------[ Original ShaderToy begins here ]---------- //
      /* "Disco Godrays" by @kishimisu (2023) - https://www.shadertoy.com/view/Dt33RS

         These are "fake" godrays made without tracing any additional ray.
         The maximum raymarching step size is set to 0.1 in order to sample the scene
         frequently (very inneficient) and some blue noise is added to reduce artefacts.
      */

      #define r(p) mat2(cos(round((atan(p.y,p.x)+k)/f)*f-k + vec4(0,33,11,0)))

void mainImage(out vec4 O, vec2 F) {
    float f = .2856, d = f, k = iTime * f, t;
    vec4 p, a = O *= t = 0.;
    vec2 R = iResolution.xy;
    for(int i = 0; i < 60; i++) {
        if(d <= .01)
            break;
        p.z -= 2.;
        p.zx *= r(p.xz);
        p.yx *= r(p.xy);

        a += smoothstep(.02, .0, length(p.yz) - .05) *
            smoothstep(1., .0, length(p) - 1.) *
            (1. + cos(k + k + t + t + vec4(0, 1, 2, 0)));

        t += d = min(max(length(p) - 1., .05 - length(p.yz)), .1 + texture(iChannel0, F / 1024.).r * .06);

        p = t * normalize(vec4((F + F - R) / R.y, 1, 0));
    }

    O = .5 * mix(O + .3, a, exp(-t * .1));
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
    gl_FragColor.a = 1.;
}