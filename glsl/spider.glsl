      /*
       * Original shader from: https://www.shadertoy.com/view/sdjczG
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
      //Why We Walk in Circles by eiffie (X marks the spot)

      //https://www.sciencefocus.com/news/humans-may-have-an-ancient-ability-to-sense-magnetic-fields/

      //Blindfolded we walk in circles as tight as 20 meters. What removed that ability?.

      //Characteristics for the Occurence of a High-Current Z-Pinch Aurora
      //as Recorded in Antiquity, Anthony L Peratt

      //The Z-Machine at Sandia Labs produces 2 billion degrees using a z-pinch.
      //It takes 3 billion to fuse silica into iron, more than a hundred times
      //hotter than the center of the sun.

      //In the Nazca desert lines are produced by scraping away a layer of reddish
      //iron rich soil to reveal the light sand below. Don't say they didn't warn you.

      #define tim iTime*.3
      #define rez iResolution.xy
      // Based on a simple 2d noise algorithm contributed by Trisomie21 (Thanks!)
float noyz(vec2 v) {
    vec4 h = fract(sin(vec4(floor(v.x) + floor(v.y) * 1000.) + vec4(0, 1, 1000, 1001)) * 1000.);
    v = smoothstep(0., 1., fract(v));
    return mix(mix(h.x, h.y, v.x), mix(h.z, h.w, v.x), v.y);
}
float bumpz(vec2 p, float d) {
    return (noyz(p) + noyz(vec2(p.x + p.y, p.x - p.y))) * d;
}
      //smin from iq
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return b + h * (a - b - k + k * h);
}
float tube(vec2 pa, vec2 ba) {
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}
float DE(vec2 p) {
    p *= 1. + p.x * 0.02;
    p.x *= .8;
    float r = length(p) - .57;
    vec2 k = p;
    k.x = abs(k.x) - .77;
    float r2 = length(k) - .28;
    k = p;
    k.x = abs(k.x) - 2.;
    float r3 = length(k) - 1. + p.x * .05;
    if(p.x > 0.)
        r3 = max(r3, -(length(p - vec2(2.5, 0.)) - .57));
    k = abs(p) - vec2(0., .29);
    k.y -= k.x * k.x * 0.09;
    float t = tube(k, vec2(.9, 1.6)) - .12;
    t = min(t, tube(k - vec2(.9, 1.6), vec2(2.5, .21)) - .12);
    t = min(t, tube(p - vec2(1.9, 0.), vec2(.6, 0.)) - .12);
    float t2 = tube(k - vec2(.6, .07), vec2(.6, 1.)) - .12;
    t2 = min(t2, tube(k - vec2(.6, .07) - vec2(.6, 1.), vec2(2.2, .18)) - .12);
    r = smin(min(r, min(r3, t2)), min(r2, t), .36);
    float d = min(abs(r), abs(p.x + p.y + 7.));
    return d;
}
vec2 rotate(vec2 v, float angle) {
    return cos(angle) * v + sin(angle) * vec2(v.y, -v.x);
}
void mainImage(out vec4 O, in vec2 U) {
    vec2 uv = (2.0 * U - rez) / rez;
    uv.xy *= (1.75 + .5 * sin(tim) + uv.y * .4);
    uv += vec2(sin(tim * .7), sin(tim * .5)) * .2;
    uv = rotate(uv, (tim + sin(tim)) * 1.3);
    float d = DE(uv * 5.);
    d = .75 - .4 * pow(bumpz(uv * (30. + 3. * sin(uv.yx * 2.)), d), .25);
    O = vec4(mix(vec3(1., .7, .4) * d, vec3(1), clamp(d * d * d, 0., 1.)), 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}