shader_type canvas_item;

void fragment() {
    vec2 grid_uv = UV * vec2(80.0, 10.0); // Columnas y filas de la rejilla
    vec2 grid = abs(fract(grid_uv - 0.5) - 0.5) / fwidth(grid_uv);
    float line = min(grid.x, grid.y);
    float grid_pattern = 1.0 - min(line, 1.0);
    
    // Color azul Animus muy oscuro y sutil para el fondo
    vec4 bg_color = vec4(0.02, 0.05, 0.1, 0.6); 
    vec4 grid_color = vec4(0.1, 0.3, 0.5, 0.15); // Rejilla casi transparente
    
    COLOR = mix(bg_color, grid_color, grid_pattern);
}