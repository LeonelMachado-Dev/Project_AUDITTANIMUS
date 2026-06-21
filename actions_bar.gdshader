shader_type canvas_item;

// Parámetros que podrás modificar desde el Inspector de Godot
uniform vec4 color_base : source_color = vec4(0.9, 0.9, 0.9, 0.3); // Gris claro semi-transparente del Animus
uniform vec4 color_lineas : source_color = vec4(1.0, 1.0, 1.0, 0.15); // Color de las líneas de escaneo
uniform float velocidad_escaneo : hint_range(0.0, 10.0) = 1.5;
uniform float densidad_lineas : hint_range(1.0, 500.0) = 200.0;
uniform float parpadeo_ruido : hint_range(0.0, 1.0) = 0.02; // Sutil glitch de brillo

// Función para generar un ruido pseudo-aleatorio para el glitch del Animus
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // 1. Crear el parpadeo digital del Animus
    float glitch = rand(vec2(TIME, 0.0)) * parpadeo_ruido;
    vec4 color_final = color_base + vec4(glitch, glitch, glitch, 0.0);
    
    // 2. Crear las líneas de escaneo (Scanlines) que se mueven verticalmente
    float linea = sin((FRAGCOORD.y + TIME * velocidad_escaneo * 20.0) * (densidad_lineas / 100.0));
    
    // Si la onda es alta, mezclamos con el color de la línea
    if (linea > 0.7) {
        color_final = mix(color_final, color_lineas, 0.4);
    }
    
    COLOR = color_final;
}
