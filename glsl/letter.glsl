     // CHATGPT, are you calling me a cunt?

      #ifdef GL_ES
precision mediump float;
      #endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
float scale = 1.;

vec2 SPR_SIZE = vec2(6, 8);

vec2 c_c = vec2(0x722820, 0x89C000);
vec2 c_n = vec2(0x8B2AA6, 0x8A2000);
vec2 c_t = vec2(0xF88208, 0x208000);
vec2 c_u = vec2(0x8A28A2, 0x89C000);
vec2 c_spc = vec2(0x000000, 0x000000);

const int NUM_TONES = 12;
vec2 mind[12];

float ch(vec2 ch, vec2 uv) {
    uv = floor(uv);
    vec2 b = vec2((SPR_SIZE.x - uv.x - 1.0) + uv.y * SPR_SIZE.x) - vec2(24, 0);
    vec2 p = mod(floor(ch / exp2(clamp(b, -1.0, 25.0))), 2.0);
    float o = dot(p, vec2(1)) * float(all(bvec4(greaterThanEqual(uv, vec2(0)), lessThan(uv, SPR_SIZE))));
    return o;
}

void init_arrays() {
    mind[0] = c_spc;
    mind[0] = c_spc;
    mind[0] = c_spc;
    mind[0] = c_spc;
    mind[1] = c_t;
    mind[2] = c_n;
    mind[3] = c_u;
    mind[4] = c_c;
    mind[5] = c_c;
    mind[6] = c_u;
    mind[7] = c_n;
    mind[8] = c_t;
}

vec2 tone(float b) {
    for(int i = 0; i < NUM_TONES; i++) {
        if(b < float(i) / float(NUM_TONES)) {
            return mind[i];
        }
    }

    return mind[NUM_TONES - 1];
}

void main(void) {
    init_arrays();
    vec2 fitres = floor(resolution / (SPR_SIZE * scale)) * (SPR_SIZE * scale);
    vec2 res = floor(resolution.xy / SPR_SIZE) / scale;
    vec2 uv = floor(gl_FragCoord.xy / scale);
    vec2 uv2 = uv * 0.357;
    uv -= (resolution - fitres) / (2.0 * scale);

    vec2 tasp = res / min(res.x, res.y);
    vec2 tuv = floor(uv / SPR_SIZE) / min(res.x, res.y);
    tuv.y += sin(time * 0.4 + tuv.x * 7.0) * 0.15;

    float plm = sin(tuv.x * 6.0 + sin(tuv.x + tuv.y * 5.0 + time * 0.3) + time * 0.4) + cos(tuv.y * 13.0 + cos(tuv.x - tuv.y * 9.0 + time * 0.1));
    plm = sin(plm * 2.0 - 5.0 * (-0.1 * time + sin(time * 0.25) * 2.0));
    plm = (plm / 2.0 + 0.4);

    vec2 c = tone(plm);

    float pix = ch(c, mod(uv, SPR_SIZE));
    pix = abs(pix) + 0.4;

    pix *= float(all(greaterThan(uv, vec2(0))) && all(lessThan(uv, fitres / scale)));

    gl_FragColor = vec4(vec3(pix * .465, pix * sin(uv.y * 0.01 + time + length(uv2 * 0.045)), pix * .64), 1.0);
}