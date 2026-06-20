shader_type canvas_item;

uniform vec4 color_adn : source_color = vec4(0.0, 0.6, 0.8, 0.4); // Azul cian holográfico
uniform float velocidad : hint_range(0.1, 5.0) = 1.2;
uniform float frecuencia_onda : hint_range(1.0, 50.0) = 15.0;
uniform float ancho_helice : hint_range(0.01, 0.5) = 0.25;

void fragment() {
	vec2 uv = UV;

	float tiempo = TIME * velocidad;

	float cadena_a = sin(uv.y * frecuencia_onda - tiempo) * ancho_helice + 0.5;
	float cadena_b = cos(uv.y * frecuencia_onda - tiempo + 1.5708) * ancho_helice + 0.5;

	float grosor = 0.02;

	float linea_a = smoothstep(grosor, 0.0, abs(uv.x - cadena_a));
	float linea_b = smoothstep(grosor, 0.0, abs(uv.x - cadena_b));

	float peldanos = 0.0;
	if (abs(sin(uv.y * frecuencia_onda * 2.0 - tiempo * 2.0)) > 0.98) {
		float min_x = min(cadena_a, cadena_b);
		float max_x = max(cadena_a, cadena_b);
		if (uv.x > min_x && uv.x < max_x) {
			peldanos = 0.3;
		}
	}

	float mascara_adn = max(max(linea_a, linea_b), peldanos);

	mascara_adn *= smoothstep(0.0, 0.2, uv.x) * smoothstep(1.0, 0.8, uv.x);

	COLOR = vec4(color_adn.rgb, mascara_adn * color_adn.a);
}