      /*
       * Original shader from: https://www.shadertoy.com/view/stlcW7
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
const vec4 iMouse = vec4(0.);

      // Emulate some GLSL ES 3.x
int int_mod(int a, int b) {
    return (a - (b * (a / b)));
}

int int_max(int a, int b) {
    return (a > b) ? a : b;
}

      // --------[ Original ShaderToy begins here ]---------- //
      #define DTR 0.0174532
      #define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec2 uv;
vec3 cp = vec3(0.), cn, cr = vec3(0.), ro = vec3(0.), rd = vec3(0.), ss, oc, cc, gl = vec3(0.), vb;
vec4 fc = vec4(0.);
float tt = 0., cd = 0., sd = 0., io = 0., oa = 0., td = 0.;
int es = 0, ec;

      //shapes:
float bx(vec3 p, vec3 s) {
    vec3 q = abs(p) - s;
    return min(max(q.x, max(q.y, q.z)), 0.) + length(max(q, 0.));
}

      //crystal - domain repetition with a rotated lattice
vec3 latticeA(vec3 p, int iter) {
    for(int i = 0; i < 5; i++) {
        p.xy *= rot(45. * DTR);
        p.xz *= rot(45. * DTR);
        p = abs(p) - 1.;

              //this reverse-rotation to bring the cubes back is actually "wrong",
              //swap these two lines for the "proper" symmetric lattice
        p.xy *= rot(-45. * DTR);
        p.xz *= rot(-45. * DTR);
    }
    return p;
}

      //scene
float mp(vec3 p) {
      //now with mouse control
    if(iMouse.z > 0.) {
        p.yz *= rot(2.0 * (iMouse.y / iResolution.y - 0.5));
        p.zx *= rot(-7.0 * (iMouse.x / iResolution.x - 0.5));
    }
    vec3 pp = p;
    p.xz *= rot(tt * 0.2);
    p = latticeA(p, 5);
    sd = bx(p, vec3(1.)) - 0.03;
    float osc = cos(tt * 2.) * 0.5 + 0.5;
    sd = mix(sd, length(pp) - 1., min(pow(sin(tt * 0.5) * 0.5 + 0.5, 3.) + osc * 0.1, 1.));
    sd = abs(sd) - 0.001;
    if(sd < 0.001) {
        oc = vec3(1., 0, 0.25);
        io = 1.2;
        oa = 0.8 - length(pp * 0.1);
        ss = vec3(0.);
        vb = vec3(0., 2.5, 2.5);
        ec = 2;
    }
    return sd;
}

      //raymarching and normals
void tr() {
    vb.x = 0.;
    cd = 0.;
    for(float i = 0.; i < 512.; i++) {
        mp(ro + rd * cd);
        cd += sd;
        td += sd;
        if(sd < 0.0001 || cd > 128.)
            break;
    }
}
void nm() {
    mat3 k = mat3(cp, cp, cp) - mat3(.001);
    cn = normalize(mp(cp) - vec3(mp(k[0]), mp(k[1]), mp(k[2])));
}

      //pixel colouring
void px() {
    cc = vec3(1., 0.45, 0.) + length(pow(abs(rd + vec3(0, 0.5, 0)), vec3(3))) * 0.3 + gl;
    if(cd > 128.) {
        oa = 1.;
        return;
    }
    vec3 l = vec3(0.4, 0.7, 0.8);
    float df = clamp(length(cn * l), 0., 1.);
    vec3 fr = pow(1. - df, 3.) * mix(cc, vec3(0.4), 0.5);
    float sp = (1. - length(cross(cr, cn * l))) * 0.2;
    float ao = min(mp(cp + cn * 0.3) - 0.3, 0.3) * 0.5;
    cc = mix((oc * (df + fr + ss) + fr + sp + ao + gl), oc, vb.x);
}

      //basic setup and transparency loop
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    tt = mod(iTime, 260.);
    uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    uv -= 0.5;
    uv /= vec2(iResolution.y / iResolution.x, 1);
    ro = vec3(0, 0, -15);
    rd = normalize(vec3(uv, 1));

    for(int i = 0; i < 20; i++) {
        tr();
        cp = ro + rd * cd;
        nm();
        ro = cp - cn * 0.01;
        cr = refract(rd, cn, int_mod(i, 2) == 0 ? 1. / io : io);
        if(length(cr) == 0. && es <= 0) {
            cr = reflect(rd, cn);
            es = ec;
        }
        if(int_mod(int_max(es, 0), 3) == 0 && cd < 128.)
            rd = cr;
        es--;
        if(vb.x > 0. && int_mod(i, 2) == 1)
            oa = pow(clamp(cd / vb.y, 0., 1.), vb.z);
        px();
        fc = fc + vec4(cc * oa, oa) * (1. - fc.a);
        if((fc.a >= 1. || cd > 128.))
            break;
    }

    fragColor = fc / fc.a;
}
      // --------[ Original ShaderToy ends here ]---------- //

void main(void) {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}