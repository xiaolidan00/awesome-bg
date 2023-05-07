      /*
       * Original shader from: https://www.shadertoy.com/view/ft2cDy
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
      #define iResolution resolution
vec4 iMouse = vec4(0.);

      // Emulate a black texture
      #define texture(s, uv) vec4(0.0)

      // --------[ Original ShaderToy begins here ]---------- //
      // based on https://www.shadertoy.com/view/4dXGR4 by
      // flight404 and trisomie21 (THANKS!)
      #define GLOW_INTENSITY -.1
      #define NOISE 0.
      #define MOUSE_SENSIBILITY .5

      #define iterations 22
         #define formuparam .55

         #define volstepsBack 20
         #define volstepsFront 2
         #define stepsize 0.11

         #define zoom   0.800
         #define tile   0.850
         #define speed  0.0005

         #define brightnessStar 0.0015
         #define darkmatter 0.300
         #define distfading 0.730
         #define saturation 0.750

float snoise(vec3 uv, float res)	// by trisomie21
{
    const vec3 s = vec3(1e0, 1e2, 1e4);
    uv *= res;
    vec3 uv0 = floor(mod(uv, res)) * s;
    vec3 uv1 = floor(mod(uv + vec3(1.), res)) * s;
    vec3 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    vec4 v = vec4(uv0.x + uv0.y + uv0.z, uv1.x + uv0.y + uv0.z, uv0.x + uv1.y + uv0.z, uv1.x + uv1.y + uv0.z);
    vec4 r = fract(sin(v * 1e-3) * 1e5);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    r = fract(sin((v + uv1.z - uv0.z) * 1e-3) * 1e5);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    return mix(r0, r1, f.z) * 2. - 1.;
}

float freqs[4];

vec3 GetRayDir(vec2 uv, vec3 ro) {
    vec3 f = normalize(vec3(0) - ro), r = normalize(cross(vec3(0, 1, 0), f)), u = cross(f, r), c = ro + f, i = c + uv.x * r + uv.y * u, rd = normalize(i - ro);
    return rd;
}

      //Star Nest by Pablo Roman Andrioli
      //https://www.shadertoy.com/view/XlfGRj
vec3 StarNest(vec3 dir, float s, float fade, vec3 v, vec3 from, float mask) {
         //volumetric rendering
    dir *= zoom + .5;
    from *= .05;
    float time = iTime * speed + .25;
    from += vec3(time * 2., time, -2.);
    for(int r = 0; r < volstepsBack; r++) {
        vec3 p = from + s * dir * .5;
        p = abs(vec3(tile) - mod(p, vec3(tile * 2.))); // tiling fold
        float pa, a = pa = 0.;
        for(int i = 0; i < iterations; i++) {
            p = abs(p) / dot(p, p) - formuparam; // the magic formula
            a += abs(length(p) - pa); // absolute sum of average change
            pa = length(p) * (1. - mask);
        }
        float dm = max(0., darkmatter - a * a * .001); //dark matter
        a *= a * a; // add contrast
        if(r > 6)
            fade *= 1. - dm; // dark matter, don't render near
        v += fade;
        v += vec3(s, s * s, s * s * s * s) * a * brightnessStar * fade * (1. - mask); // coloring based on distance
        fade *= distfading; // distance fading
        s += stepsize;

    }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float mouseX = (iMouse.x * .005 * MOUSE_SENSIBILITY);
    float mouseY = (iMouse.y * .005 * MOUSE_SENSIBILITY);
    freqs[0] = texture(iChannel1, vec2(0.01, 0.25)).x;
    freqs[1] = texture(iChannel1, vec2(0.07, 0.25)).x;
    freqs[2] = texture(iChannel1, vec2(0.15, 0.25)).x;
    freqs[3] = texture(iChannel1, vec2(0.30, 0.25)).x;

    float brightness = freqs[1] * 0.25 + freqs[2] * 0.25;
    float radius = 0.24 + brightness * 0.2;
    float invRadius = 1.0 / radius;

    vec3 orange = vec3(0.8, 0.65, 0.3);
    vec3 orangeRed = vec3(0.8, 0.35, 0.1);
    float time = iTime * 0.1;
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 p = -0.5 + uv;
    p.x *= aspect;

    float fade = pow(length(2.05 * p), 0.5);
    float fVal1 = 1.0 - fade;
    float fVal2 = 1.0 - fade;

    float angle = atan(p.x * clamp((cos(mouseX) + .5), .5, 1.), p.y * (sin(mouseY) + .5)) / 6.2832;
    float dist = length(p);
    vec3 coord = vec3(angle, dist, time * 0.1);

    float newTime1 = abs(snoise(coord + vec3(0.0, -time * (0.35 + brightness * 0.001), time * 0.015), 15.0));
    float newTime2 = abs(snoise(coord + vec3(0.0, -time * (0.15 + brightness * 0.001), time * 0.015), 45.0));

    float power = pow(2.0, 3. - clamp(NOISE, 0., 3.));
    fVal1 += (0.5 / power) * snoise(coord + vec3(0.0, -time, time * 0.2), (power * (10.0) * (newTime1 + 1.0)));
    fVal2 += (0.5 / power) * snoise(coord + vec3(0.0, -time, time * 0.2), (power * (25.0) * (newTime2 + 1.0)));

    float corona = pow(fVal1 * max(1.2 - fade, 0.0), 2.) * 50.;
    corona += pow(fVal2 * max(1.3 - fade, 0.0), 2.) * 50.;
    corona *= 1.2 - newTime1;

    vec2 sp = -1.0 + 2.0 * uv;
    sp.x *= aspect;
    sp *= (2.0 - brightness);
    float r = dot(sp, sp);
    float f = (1.0 - sqrt(abs(1.0 - r))) / (r) + brightness * 0.5;

    if(dist < radius) {
        corona *= pow(dist * invRadius, 24.0);
        vec2 newUv = vec2((snoise(vec3(uv * 8., uv.y), 5.) * 2.)) * .005;
        newUv.x += sp.x * f - (iTime * .05) - mouseX;
        newUv.y += sp.y * f - mouseY;

        vec3 texSample = texture(iChannel0, newUv).rgb;
        float uOff = (texSample.g * brightness * 4.5);
        vec2 starUV = newUv + vec2(uOff, 0.0);
        vec3 starSphere = texture(iChannel0, starUV).rgb;
        fragColor.rgb += max(starSphere, .6) * fVal1 * .5;
        fragColor.rgb += starSphere;
    }

    vec3 ro = vec3(-mouseX, -mouseY, -5.4);
    vec3 rd = GetRayDir(uv, ro);

    float diam = 1.;
    float dia = clamp(1.0 - length(vec2(p * diam)), 0., 1.);

    vec3 v = StarNest(rd, .1, 1., fragColor.rgb, ro, 0.);
    v = mix(vec3(length(v) * .1), v, saturation); //color adjust
    v *= mix(vec3(0.8), vec3(1., 1., 0.) + 2.5, dia);
    fragColor.rgb += vec3(v * .01) * (1. - dia);

    float starGlow = min(max(1.0 - dist * (clamp((1. - GLOW_INTENSITY), -1., 1.5) - brightness), 0.0), 1.);
    fragColor.rgb += vec3(f * (0.75 + brightness * 0.3) * orange) + corona * orange + starGlow * orangeRed;
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    iMouse = vec4(mouse * resolution, 0., 0.);
    mainImage(gl_FragColor, gl_FragCoord.xy);
    gl_FragColor.a = 1.;
}