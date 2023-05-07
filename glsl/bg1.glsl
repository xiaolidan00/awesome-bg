       /*
       * Original shader from: https://www.shadertoy.com/view/fdtyzM
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
uniform float _cameraPositionIndex;

      #define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
      #define PI 3.14159265

struct DBuffer {
    float d1;
    float d2;
    float d3;
    float mainD;
};

struct AccBuffer {
    float acc1;
    float acc2;
    float acc3;
};

float rand(vec2 seeds) {
    return fract(sin(dot(seeds, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 random2(vec2 seeds) {
    seeds = vec2(dot(seeds, vec2(127.1, 311.7)), dot(seeds, vec2(269.5, 183.3)));
    return fract(sin(seeds) * 43758.5453123);
}

float perlinNoise(vec2 seeds) {
    vec2 i = floor(seeds);
    vec2 f = fract(seeds);
    vec2 i00 = i + vec2(0, 0);
    vec2 i10 = i + vec2(1, 0);
    vec2 i01 = i + vec2(0, 1);
    vec2 i11 = i + vec2(1, 1);
    vec2 f00 = f - vec2(0, 0);
    vec2 f10 = f - vec2(1, 0);
    vec2 f01 = f - vec2(0, 1);
    vec2 f11 = f - vec2(1, 1);
    vec2 g00 = normalize(-1.0 + 2.0 * random2(i00));
    vec2 g10 = normalize(-1.0 + 2.0 * random2(i10));
    vec2 g01 = normalize(-1.0 + 2.0 * random2(i01));
    vec2 g11 = normalize(-1.0 + 2.0 * random2(i11));
    float v00 = dot(g00, f00);
    float v10 = dot(g10, f10);
    float v01 = dot(g01, f01);
    float v11 = dot(g11, f11);
    vec2 p = smoothstep(0.0, 1.0, f);
    float v00v10 = mix(v00, v10, p.x);
    float v01v11 = mix(v01, v11, p.x);
    return mix(v00v10, v01v11, p.y) * 0.5 + 0.5;
}

vec2 fmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + PI / r;
    float n = (2. * PI) / r;
    a = floor(a / n) * n;
    return rot(a) * p;
}

float Plane(vec3 p) {
    return p.y;
}

float Cube(vec3 p, vec3 s) {
    return length(max(abs(p) - s, 0.));
}

float CubeTerrain(vec3 p, vec3 offset, float k, vec3 scale, float A, float startVal) {
    vec3 pos = p;
    pos += offset;
    float xid = floor(pos.x / k);
    float yid = floor(pos.y / k);
    float zid = floor(pos.z / k);

    pos.xz = mod(pos.xz, k) - 0.5 * k;
    float d = Cube(pos, scale + vec3(0., min(rand(vec2((xid + zid) * A)) * startVal + startVal, k) * exp(abs(xid) * 0.5) * 0.5, 0.));
    return d;
}

float d1(vec3 p) {
    p.z -= time * 2.;
    float d0 = CubeTerrain(p, vec3(0., 0., 0.), .8, vec3(0.25, 0.25, 0.25), 10.0, 0.25);
    float d1 = CubeTerrain(p, vec3(1., 0., 1.), .8, vec3(0.25, 0.25, 0.25), 20.0, 0.2);
    d0 = min(d0, d1);
    float d2 = CubeTerrain(p, vec3(-1., -.0, -1.), .8, vec3(0.2, 0.2, 0.2), 40.0, 0.2);
    d0 = min(d0, d2);
    float d3 = CubeTerrain(p, vec3(-.5, -.0, -.5), 1.2, vec3(0.2, 0.2, 0.2), 20.0, 0.5);
    d0 = min(d0, d3);

        /*float k=.75;
        p=mod(p,k)-k*.5;
        float d0=Cube(p,vec3(.25,.25,.25));*/

    return d0;
}

float d1_edge(vec3 p) {
    float d = d1(p);
    d = max(d, d1(p * 1.1));
    return d;
}

float particle(vec3 p, float k, vec3 offset) {
    vec3 pos0 = p;
    pos0 += offset;
    vec3 id = floor(pos0 / k);
    pos0.y += sin(pos0.z * 2. + time * sign(sin(time + pos0.z))) * 0.5;
    pos0.xy *= rot(pos0.z);
    pos0 = mod(pos0, k) - k * 0.5;
    float d = Cube(pos0, vec3(0.005, 0.005, 2.));

    return d;
}

float d2(vec3 p) {
    p.z -= time;
    float d = particle(p, 1.5, vec3(0.));
    float d1 = particle(p, 1., vec3(-1.));
    d = min(d, d1);
    float d2 = particle(p, 1., vec3(1., -1., 1.));
    d = min(d, d2);

    return d;
}

float d3(vec3 p) {
      //p*=7.;

    float d = length(p) - .2;
      //p.xyz*=7.;
      //p.x+=1.5;

    p.xy *= rot(time);
    p.xz *= rot(time);
    p.yz *= rot(time);
    for(int i = 0; i < 3; i++) {
        p = abs(p) - .075;
        if(p.x < p.y)
            p.xy = p.yx;
        if(p.x < p.z)
            p.xz = p.zx;
        if(p.y < p.z)
            p.yz = p.zy;

        p.xy *= rot(1.2);
        p.xz *= rot(.25);
        p.yz *= rot(.25);

    }

    d = min(d, Cube(p, vec3(.2, .2, .2) * .2));

    return d;
}

DBuffer map(vec3 p) {
    DBuffer d;
    d.d1 = d1_edge(p);
        //d.d2=d1(p*1.1);
        //d.d1=2000.0;
    d.d2 = d2(p);
        //d.d2=2000.0;
    d.d3 = d3(p + vec3(0., -1.5, 0.));
        //d.d3=2000.0;
    d.mainD = min(min(d.d1, d.d2), d.d3);
    return d;
}

vec3 gn(vec3 p) {
    vec2 e = vec2(0.001, 0.);
    return normalize(vec3(map(p + e.xyy).mainD - map(p - e.xyy).mainD, map(p + e.yxy).mainD - map(p - e.yxy).mainD, map(p + e.yyx).mainD - map(p - e.yyx).mainD));
}

vec3 hsv2rgb2(vec3 c, float k) {
    return smoothstep(0. + k, 1. - k, .5 + .5 * cos((vec3(c.x, c.x, c.x) + vec3(3., 2., 1.) / 3.) * radians(360.)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 st = (fragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
        //vec2 st=uv*2.0-1.0;
        //st.x*=(resolution.x/resolution.y);

    vec3 col = vec3((st.y + 1.0) * 0.5 * 0.25);
    float radius = 15.;
    float speed = -.25;
    vec3 ta = vec3(0., 1., 0.);
       //vec3 ro=vec3(0.,2.,2.);
    vec3 ro = vec3(cos(time), 1., sin(time));

    if(_cameraPositionIndex == 0.0) {
        ta = vec3(0., 1., 0.);
        ro = vec3(0., 2., 2.);
    } else if(_cameraPositionIndex == 1.0) {
        ta = vec3(0., 1., 0.);
        ro = vec3(cos(time), 1., sin(time));
    } else if(_cameraPositionIndex == 2.0) {
          //float radius=1.0*(perlinNoise(vec2(0.123,-time*5.0))+1.0)*.8;
        ta = vec3(0., 1., 0.);
          //ro=vec3(cos(-time)*radius,sin(-time)*radius*0.1+1.0,sin(time)*radius);
        ro = vec3(-1., 1.5, -2.0);
    }

    float adjustAcc = 0.5;

    vec3 cDir = normalize(ta - ro);
    vec3 cSide = cross(cDir, vec3(0., -1., 0.));
    vec3 cUp = cross(cDir, cSide);
    float depth = 1.;
    vec3 rd = normalize(vec3(st.x * cSide + st.y * cUp + cDir * depth));

    DBuffer d;
    AccBuffer acc;
    float t = 0.0, pi = 0.0;
    for(int i = 0; i < 100; i++) {
        d = map(ro + rd * t);
          //d.d3=min(d.d3*0.,.1);
        pi = float(i);
        if(abs(d.d1) < 0.001 || d.d2 < 0.001 || d.d3 < 0.001 || t > 1000.0)
            break;

          //if(d.mainD<2.){
          //  t+=d.mainD*.25;
          //}else{
        t += d.mainD * .5;
          //}

        acc.acc1 += exp(-50.0 * (d.d1));
        acc.acc2 += exp(-50.0 * d.d2);
        acc.acc3 += exp(-50.0 * d.d3);
    }

    if(d.d1 < 0.001) {
        vec3 refro = ro + rd * t;
        vec3 n = gn(refro);
        rd = reflect(rd, n);
        ro = refro;
        t = 0.1;
        float acc2;

        for(int i = 0; i < 11; i++) {
            d = map(ro + rd * t);
            if(d.mainD < 0.001)
                break;
            t += d.mainD;
            float H = mod(time * 0.5, 1.0);
            acc2 += exp(-3. * d.mainD);
        }

        vec3 pos = ro + rd * t;
        float flash = 1.0 - abs(sin(pos.z * .5 + time * 4.0));
        flash += .1;
        float H = mod(time * 0.5, 1.0);
        col += flash * adjustAcc * vec3(0., 0.25, 1.0) * 20. / pi;
    }

    if(d.d2 < 0.001) {
        col += vec3(exp(-.01 * t)) * vec3(0., 0.25, 1.0) * acc.acc2 * 0.05;
    }

    if(d.d3 < 0.001) {
        col += vec3(exp(-1. * t)) * acc.acc3 * 0.05 * vec3(0., 0.25, 1.0);
    }

    fragColor = vec4(col, 1.0);
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}