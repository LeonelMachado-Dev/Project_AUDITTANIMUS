shader_type canvas_item;

// Parámetros ajustables desde el Inspector
uniform vec4 line_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float speed : hint_range(0.1, 5.0) = 1.5;
uniform float frequency : hint_range(1.0, 20.0) = 6.0;
uniform float amplitude : hint_range(0.01, 0.5) = 0.15;
uniform float thickness : hint_range(0.001, 0.05) = 0.008;

// Función para generar una onda matemática suave
float memory_wave(float x, float phase, float offset) {
    // Entrelazamos senos y cosenos para evitar que sea una onda aburrida e idéntica
    return sin(x * frequency + phase) * cos(x * frequency * 0.5 - phase) * amplitude + offset;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * speed;
    
    // Inicializamos el color de salida en transparente
    vec4 final_color = vec4(0.0);
    
    // --- LÍNEA 1 (Pasa por "delante") ---
    float y_wave1 = memory_wave(uv.x, time, 0.5);
    float dist1 = abs(uv.y - y_wave1);
    // Control de grosor y suavizado (Anti-aliasing)
    float line1 = smoothstep(thickness, 0.0, dist1);
    
    // --- LÍNEA 2 (Pasa por "detrás" usando un desfase) ---
    // Cambiamos el desfase (time * 1.2) para que se muevan a velocidades ligeramente distintas
    float y_wave2 = memory_wave(uv.x, -time * 1.2 + 2.0, 0.5);
    float dist2 = abs(uv.y - y_wave2);
    float line2 = smoothstep(thickness, 0.0, dist2);
    
    // --- EFECTO DE ENTRELAZADO (Oclusión simulada) ---
    // Si la línea 2 está detrás en ciertos puntos de intersección, reducimos su opacidad
    float intersection = smoothstep(0.05, 0.0, abs(y_wave1 - y_wave2));
    // Cuando se cruzan y el seno de la línea 1 es positivo, "escondemos" un poco la línea 2
    if (sin(uv.x * frequency + time) > 0.0) {
        line2 *= (1.0 - intersection * 0.6);
    } else {
        line1 *= (1.0 - intersection * 0.6);
    }
    
    // --- COMPOSICIÓN Y GLOW (BRILLO AC 2) ---
    float total_lines = line1 + line2;
    
    // Añadimos un brillo difuminado de fondo
    float glow1 = smoothstep(thickness * 4.0, 0.0, dist1) * 0.4;
    float glow2 = smoothstep(thickness * 4.0, 0.0, dist2) * 0.4;
    float total_glow = glow1 + glow2;
    
    // Color final mezclando el color base con el destello blanco/celeste del Animus
    final_color = (line_color * total_lines) + (glow_color * total_glow);
    
    // Añadimos partículas/bloques de memoria simulados integrados en las líneas
    float blocks = step(0.92, sin(uv.x * 30.0 - time * 2.0)) * step(0.92, cos(uv.y * 20.0));
    final_color += vec4(blocks) * glow_color * total_lines * 1.5;
    
    COLOR = final_color;
}