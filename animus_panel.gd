@tool
class_name PanelAnimus
extends Control

enum ModoColor { SOLIDO, DEGRADADO }

@export_category("Configuración de la Onda")
@export var total_columnas: int = 24:
	set(valor):
		total_columnas = valor
		generar_panel(false)

@export var velocidad_onda: float = 3.0
@export var frecuencia_onda: float = 0.05
@export var amplitud_onda: float = 12.0

@export_category("Tiempos de Animación")
@export var retraso_entre_columnas: float = 0.05
@export var duracion_aparicion_columna: float = 0.2
@export var duracion_aparicion_texto: float = 0.5
@export var tiempo_espera_texto: float = 1.1

@export_category("Personalización Visual")
@export var tipo_de_color: ModoColor = ModoColor.SOLIDO:
	set(valor):
		tipo_de_color = valor
		_actualizar_estilos_en_vivo()

@export var color_de_columnas: Color = Color("5a5a5a"):
	set(valor):
		color_de_columnas = valor
		_actualizar_estilos_en_vivo()

@export var degradado_panel: GradientTexture2D:
	set(valor):
		degradado_panel = valor
		_conectar_senales_degradado()
		_actualizar_estilos_en_vivo()

@export var opacidad_maxima_columnas: float = 1.0:
	set(valor):
		opacidad_maxima_columnas = clamp(valor, 0.0, 1.0)
		_actualizar_estilos_en_vivo()

@export var separacion_columnas: float = 1.0:
	set(valor):
		separacion_columnas = valor
		_actualizar_estilos_en_vivo()

@export var color_bordes_escena: Color = Color("a61c2e"):
	set(valor):
		color_bordes_escena = valor
		_actualizar_estilos_en_vivo()

@export_category("Referencias")
@export var columna_scene: PackedScene = preload("res://animus_columns.tscn")

@onready var contenedor_columnas: Control = $ColumnsContainer
@onready var contenedor_datos: Control = $ColumnsContainer/infoContainer

var bloques_columnas: Array[ColorRect] = []
var tiempo: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		if not item_rect_changed.is_connected(_actualizar_en_editor):
			item_rect_changed.connect(_actualizar_en_editor)
		_conectar_senales_degradado()
		generar_panel(false)
	else:
		if contenedor_datos:
			contenedor_datos.modulate.a = 0.0
		generar_panel(true)

func generar_panel(con_animacion: bool = true) -> void:
	if not contenedor_columnas:
		contenedor_columnas = get_node_or_null("ColumnsContainer")
	if not contenedor_columnas: return
	
	for hijo in contenedor_columnas.get_children():
		if Engine.is_editor_hint():
			hijo.free()
		else:
			hijo.queue_free()
			
	bloques_columnas.clear()
	
	var tamano_actual = self.size
	if tamano_actual.x <= 1.0 or tamano_actual.y <= 1.0:
		if self.custom_minimum_size.x > 0:
			tamano_actual = self.custom_minimum_size
		else:
			tamano_actual = Vector2(603, 300)
			if Engine.is_editor_hint():
				self.size = tamano_actual
	
	var ancho_disponible = tamano_actual.x
	var ancho_columna = ancho_disponible / total_columnas
	
	for i in range(total_columnas):
		var nueva_columna: ColorRect
		if columna_scene:
			nueva_columna = columna_scene.instantiate() as ColorRect
		else:
			nueva_columna = ColorRect.new()
		
		var pos_x = floor(i * ancho_columna)
		var siguiente_pos_x = floor((i + 1) * ancho_columna)
		var ancho_real_barra = (siguiente_pos_x - pos_x) - separacion_columnas
		
		nueva_columna.size = Vector2(ancho_real_barra, tamano_actual.y)
		nueva_columna.position = Vector2(pos_x, 0)
		nueva_columna.visible = true
		
		if con_animacion and not Engine.is_editor_hint():
			nueva_columna.modulate.a = 0.0
		
		contenedor_columnas.add_child(nueva_columna)
		bloques_columnas.append(nueva_columna)

	_actualizar_estilos_en_vivo()

	if con_animacion and not Engine.is_editor_hint():
		animar_entrada()

func animar_entrada() -> void:
	var tween = create_tween().set_parallel(true)
	
	for i in range(bloques_columnas.size()):
		var delay = i * retraso_entre_columnas
		tween.tween_property(bloques_columnas[i], "modulate:a", opacidad_maxima_columnas, duracion_aparicion_columna)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
	var texto_nodo = get_node_or_null("TextoContenido")
	if texto_nodo:
		texto_nodo.modulate.a = 0.0
		tween.tween_property(texto_nodo, "modulate:a", 1.0, duracion_aparicion_texto)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_delay(tiempo_espera_texto)

func _process(delta: float) -> void:
	tiempo += delta
	var tamano_actual = self.size if self.size.x > 1.0 else self.custom_minimum_size
	var ancho_columna = tamano_actual.x / (total_columnas if total_columnas > 0 else 1)
	
	for i in range(bloques_columnas.size()):
		var columna = bloques_columnas[i]
		if is_instance_valid(columna):
			var pos_x = floor(i * ancho_columna)
			var desajuste_fase = pos_x * frecuencia_onda
			var desplazamiento_y = sin((tiempo * velocidad_onda) - desajuste_fase) * amplitud_onda
			
			columna.position.x = pos_x
			columna.position.y = desplazamiento_y

func _actualizar_estilos_en_vivo() -> void:
	var tamano_actual = self.size if self.size.x > 1.0 else self.custom_minimum_size
	var ancho_columna = tamano_actual.x / (total_columnas if total_columnas > 0 else 1)
	
	if contenedor_columnas:
		contenedor_columnas.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	
	for i in range(bloques_columnas.size()):
		var columna = bloques_columnas[i]
		if is_instance_valid(columna):
			var pos_x = floor(i * ancho_columna)
			var siguiente_pos_x = floor((i + 1) * ancho_columna)
			var ancho_real_barra = (siguiente_pos_x - pos_x) - separacion_columnas
			columna.size.x = ancho_real_barra
			
			if tipo_de_color == ModoColor.SOLIDO:
				columna.color = color_de_columnas
			elif tipo_de_color == ModoColor.DEGRADADO and degradado_panel and degradado_panel.gradient:
				var ratio_x = float(i) / float(bloques_columnas.size() - 1 if bloques_columnas.size() > 1 else 1)
				
				var f_from = degradado_panel.fill_from
				var f_to = degradado_panel.fill_to
				var direccion = f_to - f_from
				
				var factor = 0.0
				if direccion.length_squared() > 0.001:
					var punto_actual = Vector2(ratio_x, 0.5)
					factor = (punto_actual - f_from).dot(direccion) / direccion.length_squared()
				
				var porcentaje_final = clamp(factor, 0.0, 1.0)
				columna.color = degradado_panel.gradient.sample(porcentaje_final)
			else:
				columna.color = color_de_columnas
			
			if Engine.is_editor_hint():
				columna.modulate.a = opacidad_maxima_columnas
			
			# --- SOLUCIÓN CON NOMBRES EXACTOS (MINÚSCULAS) ---
			var top_border = columna.get_node_or_null("topBorder")
			if top_border:
				if "color" in top_border: top_border.color = color_bordes_escena
				top_border.modulate = color_bordes_escena
				
			var bottom_border = columna.get_node_or_null("bottomBorder")
			if bottom_border:
				if "color" in bottom_border: bottom_border.color = color_bordes_escena
				bottom_border.modulate = color_bordes_escena

func _conectar_senales_degradado() -> void:
	if not degradado_panel: return
	
	if not degradado_panel.changed.is_connected(_actualizar_estilos_en_vivo):
		degradado_panel.changed.connect(_actualizar_estilos_en_vivo)
		
	if degradado_panel.gradient:
		if not degradado_panel.gradient.changed.is_connected(_actualizar_estilos_en_vivo):
			degradado_panel.gradient.changed.connect(_actualizar_estilos_en_vivo)

func _actualizar_en_editor() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		generar_panel(false)
