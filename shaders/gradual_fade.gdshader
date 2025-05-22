shader_type canvas_item;

uniform float fade_start = 100.0; // Start fading here (in pixels from the top)
uniform float fade_end = 0.0;     // Fully transparent above this Y
uniform vec2 viewport_size; // You'll set this from GDScript

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    float y_pos = SCREEN_UV.y * viewport_size.y;

    float alpha = smoothstep(fade_end, fade_start, y_pos);
    COLOR = tex_color * vec4(1.0, 1.0, 1.0, alpha);
}