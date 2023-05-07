      /*        old raymarched 3d starfield version of mine with somewhat dirty code
       *                  --=> move mouse x for rotation
       */

precision highp float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
      #define time time*1.
uniform sampler2D bb;

      #define FOG_STRENGTH   2.5  // original 2.22
      #define SPEED          1.0
      #define STAR_DENSITY   1.00
      //#define TAIL .00005

const float PI = 3.14159265;
const float angle = 60.0;
const float fov = angle * 0.5 * PI / 180.0;

float sphere(vec3 p, float r) {
    return length(p) - r;
}

vec3 ti = vec3(0.0);

      #define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

vec2 m = mouse;

float sphereSize = 1.0;
const vec3 lightDir = vec3(-0.577, 0.577, 0.577);

float N31(vec3 p) {
    vec3 a = fract(p / 118899.99 * vec3(1883.34, 8889.34, 37949.65));
    a += dot(a, a + 0.9);
    return fract((a.x * a.y * 207.0214, a.y * a.z, a.z * a.x));
}

vec3 trans(vec3 p) {
    float r = 3.0;
    ti = floor((p + 6.0 * 0.5) / 6.0);  // tile index global variable
      	//return mod(p, 6.0) - 3.0;
    return mod(p + r, 2.0 * r) - r;
}

float opSub(float d1, float d2) {
    return max(-d1, d2);
}

float distanceFunc(vec3 p) {
    float t = 55.;  // alternativ: 8.*time;
    float size = 1.0;  // from 1.5 to 4.
    float rn = N31(ti);

    p = trans(p);
    float d = 1.5;
    if(mod(rn, 0.99) < STAR_DENSITY / 300.) {
        return sphere(p, (size * sphereSize - 0.4 * (sin(3. * t + 40000. * rn) * 0.5 + 0.5)));
    } else {
        return opSub(sphere(p, 3.), d);
    }
}

void main(void) {
    m *= rot(-time);
      	//vec3  cPos = vec3(2.0 + mouse.x*400.+tw1()*90., 3.0+ mouse.y*30., 4.0 - 100.*(0.08*time)*10.*SPEED);   // movement
    vec3 cPos = vec3(100.0, 200.0, 1.0 * SPEED * time * 90.);   // movement
      	//cPos.xz *= rot(mouse.x*9.);
      	// fragment position
    vec2 p = 1.2 * (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec2 p0 = gl_FragCoord.xy / resolution.xy;

              //p *= rot(ROTATE*-0.00015*time* (sin(0.1*time)*0.5+0.5));
      	//p *= rot(mouse.x*4.);
      	// ray
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));

    ray.xz *= rot(mouse.x * 7.);
      	// ray.yz *= rot(mouse.y*7.);

      	// marching loop
    float distance = 0.0;
    float rLen = 0.0;

    vec3 rPos = cPos;

    for(int i = 0; i < 150; i++) {
        distance = distanceFunc(rPos);
        rLen += distance;
        rPos = cPos + ray * rLen;
    }

      	// the fog
    float fog = 1.0 - pow(66. / rLen, FOG_STRENGTH);
    vec3 c = vec3(0.0);

      	// hitting

      		//vec3 normal = getNormal(rPos);
      		//float diff = clamp(dot(lightDir, normal), 0.1, 1.0);
      		//c = vec3(1.0);
      	        //c = vec3(0.25*diff+0.75*(normal*0.5+0.5));  // normal values for coloring

    if(rLen > 180.0)
        c = vec3(0.0);

    c = vec3(1.0 - 1.05 * fog);
    c *= 1.0;
      	//c += 0.6*c + ((0.5*TAIL)+0.5)*texture2D(bb, p0).xyz;
      	//c += floor(p.y - fract(dot(gl_FragCoord.xy, vec2(0.5, 0.75))) * 10.0) * 0.05;  // dithering effect
      	//c = 0.2*c + 0.8*texture2D(bb, p0).xyz;
      	//if (c.x < 0.99) c *= c.x*vec3(0.75, 0.75, 0.75);
    gl_FragColor = vec4(c, 1.0);
}//ä