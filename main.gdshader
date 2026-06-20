shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    float amount = 0.001; // Muy sutil
    vec4 col;
    col.r = texture(SCREEN_TEXTURE, vec2(uv.x + amount, uv.y)).r;
    col.g = texture(SCREEN_TEXTURE, uv).g;
    col.b = texture(SCREEN_TEXTURE, vec2(uv.x - amount, uv.y)).b;
    col.a = 1.0;
    COLOR = col;
}