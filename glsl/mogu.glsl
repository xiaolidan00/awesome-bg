      /*
       * Original shader from: https://www.shadertoy.com/view/stlBD4
       */

      #ifdef GL_ES
precision highp float;
      #endif

      // glslsandbox uniforms
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

      // shadertoy emulation
      #define iTime time
      #define iResolution vec3(resolution,1.)

      // --------[ Original ShaderToy begins here ]---------- //
      //Tweet: https://twitter.com/XorDev/status/1518681953872064514
      //Twigl: https://t.co/BVcKVKeqMv

      ///Original Version [335 chars]
      #define L length

void mainImage(out vec4 O, vec2 I) {
          //Resolution for scaling
    vec3 r = iResolution,
          //Ray direction
    d = vec3(I + I, 0) - r.xyy,
          //Starting position (approx. vec3(0,0,3))
    p = 3. / r,
          //Rotation vector
    q;

          //Divide ray by length and iterate.
    d /= r.y;
    for(int i = 0; i < 200; i++) {
              //Rotate sample point
        q = p, q.xz *= mat2(cos(iTime * .2 + vec4(0, 11, 33, 0)));
              //March forward using warped sphere SDF (stalk and cap respectively)
        p += d * min(L(vec3(.9 + .2 * q.y / (q.y + 2.), q.xz)), L(vec3(q.y - 2.5 + L(q) + q.x * q.y * .1, q.xz * .5))) - d;
    }

          //Output color based on distance, with spots and back glow.
    O = vec4(1, 3, 7, 0) * max((3. - L(p)) / clamp(L(mod(q, .3) / .1 - .9), .7, 1.) * .2 * mouse.x, .05 * mouse.x / dot(d, d)); // ändrom3da tweak
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
    gl_FragColor.a = 1.;
}