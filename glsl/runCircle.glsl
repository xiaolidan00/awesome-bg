      /*
       * Original shader from: https://www.shadertoy.com/view/fdSBDD
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
      #define PI 3.14159265

float circle(vec2 uv, float blur) {
    return smoothstep(0., blur, 1. - length(uv));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    float circleWhite = circle(uv * 2.45, 1.);
    float circleBlack = circle(uv * 2.86, 0.7);
    float c = circleWhite - circleBlack;
    c *= 6.;

    float t = iTime * 5.;
    c -= circle(vec2(uv.x - sin(t) * .85, 1.8 * uv.y - cos(t) * .65) * .8, 1.);

    vec3 col = vec3(c) * vec3(1., 0., 0.5);
    col += vec3(smoothstep(0.2, 0.7, c)) * vec3(1., 1., 0.);
    col += vec3(smoothstep(0.4, 0.55, c));

    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}