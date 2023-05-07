       /*
       * Original shader from: https://www.shadertoy.com/view/DsVSRy
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
      #define t iTime
      #define SAMPLES 10
      #define FOCAL_DISTANCE 4.0
      #define FOCAL_RANGE 6.0
mat2 m(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float map(vec3 p) {
    p.xz *= m(t * 0.4);
    p.xy *= m(t * 0.3);
    vec3 q = p * 2.0 + t;
    return length(p + vec3(sin(t * 0.7))) * log(length(p) + 1.0) + sin(q.x + sin(q.z + sin(q.y))) * 0.5 - 1.0;
}

vec3 hslToRgb(vec3 hsl) {
    vec3 rgb = clamp(abs(mod(hsl.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return hsl.z + hsl.y * (rgb - 0.5) * (1.0 - abs(2.0 * hsl.z - 1.0));
}

vec3 getColor(in vec2 fragCoord, in float depth) {
    vec2 p = fragCoord.xy / iResolution.y - vec2(.9, .5);
    vec3 cl = vec3(0.);
    float d = depth;

    for(int i = 0; i <= 5; i++) {
        vec3 p = vec3(0, 0, 5.0) + normalize(vec3(p, -1.0)) * d;
        float rz = map(p);
        float f = clamp((rz - map(p + .1)) * 0.5, -0.1, 1.0);

        float hue = mod(t * 1.0 + float(i) / 5.0, 1.0);
        vec3 color = hslToRgb(vec3(hue, 1.0, 0.5));

        vec3 l = color + vec3(5.0, 2.5, 3.0) * f;
        cl = cl * l + smoothstep(2.5, 0.0, rz) * 0.7 * l;

        d += min(rz, 1.0);
    }

    return cl;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.0);
    float depthSum = 0.0;
    float focalFactor = 0.0;

    for(int i = 0; i < SAMPLES; i++) {
        float depth = FOCAL_DISTANCE + (float(i) / float(SAMPLES - 1)) * FOCAL_RANGE;
        vec3 sampleColor = getColor(fragCoord, depth);
        float weight = 2.0 / (1.0 + abs(depth - FOCAL_DISTANCE));

        color += sampleColor * weight;
        depthSum += weight;
    }

    color /= depthSum;

    fragColor = vec4(color, 1.0);
}

      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}