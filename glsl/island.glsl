
/*
 * Original shader from: https://www.shadertoy.com/view/cdV3Rc
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
// water based on https://www.shadertoy.com/view/Ms2SD1

// math
#define PI 3.14159265
#define PI_D_2 1.5707963267
// parameters
#define WATER_LEVEL_HEIGHT 0.21
#define TERRAIN_OCTAVE_NUM 8
#define MAX_ITER 64

// error to be used for float operations
#define ERROR 0.02

// AABB of the island for ray marching optimization
#define BOX vec3(1.0, 0.7, 1.0)

// main colors use for material appearance
#define MAIN_GREEN vec3(0.035, 0.08, 0.02)
#define MAIN_BLUE vec3(0.0, 0.15, 0.35)
#define MAIN_BROWN vec3(0.4,0.2,0.05)
#define SAND_COLOR vec3(0.256, 0.16, 0.04)

// light parameters
#define LIGHT_DIR vec3(0.1, -0.2, 1.0)
#define LIGHT_COL vec3(8.10,6.00,4.20)
#define SKY_LIGHT vec3(0.4, 0.7, 1.2)

// water parameters
#define WATER_HEIGHT 0.36
#define WATER_SPEED 0.4
#define WATER_FREQ 0.16
#define WATER_TIME iTime * WATER_SPEED

// material ids
#define WATER_MATERIAL 1
#define TERRAIN_MATERIAL 0

const mat2 octave_m = mat2(1.6, 1.2, -1.2, 1.6);
const mat2 octave_m_2 = mat2(1.12, 3.84, -3.84, 1.12); // octave_m * octave_m
const mat2 octave_m_3 = mat2(-2.816, 7.488, -7.488, -2.816); // octave_m * octave_m * octave_m

// super-sampling parameter for AA
#define AA 1

// a hack for webgl compiler to not unroll the loop
#define ZERO (min(iFrame,0))

// rotation matrix for octaves
const mat2 terrain_octave_rot = mat2(0.75471, -0.65606, 0.65606, 0.75470);

float hash13(vec2 p2) {
	vec3 p3 = vec3(fract(p2 * .1031), .1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(in vec2 p) {
	vec2 i = floor(p);
	vec2 u = smoothstep(0.0, 1.0, fract(p));

	float res = mix(mix(hash13(i), hash13(i + vec2(1, 0)), u.x), mix(hash13(i + vec2(0, 1)), hash13(i + vec2(1, 1)), u.x), u.y);
	return res;
}

// a terrain pattern of first (OCTAVE_NUM / 2) octaves
float terrain_raw_height(in vec2 p) {
	float amplitude = 1.0;
	float height = 0.0;
	vec2 rot_coords = p;
	for(int i = 0; i < TERRAIN_OCTAVE_NUM / 2; ++i) {
		height += amplitude * value_noise(rot_coords);
		amplitude *= 0.45;
		rot_coords = 2.0 * terrain_octave_rot * rot_coords;
	}

	return height;

}

// the actual terrain heightmap, downscaled at the edges the bounding box to make the actual island form
float terrain(in vec2 p) {
    // calculating major low-freq octaves
	float amplitude = 1.0;
	float octaves = 0.0;
	vec2 rot_coords = p;
	for(int i = 0; i < TERRAIN_OCTAVE_NUM / 2; i++) {
		octaves += amplitude * value_noise(rot_coords);
		amplitude *= 0.45;
		rot_coords = 2.0 * terrain_octave_rot * rot_coords;
	}

    // downscale them to get the island pattern
	float height = 2.0 * (octaves - 1.0) * (0.5 * (1.0 - smoothstep(0.8, 1.0, length(p)) + 0.5));

    // calculating minor high-freq octaves 
	octaves = .0;
	for(int i = TERRAIN_OCTAVE_NUM / 2; i < TERRAIN_OCTAVE_NUM; i++) {
		octaves += amplitude * value_noise(rot_coords);
		amplitude *= 0.45;
		rot_coords = 2.0 * terrain_octave_rot * rot_coords;
	}

    // adding them without any scale
	height += 2.0 * octaves;

    // making shure the underwater surface fades smoothly with distance from the center
	float dist = length(p);
	return dist > 1.0 ? max(0.0, height) * (2.0 - dist * dist) : height;
}

vec3 rainbow(in vec3 ray_dir) {

	vec3 rainbow_dir = normalize(vec3(0.0, -1.0, 0.7));
	float theta = degrees(acos(4.0 * dot(rainbow_dir, ray_dir) - 2.35));

	const float intensity = 0.30;

	vec3 color_range = vec3(50.0, 53.0, 56.0);	// angle for red, green and blue
	vec3 nd = clamp(1.0 - abs((color_range - theta) * 0.2), 0.0, 1.0);
	vec3 color = (3.0 * nd * nd - 2.0 * nd * nd * nd) * intensity;

	return color * smoothstep(-0.6, -0.5, ray_dir.y) * 0.5;
}

mat3 set_camera(in vec3 ro, in vec3 ta) {
	vec3 cf = normalize(ta - ro);
	vec3 up = vec3(0, 1, 0);
	vec3 cu = normalize(cross(cf, up));
	vec3 cv = normalize(cross(cu, cf));
	return mat3(cu, cv, cf);
}

// Box intersection by Inigo Quilez https://iquilezles.org/articles/boxfunctions

vec2 box_intersection(in vec3 ro, in vec3 rd, in vec3 rad) {
	vec3 m = 1.0 / rd;
	vec3 n = m * ro;
	vec3 k = abs(m) * rad;
	vec3 t1 = -n - k;
	vec3 t2 = -n + k;

	float tN = max(max(t1.x, t1.y), t1.z);
	float tF = min(min(t2.x, t2.y), t2.z);

	if(tN > tF || tF < 0.0)
		return vec2(-1.0); // no intersection

	return vec2(tN, tF);
}

float water_octave(vec2 uv) {
	uv += value_noise(uv) * 2.0 - 1.0;
	vec2 wv = 1.0 - abs(sin(uv));
	vec2 swv = abs(cos(uv));
	wv = mix(wv, swv, wv);
	return pow(1.0 - pow(wv.x * wv.y, 0.65), 2.0);
}

// leave only big waves for geometry calculation
float water_geom(vec2 uv) {
	float freq = WATER_FREQ * 5.832;
	float amplitude = WATER_HEIGHT * 0.02;
	float time = WATER_TIME;
	uv *= octave_m_3;

	return WATER_LEVEL_HEIGHT + (water_octave((uv + time) * freq) + water_octave((uv - time) * freq)) * amplitude;
}

// for detailed per-fragment appearance use more octaves
float water_detailed(vec2 uv) {
	float freq = WATER_FREQ * 3.24;
	float amplitude = WATER_HEIGHT * 0.0625;
	float height = WATER_LEVEL_HEIGHT;
	float time = WATER_TIME;
	uv *= octave_m_2;

	for(int i = 0; i < 3; i++) {
		height += (water_octave((uv + time) * freq) + water_octave((uv - time) * freq)) * amplitude;

		uv *= octave_m;
		freq *= 1.8;
		amplitude *= 0.25;
	}

	return height;
}

bool map(vec3 ray, inout float t, inout int material_idx) {
	float delta_w_terrain = ray.y - terrain(ray.xz);
	float delta_w_water = ray.y - water_geom(ray.xz);

	if(abs(delta_w_terrain) < ERROR) {
		material_idx = 0;
		return true;
	}
	if(abs(delta_w_water) < ERROR) {
		material_idx = 1;
		return true;
	}

	float step_mul = min(delta_w_water, delta_w_terrain);
	t += step_mul * 0.2;

	return false;
}

vec3 get_sky_color(vec3 rd) {
	return SKY_LIGHT;
}

vec3 water_color(vec3 normal, vec3 pos, vec3 rd) {
    // calibrate fresnel - we want some pattern even at high view angels
	if(rd.y < -0.5)
		rd.y = -0.5;

	float fresnel = pow(1.0 - clamp(dot(-rd, normal), 0.0, 1.0), 5.0);

	return fresnel * SKY_LIGHT + 0.8 * MAIN_BLUE;
}

// doing normals
vec3 calc_normal(float center, float dhdx, float dhdz, float eps) {
	return normalize(vec3(center - dhdx, eps, center - dhdz));
}

vec3 get_normal(in vec3 p, float t, int mat) {
	float eps = 0.001 * t;

	if(mat == 0) {
		return calc_normal(terrain(p.xz), terrain(vec2(p.x + eps, p.z)), terrain(vec2(p.x, p.z + eps)), eps);
	} else if(mat == 1) {
		return calc_normal(water_detailed(p.xz), water_detailed(vec2(p.x + eps, p.z)), water_detailed(vec2(p.x, p.z + eps)), eps);
	}

	return vec3(1.0, 0.0, 1.0);
}

// super-hacky shadows
float test_shadow(vec3 ray_origin, vec3 ray_direction) {

	vec2 box_intersect = box_intersection(ray_origin, ray_direction, BOX);

	float res = 1.0;

	if(box_intersect.x > 0.0 || (ray_origin.x < 1.0 && ray_origin.x > -1.0 &&
		ray_origin.y < BOX.y &&
		ray_origin.z < 1.0 && ray_origin.z > -1.0)) {
		float t = box_intersect.x > 0.0 ? box_intersect.x : 0.02;
		for(int i = 0; i < MAX_ITER; i++) {
			vec3 ray = ray_origin + t * ray_direction;
			float delta_w_terrain = ray.y - terrain(ray.xz);
			if(delta_w_terrain < ERROR) {
				return clamp(ray.y * ray.y * t * t * 1.5, clamp(t, 0.0, 0.3), 1.0);
			}

			t += delta_w_terrain * 0.4 + 0.001;
			if(t > box_intersect.y || ray.y > BOX.y)
				return 1.0;
		}
	}

	return clamp(res, 0.0, 1.0);
}

// main material function for water and terrain
vec3 material_calc(vec3 pos, vec3 ray_direction, vec3 normal, float t, int mat_type) {
	vec3 col;
	vec3 light_dir = -normalize(LIGHT_DIR);

	float sun_shadow = test_shadow(pos, light_dir);
	if(mat_type == TERRAIN_MATERIAL) {
		float sun_diffuse = clamp(dot(normal, light_dir), 0.0, 1.0);
		float sky_diffuse = sqrt(clamp(0.5 + 0.5 * normal.y, 0.0, 1.0));
		float ind_diffuse = clamp(0.2 + 0.8 * dot(normalize(vec3(-light_dir.x, 0.0, light_dir.z)), normal), 0.0, 1.0);

		float mid = pos.y - WATER_LEVEL_HEIGHT * 0.5;
		vec3 colmain = mix(MAIN_GREEN, MAIN_BROWN, smoothstep(0.2, 0.9, fract(mid)));
		colmain *= 1.0 - 0.6 * smoothstep(0.31, 0.8, pos.y);

		if(abs(pos.y - WATER_LEVEL_HEIGHT) < 0.04)
			colmain = SAND_COLOR;

		col = LIGHT_COL * sun_diffuse * sun_shadow + SKY_LIGHT * sky_diffuse;
		col += ind_diffuse * vec3(0.45, 0.35, 0.25) + (get_sky_color(normal) + MAIN_BLUE) * 0.12;
		col *= colmain;

		vec3 hal = normalize(light_dir - ray_direction);

		col += (0.5) * (0.04 + 0.96 * pow(clamp(1.0 + dot(hal, ray_direction), 0.0, 1.0), 5.0)) *
			vec3(7.0, 6.0, 5.0) * sun_diffuse * sun_shadow *
			pow(clamp(dot(normal, hal), 0.0, 1.0), 16.0);
	} else if(mat_type == WATER_MATERIAL) {
		float x = terrain(pos.xz);
		float delta = abs(pos.y - x) * 0.5;

		float atten = smoothstep(1.0, 0.99, length(pos.xz));
		vec3 depth_layer1 = atten * vec3(0.0, 0.2, 0.4);

		col = water_color(normal, pos, ray_direction);

		col *= (1.0 + 1.3 * smoothstep(0.11, 0.0, delta));

		float sh = float(clamp(abs(value_noise(pos.xz * 12.0 + iTime * 0.1)), 0.0, 1.0) > 0.5);
		col += 0.4 * smoothstep(0.35, 1.0, sh * sin(delta * 200.0 + iTime * 1.5) * smoothstep(1.5, 1.45, length(pos.xz)) * smoothstep(0.07, 0.02, delta));

		col = mix(0.3 * col, col, sun_shadow);
	} else {
		col = vec3(1.0, 0.0, 1.0); // Debug for missing some parts with no material
	}

	float fo = 1.0 - exp(-pow(0.1 * t, 1.5));
	vec3 fco = 0.25 * (MAIN_BLUE + get_sky_color(normal)) * vec3(0.2, 0.33, 0.5);
	col = mix(col, fco, fo);

	col += rainbow(ray_direction);

	return col;
}

vec3 Render(in vec3 ray_origin, in vec3 ray_direction) {
	vec2 box_intersect = box_intersection(ray_origin, ray_direction, BOX);
	float water_dist = (WATER_LEVEL_HEIGHT * 2.0 - ray_origin.y) / ray_direction.y;

	int material_idx = WATER_MATERIAL;

	float t = box_intersect.x > 0.0 ? box_intersect.x : water_dist;
	vec3 ray = ray_origin + ray_direction * t;

	for(int i = 0; i < MAX_ITER; ++i) {
		if(map(ray, t, material_idx))
			break;

		ray = ray_origin + ray_direction * t;
	}

	vec3 normal = get_normal(ray, t, material_idx);
	vec3 col = material_calc(ray, ray_direction, normal, t, material_idx);
	return col;
}

// Post-processing from some of Inigo Quilez shaders
void psot_process(inout vec3 in_color, vec2 q, vec2 sp, float aspect) {
	in_color += smoothstep(1.0, 0.0, length(sp)) * LIGHT_COL * 0.003;

    // Color grading
	in_color = in_color * vec3(1.11, 0.89, 0.79);

    // Compress
	in_color = 1.35 * in_color / (1.0 + in_color);

    // Gamma
	in_color = pow(in_color, vec3(0.454545));

    // S-surve
    //color = clamp(color,0.0,1.0);
	in_color = in_color * in_color * (3.0 - 2.0 * in_color);

    // Vignette
	in_color *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);

}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 p = (-iResolution.xy + 2.0 * fragCoord) / iResolution.y;
	float aspect = iResolution.x / iResolution.y;

	vec3 view_target = vec3(0.0, 0.1, 0.0);
	vec3 cam_pos = vec3(0.0, 1.288, -0.96);
	mat3 cam_mat = set_camera(cam_pos, view_target);

	vec3 color = vec3(0.0);

    #if AA>1
	for(int m = 0; m < AA; m++) for(int n = 0; n < AA; n++) {
			vec2 o = (-0.5 + vec2(float(m), float(n)) / float(AA)) * 2.0 / iResolution.y;
			vec3 view_dir = cam_mat * normalize(vec3(p + o, 1.5));
	#else    
			vec3 view_dir = cam_mat * normalize(vec3(p, 1.5));
	#endif

			color += Render(cam_pos, view_dir);

	#if AA>1
		}
	color /= float(AA * AA);
	#endif

    // Do the post-processing
	psot_process(color, fragCoord / iResolution.xy, p, aspect);

	fragColor = vec4(color, 1.0);
}
// --------[ Original ShaderToy ends here ]---------- //

void main(void) {
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
