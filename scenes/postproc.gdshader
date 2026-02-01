shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D gasmask_texture : filter_nearest;
uniform vec2 gasmask_mul;
uniform vec2 gasmask_off;

uniform int pixelate_factor;
uniform float vignette_m;
uniform float vignette_b;

uniform int behavior : hint_enum("Pixelate", "Draw Gas Mask");

float vignette(vec2 uv) {
	vec2 ndc = 2.0 * (uv - 0.5);
	float dist2 = dot(ndc, ndc);
	return min(1.0, max(0.0, vignette_m * dist2 + vignette_b));
}

vec2 pixelate_uv(vec2 uv, vec2 px_size, float factor) {
	vec2 scaling = px_size * factor;
	vec2 scaled = uv / scaling;
	vec2 floored = floor(scaled) + vec2(0.5);
	return floored * scaling;
}

vec3 superimpose_gas_mask(vec2 uv, vec3 input) {
	vec2 gasmask_pos = gasmask_off + 0.5 + gasmask_mul * (uv - 0.5);
	vec4 gasmask = texture(gasmask_texture, gasmask_pos);
	float vig = vignette(uv);
	vec3 mixed = mix(input, gasmask.rgb, gasmask.a * vig);
	return mixed;
}

vec4 gas_mask(vec2 uv) {
	vec2 gasmask_pos = gasmask_off + 0.5 + gasmask_mul * (uv - 0.5);
	vec4 gasmask = texture(gasmask_texture, gasmask_pos);
	float vig = vignette(uv);
	return vec4(gasmask.rgb, gasmask.a * vig);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (behavior == 0) {
		vec2 uv = pixelate_uv(SCREEN_UV, SCREEN_PIXEL_SIZE, float(pixelate_factor));
		COLOR = texture(screen_texture, uv);
	} else {
		//vec2 uv = pixelate_uv(SCREEN_UV, SCREEN_PIXEL_SIZE, float(pixelate_factor));
		//vec3 screen = texture(screen_texture, uv).rgb;
		vec4 gasmask = gas_mask(SCREEN_UV);
		COLOR = gasmask;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
