shader_type spatial;

uniform vec3 color : source_color = vec3(0.95, 0.0, 0.95); 

void fragment() {
	ALBEDO = color;
	ALPHA = 0.4;
}