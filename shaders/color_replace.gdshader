shader_type canvas_item;

uniform vec4 tint_color; // <-- This will receive the modulation color

void fragment() {
	vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
	COLOR.rgb = tint_color.rgb*0.8;
}