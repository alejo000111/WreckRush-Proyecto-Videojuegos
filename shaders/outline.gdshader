shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, blend_mix;

uniform vec4 color : source_color = vec4(1.0, 0.76, 0.1, 1.0);
uniform float grosor = 0.25;
uniform float opacidad = 1.0;

void vertex() {
	VERTEX += normalize(VERTEX + vec3(0.0001)) * grosor;
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = opacidad;
}
