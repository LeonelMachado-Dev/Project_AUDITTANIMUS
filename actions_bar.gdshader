shader_type canvas_item;

// --- Configuracion Animus 1000x60 (Sin cortes duros) ---
uniform vec2 resolucion_barra = vec2(1000.0, 40.0);
uniform vec4 color_barra : source_color = vec4(0.85, 0.90, 0.93, 0.18);        // Gris traslucido continuo
uniform vec4 color_bloques_datos : source_color = vec4(0.95, 0.98, 1.0, 0.38); // Bloques de la simulacion
uniform vec4 color_linea_guia : source_color = vec4(0.0, 0.75, 0.85, 0.8);     // Vector cian clasico

// Control del degradado de la transicion (en pixeles)
uniform float inicio_degradado_px : hint_range(0.0, 1000.0) = 550.0; // Comienza a desvanecerse la zona lisa
uniform float fin_degradado_px : hint_range(0.0, 1000.0) = 800.0;    // Los bloques toman el control total
uniform float velocidad_procesamiento : hint_range(1.0, 20.0) = 7.0;

// Dimensiones de los bloques de memoria
uniform vec2 tamano_bloque_px = vec2(12.0, 5.0);
uniform vec2 separacion_bloque_px = vec2(2.0, 2.0);

// Generador de matriz con antialiasing
float calcular_bloque_nitido(vec2 pixel_coords, float tiempo) {
    vec2 periodo_bloque = tamano_bloque_px + separacion_bloque_px;
    vec2 id_bloque = floor(pixel_coords / periodo_bloque);
    vec2 uv_local_bloque = mod(pixel_coords, periodo_bloque);
    
    float aleatorio = fract(sin(dot(id_bloque, vec2(12.9898, 78.233))) * 43758.5453);
    float estado_bloque = step(0.35, sin(aleatorio * tiempo));
    
    vec2 limites = smoothstep(tamano_bloque_px, tamano_bloque_px - vec2(0.5), uv_local_bloque);
    return limites.x * limites.y * estado_bloque;
}

void fragment() {
    vec2 posicion_pixel = UV * resolucion_barra;
    float t = TIME * velocidad_procesamiento;
    
    // Limite general del rectangulo entero (1px de margen para limpieza de bordes)
    float mascara_rectangulo = step(1.0, posicion_pixel.y) * step(posicion_pixel.y, resolucion_barra.y - 1.0) * step(1.0, posicion_pixel.x) * step(posicion_pixel.x, resolucion_barra.x - 1.0);
    
    // 1. CALCULAR EL DEGRADADO SUAVE HORIZONTAL (Transicion del Animus)
    // Retorna 0.0 a la izquierda (completamente liso) y 1.0 a la derecha (completamente fragmentado)
    float factor_transicion = smoothstep(inicio_degradado_px, fin_degradado_px, posicion_pixel.x);
    
    // 2. GENERAR LA MATRIZ DE BLOQUES ANIMADOS
    float patron_bloques = calcular_bloque_nitido(posicion_pixel, t);
    
    // Mezcla de colores en base al degradado:
    // A la izquierda mantiene el gris solido. En el medio se fusionan. A la derecha dominan los bloques.
    vec4 color_zona_fija = color_barra;
    vec4 color_zona_animada = mix(color_barra * 0.25, color_bloques_datos, patron_bloques);
    
    // Fusion final aplicada a todo el rectangulo unico
    vec4 color_final = mix(color_zona_fija, color_zona_animada, factor_transicion);
    color_final *= mascara_rectangulo;
    
    // 3. DETALLES VECTORIALES SUPERIORES E INFERIORES NITI DOS
    float linea_superior = step(posicion_pixel.y, 1.5) * step(0.5, posicion_pixel.y);
    float linea_inferior = step(resolucion_barra.y - 1.5, posicion_pixel.y) * step(posicion_pixel.y, resolucion_barra.y - 0.5);
    
    // El vector cian corre continuo por abajo y se desvanece suavemente junto con el degradado del fondo
    float pulso = sin(TIME * 2.5) * 0.1 + 0.9;
    float vector_activo = linea_inferior * (1.0 - factor_transicion);
    
    // Acoplamos las lineas estructurales del HUD al render
    color_final = mix(color_final, color_barra * 1.6, (max(linea_superior, linea_inferior) * mascara_rectangulo));
    color_final = mix(color_final, color_linea_guia * pulso, vector_activo * mascara_rectangulo);

    COLOR = color_final;
}