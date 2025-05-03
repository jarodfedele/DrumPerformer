shader_type canvas_item;

uniform vec4 tint_color;
uniform int mode;

uniform sampler2D val_map;
uniform int val_map_height;
uniform sampler2D uv_left_bounds_map;
uniform int uv_left_bounds_map_height;
uniform sampler2D uv_right_bounds_map;
uniform int uv_right_bounds_map_height;

void fragment() {
	vec2 uv = UV;
	vec4 tex_color = texture(TEXTURE, UV);

	int row = int((1.0 - UV.y) * float(val_map_height));
	row = clamp(row, 0, val_map_height - 1);
	float val = texelFetch(val_map, ivec2(0, row), 0).r;
	float u_min = texelFetch(uv_left_bounds_map, ivec2(0, row), 0).r;
	float u_max = texelFetch(uv_right_bounds_map, ivec2(0, row), 0).r;
	float center = (u_min + u_max) * 0.5;
	float half_width = 0.5 * (u_max - u_min);
			
	float compressed_half_width;
	if (mode == 1) {
		compressed_half_width = half_width * val;
	}else{
		compressed_half_width = half_width * 1.0;
	}
    float left_bound = center - compressed_half_width;
    float right_bound = center + compressed_half_width;

    if (uv.x < left_bound || uv.x > right_bound || val <= 0.0) {
        discard;
    } else {
        float t = (uv.x - left_bound) / (2.0 * compressed_half_width);
        float original_uvx = mix(u_min, u_max, t);
        COLOR = texture(TEXTURE, vec2(original_uvx, uv.y));
    }
		
	if (mode == 0) {
		tex_color.a *= val;
	}
	
	COLOR *= tex_color * tint_color;
}