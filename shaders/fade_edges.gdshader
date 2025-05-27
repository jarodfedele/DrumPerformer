//shader_type canvas_item;
//
//uniform float edge_fade_1 : hint_range(0.0, 1.0) = 0.9;
//uniform float edge_fade_2 : hint_range(0.0, 0.25) = 0.1;
//
//float exponential_step(float edge0, float edge1, float x){
	//return pow(clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0), 0.1);
//}
//
//void fragment() {
    //vec2 uv = UV;
    //
    //float fade_x = exponential_step(0.0, edge_fade_1, uv.x) * exponential_step(1.0, 1.0 - edge_fade_1, uv.x);
    //float fade_y = exponential_step(0.0, edge_fade_1, uv.y) * exponential_step(1.0, 1.0 - edge_fade_1, uv.y);
    //
    //float edge_alpha = fade_x * fade_y;
//
    //COLOR = texture(TEXTURE, uv) * vec4(1.0, 1.0, 1.0, edge_alpha);
	//
	//fade_x = smoothstep(0.0, edge_fade_2, uv.x) * smoothstep(1.0, 1.0 - edge_fade_2, uv.x);
    //fade_y = smoothstep(0.0, edge_fade_2, uv.y) * smoothstep(1.0, 1.0 - edge_fade_2, uv.y);
    //
    //edge_alpha = fade_x * fade_y * edge_alpha;
//
    //COLOR = texture(TEXTURE, uv) * vec4(1.0, 1.0, 1.0, edge_alpha);
//}

shader_type canvas_item;

uniform float edge_fade_1 : hint_range(0.0, 1.0) = 0.9;
uniform float edge_fade_2 : hint_range(0.0, 0.25) = 0.1;

// Fixed bounds (screen-space)
uniform vec2 bounds_min = vec2(0.0, 0.0);
uniform vec2 bounds_max = vec2(1920.0, 1080.0);
uniform bool custom_bounds = false;

float exponential_step(float edge0, float edge1, float x){
	return pow(clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0), 0.1);
}

void fragment() {
    // Get screen-space UV
    vec2 screen_uv = SCREEN_UV;

    // Convert to screen pixel coordinates
    vec2 screen_px = screen_uv * vec2(textureSize(TEXTURE, 0));

    // Remap to normalized space within the fixed bounds
	vec2 local_uv;
	if (custom_bounds) {
		local_uv = (screen_px - bounds_min) / (bounds_max - bounds_min);
	}
	else {
		local_uv = UV;
	}

    // Now apply your edge fade logic based on this custom space
    float fade_x = exponential_step(0.0, edge_fade_1, local_uv.x) * exponential_step(1.0, 1.0 - edge_fade_1, local_uv.x);
    float fade_y = exponential_step(0.0, edge_fade_1, local_uv.y) * exponential_step(1.0, 1.0 - edge_fade_1, local_uv.y);
    
    float edge_alpha = fade_x * fade_y;

    fade_x = smoothstep(0.0, edge_fade_2, local_uv.x) * smoothstep(1.0, 1.0 - edge_fade_2, local_uv.x);
    fade_y = smoothstep(0.0, edge_fade_2, local_uv.y) * smoothstep(1.0, 1.0 - edge_fade_2, local_uv.y);
    
    edge_alpha *= fade_x * fade_y;

    COLOR = texture(TEXTURE, UV) * vec4(1.0, 1.0, 1.0, edge_alpha);
}