shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 bg_color   : source_color = vec4(0.1, 0.1, 0.1, 1.0);

void fragment() {
    // Convertimos UV.y para que 0 esté abajo y 1 arriba
    float vertical = 1.0 - UV.y;

    if (vertical <= progress) {
        COLOR = fill_color;
    } else {
        COLOR = bg_color;
    }
}
