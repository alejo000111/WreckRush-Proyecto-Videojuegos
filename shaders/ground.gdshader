shader_type spatial;

uniform vec4 base : source_color = vec4(0.17, 0.18, 0.21, 1.0);
uniform vec4 punto : source_color = vec4(1.0, 0.478, 0.102, 1.0);
uniform float baldosa = 8.0;
uniform float intensidad_punto = 0.0;

varying vec3 pos_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = pos_mundo.xz / baldosa;
	vec2 f = fract(c);
	vec2 linea = smoothstep(0.0, 0.03, f) * smoothstep(0.0, 0.03, 1.0 - f);
	float rejilla = linea.x * linea.y;
	vec3 col = base.rgb * mix(0.72, 1.0, rejilla);
	float d = length(f - 0.5);
	float p = smoothstep(0.06, 0.04, d) * intensidad_punto;
	col = mix(col, punto.rgb, p);
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
