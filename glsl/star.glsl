     // circle				--=> "keep quiet" (-poonjaji)
      #define centralSun      1
      #define glow		( 1./160. )
      #define move		1
      #define col             vec3( 1., 1.5, 6. )
      #define rotationSpeed	( 1./3. )

      // gfx options
      #define AA		1.

      // code
      #define tau 6.28318530718
      #define POS gl_FragCoord
      #define OUT gl_FragColor
      #define res resolution
      #define rot( a ) mat2( cos( a*tau ), -sin( a*tau ), sin( a*tau ), cos( a*tau ) )
      #define flip( x ) ( 1. - ( x ) )
precision highp float;
uniform float time;
uniform vec2 mouse, res;
uniform sampler2D bb;
vec2 p, p0, m = mouse * res;
vec3 c, c0;
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1., 2. / 3., 1. / 3., 3.);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0., 1.), c.y);
}
float rectangle(vec2 p, vec4 rect) {
    vec2 hv = step(rect.xy, p) * step(p, rect.zw);
    return hv.x * hv.y;
}
float sdTetrahedron(vec3 p) {
    return (max(abs(p.x + p.y) - p.z, abs(p.x - p.y) + p.z) - 1.) / (1.7320508075);
}  // 1.73205.. = sqrt( 3. )are ue8f 57

void colorBar(float size) {
    float bar = rectangle(flip(p0), vec4(0., 0., 1., size));
    vec3 colBar = hsv2rgb(vec3(floor(-12. * time + 16. * p0.x) / 16., 1., .9));
    c += bar * (colBar - c);
    c -= c * rectangle(flip(p0), vec4(0., size - .0025, 1., size));
}

float nSpheres(vec3 p, float r, float num)  // by ändrom3da
      	#define size ( 1./3. )
{
    float theta = atan(p.x, p.y) + tau / 2.;
    float nt = num / tau;
    float pn = (floor(theta * nt) + .5) / nt;
    vec3 circleCenter = vec3(-sin(pn), -cos(pn), 0.) * r;
    float circleRadius = r * sin(.5 / nt);
      	#define thetaaa 10. // fix
    return distance(p, circleCenter) - circleRadius * (sin(thetaaa + 1.) * .333 + .9) * 0.66;
}

float map(vec3 p) {
    vec3 trans = vec3(0);
    float numSuns = floor(abs(24.) + 3.);
      	#if ( move == 1 )
    p -= 9. * vec3(sin(time), 0., cos(time));
      	#endif
    p.yz *= rot(time * tau * rotationSpeed / 43.);
    p.xz *= rot(cos(3. * time * rotationSpeed / 15.));
    p.xy *= rot(time * tau * rotationSpeed / 4.);
    float d = nSpheres(p, 16., numSuns);
      	#if ( centralSun == 1 )
    float tetra1 = sdTetrahedron(p / 1.5);
    p.xy *= rot(.25);
    float tetra2 = sdTetrahedron(p / 1.5);
    float tetra = min(tetra1, tetra2);
    d = min(tetra, d);
      	#endif
    return d;
}

void mainImage(vec2 p) {
    vec3 camPos = vec3(0., 0., -21.5);
    vec3 rayDir = normalize(vec3(p, 1.));
    float depth = 0.;
    for(int i = 0; i < 26; i++) {
        vec3 rayPos = camPos + rayDir * depth;
        float dist = map(rayPos);
        c += vec3(glow) / (dist);
        if(dist < 0.01) {
            c = vec3(4.);
            break;
        }
        depth += dist;
    }
    c /= col / 2.; // twist
    c = 1. - exp(-c); // some tonemapping
    colorBar(6. / 320.);
}

void main() {
    p0 = POS.xy / res;
    for(float kk = 0.; kk < AA; kk++) for(float kkk = 0.; kkk < AA; kkk++) // nested AA loop
        {
            vec2 k = (vec2(kk, kkk) - .5) / vec2(AA);
            c = vec3(0.);
            if(kk + kkk == 0.) {
                m = (m.xy - k - res / 2.) / res.y;
            }
            p = (POS.xy - k - res / 2.) / res.y;
            mainImage(p);
            c0 += c;
        } // acc the color
    c0 /= AA * AA;
    OUT = vec4(c0, 1.);
} //ändrom3da