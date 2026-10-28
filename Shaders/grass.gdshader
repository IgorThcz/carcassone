shader_type spatial;

// 2. Ativa o modo transparente para o Godot respeitar o render_priority
render_mode blend_mix, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_nearest;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a; // Garante que o canal alpha está ativo
}