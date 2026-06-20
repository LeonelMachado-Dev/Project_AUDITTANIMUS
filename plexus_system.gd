extends Node2D

# -- CONFIGURACIÓN VISUAL PULIDA --
@export var num_points: int = 75            # Cantidad de nodos
@export var point_color: Color = Color(0.74, 0.812, 0.87, 0.894) # Azul Animus
@export var line_color: Color = Color(0.63, 0.79, 0.87, 0.4)  # Con opacidad media
@export var max_distance: float = 200.0     # Radio de conexión aumentado
@export var point_size: float = 4.0         # Puntos más grandes (antes 2.0)
@export var line_width: float = 2.0         # Líneas más gruesas (antes 1.0)
@export var min_speed: float = 12.0
@export var max_speed: float = 28.0

# -- VARIABLES INTERNAS --
var points = [] 
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	
	# Generar puntos iniciales
	for i in range(num_points):
		var pos = Vector2(randf() * screen_size.x, randf() * screen_size.y)
		var angle = randf() * PI * 2
		var speed = randf_range(min_speed, max_speed)
		var vel = Vector2(cos(angle) * speed, sin(angle) * speed)
		points.append({"pos": pos, "vel": vel})
		
	get_tree().root.size_changed.connect(func(): screen_size = get_viewport_rect().size)

func _process(delta):
	# Movimiento y rebote sutil en bordes
	for p in points:
		p.pos += p.vel * delta
		if p.pos.x < 0 or p.pos.x > screen_size.x: p.vel.x *= -1
		if p.pos.y < 0 or p.pos.y > screen_size.y: p.vel.y *= -1
			
	queue_redraw() # Solicita llamar a _draw()

func _draw():
	# Dibujar las conexiones (Líneas)
	for i in range(num_points):
		var p1 = points[i]
		
		for j in range(i + 1, num_points):
			var p2 = points[j]
			var dist = p1.pos.distance_to(p2.pos)
			
			if dist < max_distance:
				# Efecto de desvanecimiento por distancia
				var alpha_factor = 1.0 - (dist / max_distance)
				var final_color = line_color
				final_color.a *= alpha_factor
				
				# DIBUJAR LÍNEA CON EL NUEVO GROSOR
				draw_line(p1.pos, p2.pos, final_color, line_width)
		
		# DIBUJAR EL PUNTO (NODO)
		draw_circle(p1.pos, point_size, point_color)
