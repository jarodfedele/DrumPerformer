shader_type canvas_item;

uniform float blur_radius = 2.0;

void fragment() {
	vec4 color = vec4(0.0);
	vec2 size = blur_radius * SCREEN_PIXEL_SIZE;

	color += texture(TEXTURE, UV + size * vec2(-1.0, -1.0));
	color += texture(TEXTURE, UV + size * vec2( 0.0, -1.0));
	color += texture(TEXTURE, UV + size * vec2( 1.0, -1.0));

	color += texture(TEXTURE, UV + size * vec2(-1.0,  0.0));
	color += texture(TEXTURE, UV);
	color += texture(TEXTURE, UV + size * vec2( 1.0,  0.0));

	color += texture(TEXTURE, UV + size * vec2(-1.0,  1.0));
	color += texture(TEXTURE, UV + size * vec2( 0.0,  1.0));
	color += texture(TEXTURE, UV + size * vec2( 1.0,  1.0));

	COLOR = color / 9.0;
}