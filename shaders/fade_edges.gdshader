shader_type canvas_item;

uniform float edge_fade_1 : hint_range(0.0, 1.0) = 0.9;
uniform float edge_fade_2 : hint_range(0.0, 0.25) = 0.1;

float exponential_step(float edge0, float edge1, float x){
	return pow(clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0), 0.1);
}

void fragment() {
    vec2 uv = UV;
    
    float fade_x = exponential_step(0.0, edge_fade_1, uv.x) * exponential_step(1.0, 1.0 - edge_fade_1, uv.x);
    float fade_y = exponential_step(0.0, edge_fade_1, uv.y) * exponential_step(1.0, 1.0 - edge_fade_1, uv.y);
    
    float edge_alpha = fade_x * fade_y;

    COLOR = texture(TEXTURE, uv) * vec4(1.0, 1.0, 1.0, edge_alpha);
	
	fade_x = smoothstep(0.0, edge_fade_2, uv.x) * smoothstep(1.0, 1.0 - edge_fade_2, uv.x);
    fade_y = smoothstep(0.0, edge_fade_2, uv.y) * smoothstep(1.0, 1.0 - edge_fade_2, uv.y);
    
    edge_alpha = fade_x * fade_y * edge_alpha;

    COLOR = texture(TEXTURE, uv) * vec4(1.0, 1.0, 1.0, edge_alpha);
}