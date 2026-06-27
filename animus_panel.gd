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
#------------------------------------------------------------
@export_category("Referencias")
@export var columna_scene: PackedScene = preload("res://animus_columns.tscn")

@onready var contenedor_columnas: Control = $ColumnsContainer
@onready var contenedor_datos: Control = $ColumnsContainer/infoContainer

var bloques_columnas: Array[ColorRect] = []
var tiempo: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		generar_panel(false)
	else:
		if contenedor_datos:
			contenedor_datos.modulate.a = 0.0
		generar_panel(true)

func generar_panel(con_animacion: bool = true) -> void:
	# 1. TRUCO CRUCIAL: Esperamos un frame a que los contenedores calculen el tamaño real
	if not is_inside_tree(): 
		await ready
	else:
		await get_tree().process_frame
		
	if not contenedor_columnas: return
		
	for hijo in contenedor_columnas.get_children():
		hijo.queue_free()
	bloques_columnas.clear()
	
	# 2. Si el tamaño sigue dando 0 por el contenedor, usamos el mínimo asignado
	var tamano_actual = self.size
	if tamano_actual.x <= 0 or tamano_actual.y <= 0:
		tamano_actual = self.custom_minimum_size
		
	# Si todo falla, no dejamos que rompa en división por 0
	if tamano_actual.x <= 0: tamano_actual = Vector2(603, 300)
	
	var ancho_columna = tamano_actual.x / total_columnas
	
	for i in range(total_columnas):
		if not columna_scene: return
		var nueva_columna = columna_scene.instantiate() as ColorRect

		nueva_columna.size = Vector2(ancho_columna + 0.5, tamano_actual.y)
		nueva_columna.position = Vector2(i * ancho_columna, 0)
		nueva_columna.modulate.a = 0.0 if con_animacion else 1.0

		contenedor_columnas.add_child(nueva_columna)
		bloques_columnas.append(nueva_columna)

	if con_animacion and not Engine.is_editor_hint():
		animar_entrada()

func animar_entrada() -> void:
	# El Tween en paralelo procesa todo al mismo tiempo usando sus propios retrasos (delays)
	var tween = create_tween().set_parallel(true)
	
	# 1. Animamos la construcción de las barras una a una
	for i in range(bloques_columnas.size()):
		var delay = i * retraso_entre_columnas
		tween.tween_property(bloques_columnas[i], "modulate:a", 1.0, duracion_aparicion_columna)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)
			
	# 2. Animamos el texto de forma independiente controlando su aparición exacta
	var texto_nodo = get_node_or_null("TextoContenido")
	if texto_nodo:
		texto_nodo.modulate.a = 0.0
		# Al NO usar .chain(), corre en paralelo y se dispara exactamente en el segundo configurado
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
