shader_type canvas_item;

vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}
vec4 darken(vec4 base, vec4 blend){
	return min(base, blend);
}
vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}
vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}
vec4 exclusion(vec4 base, vec4 blend){
	return base + blend - 2.0 * base * blend;
}
vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec4 hard_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec4 soft_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}
vec4 color_dodge(vec4 base, vec4 blend){
	vec3 result = base.rgb / max(vec3(0.001), (1.0 - blend.rgb)); // Avoid division by 0
    result = clamp(result, 0.0, 1.0); // Clamp after to avoid overshooting
    return vec4(result, base.a);
}
vec4 linear_dodge(vec4 base, vec4 blend){
	vec4 result = base + blend;
    result.rgb = clamp(result.rgb, 0.0, 1.0); // Clamp RGB channels
    result.a = base.a; // Preserve base alpha or blend them properly
    return result;
}

vec4 color_burn(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) / blend;
}
vec4 linear_burn(vec4 base, vec4 blend){
	vec3 result = base.rgb + blend.rgb - vec3(1.0);
    result = clamp(result, 0.0, 1.0);
    return vec4(result, base.a);
}

uniform vec4 tint_color; // <-- This will receive the modulation color
uniform int blending_mode; // <-- This will receive the blending mode

void fragment() {
	vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    vec4 blended_color = multiply(tex_color, tint_color); //default mode
	
	if (blending_mode == 1) {
		blended_color = color_burn(tex_color, tint_color);
	}
	if (blending_mode == 2) {
		blended_color = linear_burn(tex_color, tint_color);
	}
	if (blending_mode == 3) {
		blended_color = hard_light(tex_color, tint_color);
	}
	if (blending_mode == 4) {
		blended_color = soft_light(tex_color, tint_color);
	}
	if (blending_mode == 5) {
		blended_color = color_dodge(tex_color, tint_color);
	}
	if (blending_mode == 6) {
		blended_color = linear_dodge(tex_color, tint_color);
	}

    //COLOR = blended_color;
	COLOR = mix(tex_color, blended_color, tint_color.a);
}
