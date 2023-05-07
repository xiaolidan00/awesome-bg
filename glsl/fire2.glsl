#extension GL_OES_standard_derivatives : enable

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main(void) {

    vec2 pos = (gl_FragCoord.xy / resolution.xy) * 4.;

    float color = 1.0;
    float radius = 1.;
    float speed = 2.5;
    float dist = distance(vec2((sin(time * speed) * .5) * radius, cos(time * speed) * radius) + 2., pos);
    float dist2 = distance(vec2(mouse.x, mouse.y) * 4., pos);
    color /= distance(vec2(4, 2), vec2(pos.x * 2., pos.y));
    float d = dist;
    color -= d;
    gl_FragColor = vec4(vec3(color / d, color - d * 0.3, color * d), 1.0);

}