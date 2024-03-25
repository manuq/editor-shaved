shader_type canvas_item;

uniform float fill : hint_range(-0.01,1.0) = -0.01;
uniform bool reverse = false;
uniform vec4 color : source_color;
uniform sampler2D heightMap;

void fragment(){
	float h = texture(heightMap,UV).x;
	h = clamp(floor(h+fill),0.0,1.0);
	if (reverse) {
		h = 1.0 - h;
	}
	COLOR = vec4(color.rgb,color.a*h);
}