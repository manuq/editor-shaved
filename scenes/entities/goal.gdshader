shader_type canvas_item;

uniform float displace_x : hint_range(0.0,1.0) = 0.0;
uniform float displace_y : hint_range(0.0,1.0) = 0.0;

// uniform vec4 color : source_color;
// uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR = texture(TEXTURE, UV + vec2(-displace_x, -displace_y + sin(TIME * 1.5) * 0.1));
}
