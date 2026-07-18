extends Control

@onready var fondo = $Background
@onready var neblina = $NeblinaAnimus
@onready var placesCarrousel = $Interface/PlacesCarrousel
@onready var AddBtn = $Interface/addPlacesBtn
@onready var EditBtn = $Interface/editPlacesBtn
@onready var DeleteBtn = $Interface/deletePlacesBtn
@onready var BackBtn = $Interface/backBtn

# --- arrow animation -------------------------------------------------------------------
@onready var flecha_izquierda = $Interface/leftBtn  # Ajusta la ruta exacta de tu nodo
@onready var flecha_derecha = $Interface/rightBtn   # Ajusta la ruta exacta de tu nodo

# Variables de posición original declaradas correctamente para solucionar los errores
var pos_original_flecha_izq: Vector2
var pos_original_flecha_der: Vector2
var tween_izq: Tween
var tween_der: Tween

var offset_dinamico_izq: Vector2 = Vector2.ZERO:
	set(val):
		offset_dinamico_izq = val
		if is_instance_valid(flecha_izquierda):
			flecha_izquierda.position = pos_original_flecha_izq + offset_dinamico_izq

var offset_dinamico_der: Vector2 = Vector2.ZERO:
	set(val):
		offset_dinamico_der = val
		if is_instance_valid(flecha_derecha):
			flecha_derecha.position = pos_original_flecha_der + offset_dinamico_der
#-------------------------------------------------------------------------------------
func _ready() -> void:
	ajustar_pantalla_animus()
	get_tree().root.size_changed.connect(ajustar_pantalla_animus)
	
	# Forzamos una espera de un frame para asegurarnos de que el layout inicial sea el correcto
	await get_tree().process_frame
	reiniciar_posiciones_referencia()
	
	if AddBtn:
		AddBtn.text = tr("KEY_AÑADIR_SUJETOS")
		
	if EditBtn:
		EditBtn.text = tr("KEY_EDITAR_SUJETOS")
		
	if DeleteBtn:
		DeleteBtn.text = tr("KEY_BORRAR_SUJETOS")
		
	if BackBtn:
		BackBtn.text = tr("KEY_REGRESAR")
		
func ajustar_pantalla_animus():
	var screen_size = get_viewport_rect().size
	if fondo: fondo.size = screen_size
	if neblina: neblina.size = screen_size
	if placesCarrousel: placesCarrousel.position = screen_size / 2
	
	# 1. Matamos inmediatamente cualquier tween en curso (de flotación o de clics)
	if tween_izq: tween_izq.kill()
	if tween_der: tween_der.kill()
	
	# 2. Reseteamos los offsets dinámicos a cero.
	offset_dinamico_izq = Vector2.ZERO
	offset_dinamico_der = Vector2.ZERO
	
	# --- REPOSITORIO FORZADO DE FLECHAS EN SUS RESPECTIVOS LATERALES ---
	var margen_lateral = 50.0 # Sube este número para meter las flechas más hacia el centro, bájalo para pegarlas al borde.
	
	if flecha_izquierda:
		var alto_izq = flecha_izquierda.size.y if "size" in flecha_izquierda else 0.0
		flecha_izquierda.position = Vector2(margen_lateral, (screen_size.y / 2) - (alto_izq / 2))
		
	if flecha_derecha:
		var ancho_der = flecha_derecha.size.x if "size" in flecha_derecha else 0.0
		var alto_der = flecha_derecha.size.y if "size" in flecha_derecha else 0.0
		flecha_derecha.position = Vector2(screen_size.x - margen_lateral - ancho_der, (screen_size.y / 2) - (alto_der / 2))
	
	# 3. Esperamos de forma segura un cuadro a que el motor procese los cambios
	await get_tree().process_frame
	
	# 4. Capturamos las nuevas referencias físicas estables y reiniciamos los bucles suaves
	reiniciar_posiciones_referencia()
	
func reiniciar_posiciones_referencia():
	# Guardamos la posición limpia calculada por código dinámicamente
	if flecha_izquierda: pos_original_flecha_izq = flecha_izquierda.position
	if flecha_derecha: pos_original_flecha_der = flecha_derecha.position
	
	# Iniciamos los bucles de flotación desde la nueva base estable
	iniciar_bucle_flechas()
	
func iniciar_bucle_flechas():
	if tween_izq: tween_izq.kill()
	if tween_der: tween_der.kill()

	# Reseteamos los desfases internos para empezar el bucle limpios
	offset_dinamico_izq = Vector2.ZERO
	offset_dinamico_der = Vector2.ZERO

	# --- BUCLE FLECHA IZQUIERDA (Animando propiedad aislada) ---
	if flecha_izquierda:
		tween_izq = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_izq.tween_property(self, "offset_dinamico_izq", Vector2(-12, 0), 0.8)
		tween_izq.tween_property(self, "offset_dinamico_izq", Vector2.ZERO, 0.8)

	# --- BUCLE FLECHA DERECHA (Animando propiedad aislada) ---
	if flecha_derecha:
		tween_der = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_der.tween_property(self, "offset_dinamico_der", Vector2(12, 0), 0.8)
		tween_der.tween_property(self, "offset_dinamico_der", Vector2.ZERO, 0.8)
		
func _animar_y_esperar_boton(boton: Button) -> void:
	if not is_instance_valid(boton): return
	
	# Aseguramos el pivote en el centro
	boton.pivot_offset = boton.size / 2
	
	var tween = create_tween()
	
	# 1. Se encoge de forma ultra inmediata (0.02 segundos)
	tween.tween_property(boton, "scale", Vector2(0.92, 0.92), 0.02)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# 2. Vuelve al tamaño original rápido con un golpe firme (0.08 segundos)
	tween.tween_property(boton, "scale", Vector2.ONE, 0.08)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	# Espera total de solo 0.1 segundos antes de hacer la acción
	await tween.finished


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_btn_pressed() -> void:
	Global.reproducir_tick()
	get_tree().change_scene_to_file("res://main_menu.tscn")
