shader_type canvas_item;

// Color de la neblina (gris azulado muy suave)
uniform vec4 smoke_color : source_color = vec4(0.85, 0.9, 0.95, 0.15);

// Generador de ruido para la neblina
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Suavizado del ruido (Perlin-ish)
float smooth_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    // Velocidad del flujo de datos/neblina
    vec2 uv = UV * 3.0; 
    float t = TIME * 0.1;
    
    // Capas de movimiento para profundidad
    float n = smooth_noise(uv + t);
    n += smooth_noise(uv * 2.0 - t * 0.5) * 0.5;
    n += smooth_noise(uv * 4.0 + t * 0.2) * 0.25;
    
    // Aplicar el color con el ruido
    float final_alpha = n * smoke_color.a;
    COLOR = vec4(smoke_color.rgb, final_alpha);
}