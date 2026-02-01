shader_type spatial;
render_mode unshaded;

render_mode cull_disabled;

uniform sampler2D image;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(image, UV.xy).xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
