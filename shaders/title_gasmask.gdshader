shader_type canvas_item;

uniform sampler2D gasmask_texture : filter_nearest;
uniform vec2 gasmask_mul;
uniform vec2 gasmask_off;

uniform float vignette_m;
uniform float vignette_b;

float vignette(vec2 uv) {
	vec2 ndc = 2.0 * (uv - 0.5);
	float dist2 = dot(ndc, ndc);
	return min(1.0, max(0.0, vignette_m * dist2 + vignette_b));
}

vec4 gas_mask(vec2 uv) {
	vec2 gasmask_pos = gasmask_off + 0.5 + gasmask_mul * (uv - 0.5);
	vec2 inside = step(0.0, gasmask_pos) * step(-1.0, -gasmask_pos);
	vec4 gasmask = texture(gasmask_texture, gasmask_pos);
	float vig = vignette(uv);
	return vec4(gasmask.rgb, gasmask.a * vig * inside.x * inside.y);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 gasmask = gas_mask(SCREEN_UV);
	COLOR = gasmask;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
