shader_type canvas_item;

// --- PARÁMETROS DEL INSPECTOR ---
uniform vec4 strand_color : source_color = vec4(0.15, 0.65, 1.0, 1.0); // Color hebras
uniform vec4 block_color : source_color = vec4(0.5, 0.9, 1.0, 1.0);   // Color bloques/datos
uniform float speed : hint_range(0.1, 5.0) = 2.0;                      // Velocidad de giro
uniform float frequency : hint_range(1.0, 15.0) = 5.0;                 // Densidad de las curvas
uniform float amplitude : hint_range(0.05, 0.4) = 0.22;                // Alto de la hélice
uniform float DNA_width : hint_range(0.01, 0.2) = 0.08;                // Ancho de separación
uniform int block_density : hint_range(5, 50) = 25;                    // Cantidad de bloques de datos

void fragment() {
    vec2 uv = UV;
    float time = TIME * speed;
    
    // Inicializamos el color en negro absoluto con ALFA EN CERO (Transparente)
    vec4 final_color = vec4(0.0);
    
    // ==========================================
    // 1. CÁLCULO DE LAS HEBRAS PRINCIPALES (ADN)
    // ==========================================
    
    // Hebra A
    float angleA = uv.x * frequency + time;
    float yA = 0.5 + sin(angleA) * amplitude;
    float zA = cos(angleA); // Profundidad (-1 fondo, 1 frente)
    
    // Hebra B (Desfasada PI para la doble hélice)
    float angleB = uv.x * frequency + time + 3.141592;
    float yB = 0.5 + sin(angleB) * amplitude;
    float zB = cos(angleB);
    
    // Grosores dinámicos por profundidad
    float thicknessA = 0.006 + (zA + 1.0) * 0.006;
    float thicknessB = 0.006 + (zB + 1.0) * 0.006;
    
    float distA = abs(uv.y - yA);
    float distB = abs(uv.y - yB);
    
    float strandA = smoothstep(thicknessA, 0.0, distA);
    float strandB = smoothstep(thicknessB, 0.0, distB);
    
    // Brillo por profundidad
    float glowA = smoothstep(thicknessA * 4.0, 0.0, distA) * (0.3 + (zA + 1.0) * 0.3);
    float glowB = smoothstep(thicknessB * 4.0, 0.0, distB) * (0.3 + (zB + 1.0) * 0.3);
    
    // Oclusión (una tapa a la otra)
    if (zA > zB) {
        strandB *= smoothstep(0.01, 0.04, abs(yA - yB));
    } else {
        strandA *= smoothstep(0.01, 0.04, abs(yA - yB));
    }
    
    // Sumamos las hebras al contenedor de color
    final_color += (strandA * strand_color) + (glowA * strand_color * 0.5);
    final_color += (strandB * strand_color) + (glowB * strand_color * 0.5);
    
    // ==========================================
    // 2. BLOQUES DE MEMORIA CONECTORES
    // ==========================================
    
    float block_strip = fract(uv.x * float(block_density));
    float block_trigger = step(0.6, block_strip); 
    
    float top_y = min(yA, yB);
    float bottom_y = max(yA, yB);
    
    if (uv.y > top_y && uv.y < bottom_y && block_trigger > 0.0) {
        float block_center_x = (floor(uv.x * float(block_density)) + 0.5) / float(block_density);
        float block_angle = block_center_x * frequency + time;
        float block_z = cos(block_angle); 
        
        float block_fade = (block_z + 1.2) / 2.2;
        float glitch = step(0.15, sin(block_center_x * 123.45 + time * 4.0) * cos(block_center_x * 456.78 - time * 2.0));
        
        if (glitch > 0.0) {
            float byte_texture = step(0.3, fract(uv.y * 40.0));
            float final_block = byte_texture * block_fade;
            final_color += vec4(final_block) * block_color * 0.7;
        }
    }
    
    // ==========================================
    // 3. TRANSPARENCIA (AQUÍ ESTÁ LA MAGIA)
    // ==========================================
    // Asignamos el color RGB calculado
    COLOR.rgb = final_color.rgb;
    
    // El alfa (la opacidad) será igual a la intensidad del brillo de nuestro ADN.
    // Usamos el valor más alto entre los canales de color para determinar el alfa de forma limpia.
    COLOR.a = max(final_color.r, max(final_color.g, final_color.b));
}