shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.8, 1.0, 0.7);
uniform vec4 bg_color   : source_color = vec4(0.1, 0.1, 0.1, 0.7);

void fragment() {
    // UV centrado (-0.5 a 0.5)
    vec2 centered_uv = UV - vec2(0.5);

    // Radio del círculo
    float dist = length(centered_uv);

    // Fuera del círculo → transparente
    if (dist > 0.5) {
        discard;
    }

    // Progreso vertical (abajo → arriba)
    float vertical = 1.0 - UV.y;

    if (vertical <= progress) {
        COLOR = fill_color;
    } else {
        COLOR = bg_color;
    }
}
