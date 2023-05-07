      /*
       * Original shader from: https://www.shadertoy.com/view/ssBBDW
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
      // Hash without Sine
      // MIT License...
      /* Copyright (c)2014 David Hoskins.

      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:

      The above copyright notice and this permission notice shall be included in all
      copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
      SOFTWARE.*/

      //----------------------------------------------------------------------------------------
      //  1 out, 1 in...
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

      //----------------------------------------------------------------------------------------
      //  1 out, 2 in...
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

      //----------------------------------------------------------------------------------------
      //  1 out, 3 in...
float hash13(vec3 p3) {
    p3 = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

      //----------------------------------------------------------------------------------------
      //  2 out, 1 in...
vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);

}

      //----------------------------------------------------------------------------------------
      ///  2 out, 2 in...
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);

}

      //----------------------------------------------------------------------------------------
      ///  2 out, 3 in...
vec2 hash23(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

      //----------------------------------------------------------------------------------------
      //  3 out, 1 in...
vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

      //----------------------------------------------------------------------------------------
      ///  3 out, 2 in...
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

      //----------------------------------------------------------------------------------------
      ///  3 out, 3 in...
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);

}

      //----------------------------------------------------------------------------------------
      // 4 out, 1 in...
vec4 hash41(float p) {
    vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);

}

      //----------------------------------------------------------------------------------------
      // 4 out, 2 in...
vec4 hash42(vec2 p) {
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);

}

      //----------------------------------------------------------------------------------------
      // 4 out, 3 in...
vec4 hash43(vec3 p) {
    vec4 p4 = fract(vec4(p.xyzx) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

      //----------------------------------------------------------------------------------------
      // 4 out, 4 in...
vec4 hash44(vec4 p4) {
    p4 = fract(p4 * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

      // The sdf and cloud rendering was inspired of another shader on the site, but i lost it!

vec3 getRd(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 dir = normalize(lookAt - ro);
    vec3 right = normalize(cross(dir, vec3(0, 1, 0)));
    vec3 up = normalize(cross(dir, right));
    return normalize(dir + right * uv.x + up * uv.y);
}

      #define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

vec3 map(vec3 p) {
    vec3 d = vec3(0);

    p *= 2.;
    vec3 op = p;
    float att = 1.;
    for(float i = 0.; i < 3.; i++) {

        p = abs(p);
        p *= 1.5;

        p -= 0.4;
        p /= clamp(dot(p, p), -0.5, 2.4);

        p += sin(dot(p, cos(p * 1. + i + iTime))) * att * 0.4;
        p.yz *= rot(1.6 + i * 0.);
        p.xy *= rot(1.6);

        d += exp(-abs(dot(op, p)) * 40.) * att * 2.;
              //d += abs(dot(sin(p*1.),cos(p*1.5 + 15.)))*att;
        att *= 0.7;
    }
          //d = clamp(d,0.,1.);
          //d = max(d,0.);
    d *= 1.4;
    if(false) {
        d = d / (d + 1.);
        d = pow(d, vec3(4.4)) * 25.;
    }//d = 1.-abs(d);
          //d = abs(d);
          //d = clamp(d,0.,1.);
          //d = max(d,0.);
          //d = mix(vec3(1,0.5,1)*0.1,vec3(1,1.5,1),d*5.);

          //d = mix(vec3(1.4,0.1,0.4),vec3(0,0.4,0.2),d*0.5)*d;
    d = (0.5 + 0.5 * sin(vec3(1, 2, 5) * 1. - cos(d * 29.) * 0. + 4. + d.x * 0.4)) * d * 1.;
          //d = exp(d*1000.);
          //d = pow(d,vec3(5.));
    return d;
}

vec3 getMarch(vec3 ro, vec3 rd, vec2 uv) {

    vec3 col = vec3(0);

    const float iters = 400.;
    float maxD = 5.;
    vec3 accum = vec3(0);
          //float stepSz = 1./iters*maxD*mix(0.99,1.,hash23(vec3(uv*2000.,110.)).x);

    ro -= rd * hash23(vec3(uv * 2000., 510. + iTime * 0.)).x * 1. / iters * maxD;
    vec3 p = ro;

    float t = 0.;
    float stepSz = 1. / iters * maxD;
    for(float i = 0.; i < iters; i++) {
        vec3 d = map(p);

        accum += d * stepSz * (1. - dot(accum, accum));
        stepSz = 1. / iters * maxD * mix(1., 0.5, exp(-dot(d, d) * 44.));

        if(dot(accum, accum) > 0.9 || t > maxD)
            break;
        t += stepSz;
        p += rd * stepSz;
    }

          //col += accum;
    col = mix(col, accum, dot(accum, accum) * 15.);
          //col = mix(col,accum,pow(dot(accum,accum)*4.,1.)*144.);

    col = col / (2. + col * 0.7) * 1.4;
    col = pow(col, vec3(0.4545));
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec3 col = vec3(0);

    vec3 ro = vec3(0, 0, -2);
    ro.xz *= rot((iTime + sin(iTime * 1.4)) * 0.2);
    ro.xy *= rot((iTime * 0.8 + sin(iTime * 1.7) * 0.6) * 0.1);

    vec3 lookAt = vec3(0);
    vec3 rd = getRd(ro, lookAt, uv);

    col = getMarch(ro, rd, uv);
          //vec3 rd = normalize(vec3(uv,1));

    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}