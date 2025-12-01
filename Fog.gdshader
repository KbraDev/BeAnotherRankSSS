shader_type canvas_item;

// Noise Texture
uniform sampler2D noise_texture: repeat_enable, filter_nearest;
// Fog density
uniform float density: hint_range(0.0, 1.0) = 1.0
;
// fog speed
uniform vec2 speed = vec2(0.02, 0.01);

void fragment() {
	// slowly move
	vec2 uv = UV + speed * TIME;
	// sample the noise texture
	float noise = texture(noise_texture, uv).r;
	// conver noise from the (0.0, 1.0) range to (-1.0, 1.0) range
	// clamp it between 0.0 and 1.0 again
	float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);
	// apply the fog effect
	COLOR.a *= fog * density;
}
