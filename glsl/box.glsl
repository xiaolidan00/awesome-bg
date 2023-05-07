    #extension GL_OES_standard_derivatives : enable

      /*
      Just a test glsl shader: example of slicing objects with ray-surface intersection functions
      */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

      #define PI 3.141592653589793

vec2 boxIntersection(in vec3 ro, in vec3 rd, vec3 boxSize, out vec3 outNormal) {
    vec3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    vec3 n = m * ro;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if(tN > tF || tF < 0.0)
        return vec2(-1.0); // no intersection
    outNormal = (tN > 0.0) ? step(vec3(tN), t1) : // ro ouside the box
    step(t2, vec3(tF));  // ro inside the box
    outNormal *= -sign(rd);
    return vec2(tN, tF);
}

float plaIntersect(in vec3 ro, in vec3 rd, in vec4 p) {
    return -(dot(ro, p.xyz) + p.w) / dot(rd, p.xyz);
}

float lightning(vec3 normal, vec3 pos, vec3 lightPos) {
    return abs(dot(normal, normalize(lightPos)) / max(1.0, distance(pos, lightPos)));
}

vec3 shading(vec3 normal, vec3 pos) {
    vec3 lightness = vec3(0.0);

    lightness += lightning(normal, pos, vec3(sin(time * 2.0), 0.0, cos(time * 2.0))) * vec3(1.0, 0.0, 0.0);
    lightness += lightning(normal, pos, vec3(0.0, cos(time * 2.0) * 2.5 + 1.5, sin(time * 2.0))) * vec3(0.0, 0.0, 1.0);

    return lightness;
}

vec3 background(vec3 rd) {
    return abs(rd);
}

vec3 scene(vec3 ro, vec3 rd) {
    vec3 normal = vec3(0.0);
    vec3 planeNormal = -normalize(vec3(-1.0, 1.0, -1.0));

    vec2 boxDist = boxIntersection(ro, rd, vec3(1.0, 2.0, 1.0), normal);

    float planeDist = plaIntersect(ro, rd, vec4(planeNormal, 1.0));

    vec3 box = shading(normal, ro + rd * boxDist.x);
    vec3 plane = shading(planeNormal, ro + rd * planeDist);

    if(planeDist > boxDist.y) {
        return background(rd);
    }

    if(planeDist > boxDist.x) {
          // return plane;
        return mix(plane, background(reflect(rd, planeNormal)), 0.8);
    }

    if(boxDist.x > 0.0) {
          // return box;
        return mix(box, background(reflect(rd, planeNormal)), 1.0);
    }

    return background(rd);
}

mat2 makeRotationMatrix(float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return mat2(vec2(c, -s), vec2(s, c));
}

void main(void) {

    vec2 position = (gl_FragCoord.xy - resolution.xy * 0.5) / min(resolution.x, resolution.y);

    vec3 rd = normalize(vec3(position, 1.0));
    vec3 ro = vec3(0.0, sin(time * 0.5) * 1.32 + 1.0, -10.0);

    mat2 rotation = makeRotationMatrix(time);

    rd.xz *= rotation;
    ro.xz *= rotation;

    vec3 color = scene(ro, rd);

    gl_FragColor = vec4(color, 1.0);

}