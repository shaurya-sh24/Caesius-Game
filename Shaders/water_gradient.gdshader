shader_type canvas_item;
render_mode blend_mix;

uniform vec4 shallow_color : source_color = vec4(0.2, 0.6, 0.9, 0.10);
uniform vec4 deep_color : source_color = vec4(0.0, 0.01, 0.05, 0.80);

void fragment() {
	float t = UV.y;
	COLOR = mix(shallow_color, deep_color, t);
}