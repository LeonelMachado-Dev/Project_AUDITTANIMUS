@tool
class_name PanelAnimus
extends Control

@export_category("Configuración de la Onda")
@export var total_columnas: int = 24
@export var velocidad_onda: float = 3.0
@export var frecuencia_onda: float = 0.05
@export var amplitud_onda: float = 12.0
# --- NUEVAS VARIABLES PARA CONTROLAR EL TIEMPO ---
@export_category("Tiempos de Animación")
@export var retraso_entre_columnas: float = 0.05  # Qué tan rápido se van construyendo (menor = más rápido)
@export var duracion_aparicion_columna: float = 0.2 # Cuánto tarda cada barra individual en pasar de invisible a opaca
@export var duracion_aparicion_texto: float = 0.5  # Cuánto tarda el texto en aparecer suavemente al final
@export var tiempo_espera_texto: float = 1.1        # <-- NUEVA: El segundo exacto donde arranca el texto

# --- NUEVA CATEGORÍA DE PERSONALIZACIÓN VISUAL ---
@export_category("Personalización Visual")
@export var color_de_columnas: Color = Color("5a5a5a") # Color base (puedes cambiarlo en el inspector)
@export var opacidad_maxima_columnas: float = 1.0     # 1.0 = Sólido, 0.5 = Semitransparente, etc.
#------------------------------------------------------------
@export_category("Referencias")
@export var columna_scene: PackedScene = preload("res://animus_columns.tscn")

@onready var contenedor_columnas: Control = $ColumnsContainer
@onready var contenedor_datos: Control = $ColumnsContainer/infoContainer

var bloques_columnas: Array[ColorRect] = []
var tiempo: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		# En el editor, conectamos una señal para que se redibuje si reajustas el tamaño de la ventana
		if not item_rect_changed.is_connected(_actualizar_en_editor):
			item_rect_changed.connect(_actualizar_en_editor)
		generar_panel(false)
	else:
		# JUEGO REAL: Forzamos la limpieza y construcción limpia desde cero
		if contenedor_datos:
			contenedor_datos.modulate.a = 0.0
		generar_panel(true)

func generar_panel(con_animacion: bool = true) -> void:
	# 1. Seguridad de carga de referencias
	if not contenedor_columnas:
		contenedor_columnas = get_node_or_null("ColumnsContainer")
	if not contenedor_columnas: return
		
	# 2. ESPERA CRUCIAL (Solo en el juego real)
	if not Engine.is_editor_hint():
		if not is_inside_tree(): 
			await ready
		else:
			await get_tree().process_frame
			await get_tree().process_frame # Doble frame para asegurar que la UI despertó del modo editor
	
	# 3. LIMPIEZA ADAPTATIVA
	# En el editor usamos free() para liberar memoria en vivo; en el juego queue_free() para evitar crasheos
	for hijo in contenedor_columnas.get_children():
		if Engine.is_editor_hint():
			hijo.free()
		else:
			hijo.queue_free()
			
	bloques_columnas.clear()
	
	# 4. CÁLCULO DE TAMAÑO
	var tamano_actual = self.size
	if tamano_actual.x <= 0 or tamano_actual.y <= 0:
		tamano_actual = self.custom_minimum_size
		
	if tamano_actual.x <= 0: tamano_actual = Vector2(603, 300)
	
	var ancho_columna = tamano_actual.x / total_columnas
	
	# 5. INSTANCIACIÓN
	for i in range(total_columnas):
		var nueva_columna: ColorRect
		if columna_scene:
			nueva_columna = columna_scene.instantiate() as ColorRect
		else:
			nueva_columna = ColorRect.new()
		
		nueva_columna.size = Vector2(ancho_columna + 0.5, tamano_actual.y)
		nueva_columna.position = Vector2(i * ancho_columna, 0)
		nueva_columna.color = color_de_columnas
		nueva_columna.visible = true
		
		# Si estamos en el editor, se ven con su opacidad final. En el juego, inician en 0.0 para el Tween
		if Engine.is_editor_hint():
			nueva_columna.modulate.a = opacidad_maxima_columnas
		else:
			nueva_columna.modulate.a = 0.0 if con_animacion else opacidad_maxima_columnas

		contenedor_columnas.add_child(nueva_columna)
		bloques_columnas.append(nueva_columna)

	# 6. DISPARO DE ANIMACIÓN (Solo en el juego)
	if con_animacion and not Engine.is_editor_hint():
		animar_entrada()

func animar_entrada() -> void:
	var tween = create_tween().set_parallel(true)
	
	for i in range(bloques_columnas.size()):
		var delay = i * 0.04
		# --- CORREGIDO: En vez de forzar a 1.0, animamos hasta 'opacidad_maxima_columnas' ---
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
	for i in range(bloques_columnas.size()):
		var columna = bloques_columnas[i]
		if is_instance_valid(columna):
			var desajuste_fase = columna.position.x * frecuencia_onda
			var desplazamiento_y = sin((tiempo * velocidad_onda) - desajuste_fase) * amplitud_onda
			columna.position.y = desplazamiento_y
			
# Función de soporte para redibujar en el editor sin romper nada
func _actualizar_en_editor() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		generar_panel(false)
