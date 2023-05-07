      /*{
        "CREDIT": "by mojovideotech",
        "CATEGORIES": [
          "space"
        ],
        "INPUTS": [
          {
      			"NAME": "mouse",
      			"TYPE": "point2D",
      			"DEFAULT":	[ 0, 0 ],
      			"MAX" : 	[ 1.0, 1.0 ],
            		"MIN" : 	[ -1.0, -1.0 ]
      	}
        ],
        "DESCRIPTION": ""
      }*/

      ///////////////////////////////////////////
      // BlackCherryCosmos  by mojovideotech
      //
      // based on:
      // glslsandbox.com/\e#28545.0
      //
      // Creative Commons Attribution-NonCommercial-ShareAlike 3.0
      ///////////////////////////////////////////

      #ifdef GL_ES
precision mediump float;
      #endif

      #define iterations 4
      #define formuparam2 0.89
      #define volsteps 4
      #define stepsize 0.390
      #define zoom 6.900
      #define tile   0.850
      #define brightness 0.15
      #define darkmatter 0.600
      #define distfading 0.560
      #define saturation 0.900
      #define transverseSpeed zoom*2.0
      #define cloud 0.067

uniform float time;
float TIME = time;

uniform vec2 resolution;
vec2 RENDERSIZE = resolution;

uniform vec2 mouse;

float triangle(float x, float a) {
    return (2.0 * abs(2.0 * ((x / a) - floor((x / a) + 0.5))) - 1.0);
}

float field(in vec3 p) {
    float accum = 0.0, prev = 0.0, tw = 0.0;
    float strength = 7.0 + 0.03 * log(1.e-6 + fract(sin(TIME) * 4373.11));
    for(int i = 0; i < 6; ++i) {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-0.5, -0.8 + 0.1 * sin(TIME * 0.2 + 2.0), -1.1 + 0.3 * cos(TIME * 0.15));
        float w = exp(-float(i) / 7.0);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.3));
        tw += w;
        prev = mag;
    }
    return max(0.0, 5.0 * accum / tw - 0.7);
}

void main() {
    vec2 uv2 = 2.0 * gl_FragCoord.xy / RENDERSIZE.xy - 1.0;
    vec2 uvs = uv2 * RENDERSIZE.xy / max(RENDERSIZE.x, RENDERSIZE.y);
    float time2 = TIME;
    float speed = 0.005 * cos(time2 * 0.02 + 3.1415926 / 4.0);
    float formuparam = formuparam2;
    vec2 uv = uvs;
    float a_xz = 0.9, a_yz = -0.6, a_xy = 0.9 + TIME * 0.04;
    mat2 rot_xz = mat2(cos(a_xz), sin(a_xz), -sin(a_xz), cos(a_xz));
    mat2 rot_yz = mat2(cos(a_yz), sin(a_yz), -sin(a_yz), cos(a_yz));
    mat2 rot_xy = mat2(cos(a_xy), sin(a_xy), -sin(a_xy), cos(a_xy));
    float v2 = 1.0;
    vec3 dir = vec3(uv * zoom, 1.0);
    vec3 from = vec3(0.0, 0.0, 0.0);
    from.x -= 5.0 * (mouse.x - 0.5);
    from.y -= 5.0 * (mouse.y - 0.5);
    vec3 forward = vec3(0.0, 0.0, 1.0);
    from.x += transverseSpeed * (1.0) * cos(0.01 * TIME) + 0.001 * TIME;
    from.y += transverseSpeed * (1.0) * sin(0.01 * TIME) + 0.001 * TIME;
    from.z += 0.003 * TIME;
    dir.xy *= rot_xy;
    forward.xy *= rot_xy;
    dir.xz *= rot_xz;
    forward.xz *= rot_xz;
    dir.yz *= rot_yz;
    forward.yz *= rot_yz;
    from.xy *= -rot_xy;
    from.xz *= rot_xz;
    from.yz *= rot_yz;
    float zooom = (time2 - 3311.0) * speed;
    from += forward * zooom;
    float sampleShift = mod(zooom, stepsize);
    float zoffset = -sampleShift;
    sampleShift /= stepsize;
    float s = 0.24, t3 = 0.0, s3 = s + stepsize / 2.0;
    vec3 v = vec3(0.0), backCol2 = vec3(0.0);
    for(int r = 0; r < volsteps; r++) {
        vec3 p2 = from + (s + zoffset) * dir;
        vec3 p3 = (from + (s3 + zoffset) * dir) * (1.9 / zoom);
        p2 = abs(vec3(tile) - mod(p2, vec3(tile * 2.)));
        p3 = abs(vec3(tile) - mod(p3, vec3(tile * 2.)));
        t3 = field(p3);
        float pa, a = pa = 0.;
        for(int i = 0; i < iterations; i++) {
            p2 = abs(p2) / dot(p2, p2) - formuparam;
            float D = abs(length(p2) - pa);
            if(i > 2) {
                a += i > 7 ? min(12., D) : D;
            }
            pa = length(p2);
        }
        a *= a * a;
        float s1 = s + zoffset;
        float fade = pow(distfading, max(0., float(r) - sampleShift));
        v += fade;
        if(r == 0)
            fade *= (1. - (sampleShift));
        if(r == volsteps - 1)
            fade *= sampleShift;
        v += vec3(s1, s1 * s1, s1 * s1 * s1 * s1) * a * brightness * fade;
        backCol2 += mix(.4, 1., v2) * vec3(1.8 * t3 * t3 * t3, 1.4 * t3 * t3, t3) * fade;
        s += stepsize;
        s3 += stepsize;
    }
    v = mix(vec3(length(v)), v, saturation);
    vec4 forCol2 = vec4(v * .01, 1.);
    backCol2 *= cloud;
    backCol2.b *= 1.8;
    backCol2.r *= 0.55;
    backCol2.b = 0.5 * mix(backCol2.g, backCol2.b, 0.8);
    backCol2.g = -0.5;
    backCol2.bg = mix(backCol2.gb, backCol2.bg, 0.5 * (cos(TIME * 0.01) + 1.0));

    gl_FragColor = forCol2 + vec4(backCol2, 1.0);
}