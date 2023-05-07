      /*
       * Original shader from: https://www.shadertoy.com/view/fd2yRw
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
      #define resolution iResolution
      #define time iTime

float speed;

vec3 spherePos1;
vec3 spherePos2;

vec3 lightCol1 = vec3(0.8, 0.5, 0.2);
vec3 lightCol2 = vec3(0.2, 0.2, 0.8);

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

vec3 cam(float t) {
    return vec3(sin(t * .3) * 1., cos(t * .5 + 1.5), t);
}

float sdCross(vec3 p, float c) {
    p = abs(p);
    vec3 d = max(p.xyz, p.yzx);
    return min(min(d.x, d.y), d.z) - c;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdMenger(vec3 p, float size, float width) {
    float s = 1.;
    float d = 0.;
    for(int i = 0; i < 4; i++) {
        vec3 q = mod(p * s, 2.) - 1.;
        s *= size;
        q = 1. - size * abs(q);
        float c = sdCross(q, width) / s;
        d = max(d, c);
    }
    return d;
}

float map(vec3 p) {
    float d1 = sdMenger(p, 3.8, .7);

    float d2 = length(p.xy - cam(p.z).xy) - .2;

    return max(d1, -d2);
}

vec4 spheres(vec3 p) {
    spherePos1 = cam(time + 1.) + vec3(cos(time * 1.3) * .6, sin(time) * .6, exp(sin(time)) * .5);
      	//spherePos2 = cam(time + sin(time) * .3 + 1.) + vec3(cos(time * .6 + 1.6) * .5, sin(time *  1.2 + .6) * .5, exp(sin(time + 1.6)) * .5);
    float d3 = sdSphere(p - spherePos1, .0);
      	//float d4 = sdSphere(p - spherePos2, .0);
      	//lightCol1 = pal( time * .01, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );
    vec3 col = 3. * (exp(-d3 * 3.) * lightCol1);// + exp(-d4 * 3.) * lightCol2);

    return vec4(col, d3);// min(d3,d4));
}

vec3 genNormal(vec3 p) {
    vec2 d = vec2(0.001, 0.);
    return normalize(vec3(map(p + d.xyy) - map(p - d.xyy), map(p + d.yxy) - map(p - d.yxy), map(p + d.yyx) - map(p - d.yyx)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    vec2 p = (gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y);

    vec3 color = vec3(0.0);
      	//color.xy = p;

    speed = time;

    vec3 cPos = vec3(0., 0., -4. + speed);
    cPos = cam(time);
    vec3 t = vec3(0., 0., 0. + speed);
    t = cam(time + .5);
    vec3 fwd = normalize(t - cPos);
    vec3 side = normalize(cross(vec3(sin(time * .6) * .6, 1., cos(time * .3 + 1.6) * .4), fwd));
    vec3 up = normalize(cross(fwd, side));
    vec3 rd = normalize(p.x * side + p.y * up + fwd * (1. + .3 * (1. - dot(p, p))));

    float d = 0., dd;
    vec3 ac;
    int k;

    for(int i = 0; i < 100; i++) {
        vec4 s = spheres(cPos + d * rd);
        dd = map(cPos + d * rd);
        if(dd < 0.001) {
      			//color += 1.;
            break;
        }
        ac += s.xyz;
        dd = min(dd, s.w);
        k = i;
        d += dd;
    }

    vec3 ip = cPos + d * rd;

    if(dd < 0.001) {
        vec3 normal = genNormal(ip);

        float ao = 1. - (float(k) + dd / 0.001) / 100.;

        float diff1 = clamp(dot(normalize(spherePos1 - ip), normal), 0., 1.) / pow(length(spherePos1 - ip), 3.);
      		//float diff2 = clamp(dot(normalize(spherePos2 - ip), normal), 0., 1.) / pow(length(spherePos2 - ip), 3.);

        color += diff1 * lightCol1;
      		//color += diff2 * lightCol2;

        color *= ao;
    }

    color += ac * .03;

    p = gl_FragCoord.xy / resolution.xy;
    color = sqrt(color);
    color *= pow(p.x * p.y * (1. - p.x) * (1. - p.y) * 16., .5);

    fragColor = vec4(color, 1.0);

}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}