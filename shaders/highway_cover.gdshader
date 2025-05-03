shader_type canvas_item;

void fragment() {
    // UV.y is 0 at bottom and 1 at top
    float fade = 1.0 - UV.y;
    COLOR = vec4(0.0, 0.0, 0.0, fade); // black, but with fading alpha
}