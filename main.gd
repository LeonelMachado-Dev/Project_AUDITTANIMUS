extends Control

@onready var fondo = $Background
@onready var neblina = $NeblinaAnimus
@onready var contenedor_tarjetas = $Interface/MenuSujetos/ContenedorTarjetas
@onready var click_effect = $click_effect
@onready var pop_up_confirmacion = $PopUpConfirmacion
@onready var delete_btn = $Interface/delete_subjectBtn
@onready var estado_borrar_label = $Interface/status
@onready var label_BG = $Interface/Label_BG
@onready var edit_btn = $Interface/edit_subjectBtn
var tiempo_ultimo_giro : float = 0.0
var lista_filtrada = [] #Esto servira para que se guarde solo las tarjetas filtradas, una caja temporal de las tarjetas mientras se filtran.
var escena_entrada = preload("res://entrada_sujeto.tscn")
var modo_borrar_activo: bool = false
var tarjeta_a_eliminar = null 
enum EstadoInterfaz { NORMAL, MODO_PURGA, ESPERANDO_CONFIRMACION, MODO_EDICION }
var estado_actual = EstadoInterfaz.NORMAL
# --- CARRUSEL -----------------------------------------------------------------
var lista_instancias = []    
var indice_central = 0       
var espacio_horizontal = 340 
var escala_fondo = 0.65       
var opacidad_fondo = 0.25

# --- arrow animation ---
@onready var flecha_izquierda = $Interface/leftBtn  # Ajusta la ruta exacta de tu nodo
@onready var flecha_derecha = $Interface/rightBtn   # Ajusta la ruta exacta de tu nodo

# Variables de posición original declaradas correctamente para solucionar los errores
var pos_original_flecha_izq: Vector2
var pos_original_flecha_der: Vector2
var tween_izq: Tween
var tween_der: Tween
# --- SOLUCIÓN CRÍTICA: PROPIEDADES DE AISLAMIENTO DE ANIMACIÓN ---
# Animamos estas variables en lugar de la posición física del nodo para no corromper los anclajes de Godot
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
#-------------------------------------------------------------------------------

func _ready():
	label_BG.visible = false
	ajustar_pantalla_animus()
	indice_central = Global.indice_carrusel_guardado
	llenar_lista()
	
	if pop_up_confirmacion:
		pop_up_confirmacion.get_ok_button().text = "SÍ, ELIMINAR"
		pop_up_confirmacion.get_cancel_button().text = "NO, CANCELAR"
		
		if not pop_up_confirmacion.confirmed.is_connected(_on_borrado_confirmado):
			pop_up_confirmacion.confirmed.connect(_on_borrado_confirmado)
		if not pop_up_confirmacion.canceled.is_connected(_on_borrado_cancelado):
			pop_up_confirmacion.canceled.connect(_on_borrado_cancelado)
	
	if delete_btn and not delete_btn.pressed.is_connected(_on_delete_subject_btn_pressed):
		delete_btn.pressed.connect(_on_delete_subject_btn_pressed)
		
	if edit_btn and not edit_btn.pressed.is_connected(_on_edit_subject_btn_pressed):
		edit_btn.pressed.connect(_on_edit_subject_btn_pressed)
		
	get_tree().root.size_changed.connect(ajustar_pantalla_animus)
	
	# Forzamos una espera de un frame para asegurarnos de que el layout inicial sea el correcto
	await get_tree().process_frame
	reiniciar_posiciones_referencia()

func ajustar_pantalla_animus():
	var screen_size = get_viewport_rect().size
	if fondo: fondo.size = screen_size
	if neblina: neblina.size = screen_size
	if contenedor_tarjetas: contenedor_tarjetas.position = screen_size / 2
	
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

# --- INTERCEPTOR CRÍTICO DE ENTRADA ---
func _on_tarjeta_pulsada_en_carrusel(tarjeta_pulsada):
	if lista_filtrada.find(tarjeta_pulsada) != indice_central:
		return

	match estado_actual:
		EstadoInterfaz.NORMAL:
			if tarjeta_pulsada.has_method("cambiar_a_detalles"):
				tarjeta_pulsada.cambiar_a_detalles()
				
		EstadoInterfaz.MODO_PURGA:
			tarjeta_a_eliminar = tarjeta_pulsada
			var nombre = tarjeta_pulsada.datos_sujeto.get("nombre", "Desconocido")
			var apellido = tarjeta_pulsada.datos_sujeto.get("apellido", "Desconocido")
			
			if pop_up_confirmacion:
				pop_up_confirmacion.dialog_text = "¿Estás seguro de querer borrar al sujeto " + nombre.to_upper() + " " + apellido.to_upper() + " de la base de datos?"
				pop_up_confirmacion.popup_centered()
				
		EstadoInterfaz.MODO_EDICION:
			# Guardamos el ID en el Autoload Global
			Global.sujeto_seleccionado_id = tarjeta_pulsada.datos_sujeto["id"]
			print("[SISTEMA] Preparando edición para el sujeto ID: ", Global.sujeto_seleccionado_id)
			
			# ¡ATENCIÓN! Asegúrate de que esta sea la ruta correcta a tu escena de editar/añadir
			get_tree().change_scene_to_file("res://subject_editor.tscn")

func llenar_lista():
	for child in contenedor_tarjetas.get_children():
		child.queue_free()
	lista_instancias.clear()

	var sujetos = DB.obtener_sujetos()
	for s in sujetos:
		var nueva_tarjeta = escena_entrada.instantiate()
		contenedor_tarjetas.add_child(nueva_tarjeta)
		nueva_tarjeta.configurar(s)
		
		# Forzamos a que intercepte ANTES el script principal
		nueva_tarjeta.pressed.connect(func(): _on_tarjeta_pulsada_en_carrusel(nueva_tarjeta))
		nueva_tarjeta.pressed.connect(Global.reproducir_tick)
		
		lista_instancias.append(nueva_tarjeta)
	
	lista_filtrada = lista_instancias.duplicate()
	actualizar_posiciones_carrusel(false)

func _on_delete_subject_btn_pressed() -> void:
	Global.reproducir_tick()
	if estado_actual == EstadoInterfaz.NORMAL:
		estado_actual = EstadoInterfaz.MODO_PURGA
		
		if estado_borrar_label:
			estado_borrar_label.text = tr("KEY_MODO_BORRAR")
			estado_borrar_label.modulate = Color("ff4d47ff")
			
		if label_BG:
			label_BG.visible = true
	else:
		estado_actual = EstadoInterfaz.NORMAL
		restablecer_interfaz_borrar()
		
func _on_edit_subject_btn_pressed() -> void:
	Global.reproducir_tick()
	if estado_actual == EstadoInterfaz.NORMAL:
		estado_actual = EstadoInterfaz.MODO_EDICION
		if label_BG:
			label_BG.visible = true
		if estado_borrar_label:
			estado_borrar_label.text = tr("KEY_MODO_EDITAR")
			estado_borrar_label.modulate = Color("54d2faff")
	else:
		estado_actual = EstadoInterfaz.NORMAL
		restablecer_interfaz_borrar()

# --- RESPUESTAS DEL POP-UP (SÍ / NO) ---
func _on_borrado_confirmado():
	Global.reproducir_tick()
	if tarjeta_a_eliminar and tarjeta_a_eliminar.datos_sujeto.has("id"):
		var id_sujeto = tarjeta_a_eliminar.datos_sujeto["id"]
		DB.eliminar_sujeto(id_sujeto)
		print("Sujeto eliminado con éxito del registro.")
		
		# Limpiamos el modo borrado
		estado_actual = EstadoInterfaz.NORMAL
		restablecer_interfaz_borrar()
		
		if indice_central >= lista_filtrada.size() - 1 and indice_central > 0:
			indice_central -= 1
			
		llenar_lista()
	tarjeta_a_eliminar = null

func _on_borrado_cancelado():
	Global.reproducir_tick()
	print("Operación cancelada de forma segura.")
	estado_actual = EstadoInterfaz.NORMAL
	restablecer_interfaz_borrar()
	tarjeta_a_eliminar = null

func restablecer_interfaz_borrar():
	if estado_borrar_label:
		estado_borrar_label.text = ""
	label_BG.visible = false

# --- ENTRADAS GENERALES DEL CARRUSEL ---
func _unhandled_input(event: InputEvent) -> void:
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	if tiempo_actual - tiempo_ultimo_giro < 0.25: return
	
	if event.is_action_pressed("ui_left_animus"):
		tiempo_ultimo_giro = tiempo_actual
		_on_left_btn_pressed()
	elif event.is_action_pressed("ui_right_animus"):
		tiempo_ultimo_giro = tiempo_actual
		_on_right_btn_pressed()

func _on_browser_text_changed(nuevo_texto: String) -> void:
	lista_filtrada.clear()
	var texto_buscar = nuevo_texto.strip_edges().to_lower()
	for tarjeta in lista_instancias:
		var nombre_completo = (tarjeta.datos_sujeto.get("nombre", "") + " " + tarjeta.datos_sujeto.get("apellido", "")).to_lower()
		if texto_buscar == "" or texto_buscar in nombre_completo:
			tarjeta.visible = true
			lista_filtrada.append(tarjeta)
		else:
			tarjeta.visible = false
	if lista_filtrada.size() > 0:
		indice_central = clampi(indice_central, 0, lista_filtrada.size() - 1)
	else:
		indice_central = 0
	actualizar_posiciones_carrusel(true)

func actualizar_posiciones_carrusel(animado: bool = true):
	var total_elementos = lista_filtrada.size()
	if total_elementos == 0: return
	for i in range(total_elementos):
		var tarjeta = lista_filtrada[i]
		var distancia_al_centro = i - indice_central
		var limite_mitad = float(total_elementos) / 2.0
		if distancia_al_centro > limite_mitad: distancia_al_centro -= total_elementos
		elif distancia_al_centro < -limite_mitad: distancia_al_centro += total_elementos
		var destino_x = distancia_al_centro * espacio_horizontal
		var destino_y = abs(distancia_al_centro) * 30 
		var factor_escala = max(1.0 - (abs(distancia_al_centro) * (1.0 - escala_fondo)), escala_fondo)
		var factor_opacidad = max(1.0 - (abs(distancia_al_centro) * (1.0 - opacidad_fondo)), opacidad_fondo)
		tarjeta.z_index = 10 - abs(distancia_al_centro)
		tarjeta.disabled = (distancia_al_centro != 0)
		if animado:
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var posicion_final = Vector2(destino_x, destino_y) - (tarjeta.size * factor_escala / 2)
			tween.tween_property(tarjeta, "position", posicion_final, 0.4)
			tween.tween_property(tarjeta, "scale", Vector2(factor_escala, factor_escala), 0.4)
			tween.tween_property(tarjeta, "modulate:a", factor_opacidad, 0.4)
		else:
			var tarjeta_size = tarjeta.size if "size" in tarjeta else Vector2.ZERO
			tarjeta.scale = Vector2(factor_escala, factor_escala)
			tarjeta.position = Vector2(destino_x, destino_y) - (tarjeta_size * factor_escala / 2)
			tarjeta.modulate.a = factor_opacidad

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
		
func _on_back_btn_pressed() -> void:
	Global.reproducir_tick()
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_add_subject_btn_pressed() -> void:
	Global.reproducir_tick()
	
	# Forzamos el reinicio de seguridad. 0 significa "Nuevo Registro"
	Global.sujeto_seleccionado_id = 0 
	print("[SISTEMA] Abriendo el editor en modo: CREAR NUEVO SUJETO")
	
	get_tree().change_scene_to_file("res://subject_editor.tscn")

func _on_right_btn_pressed() -> void:
	if lista_filtrada.size() == 0: return

	if flecha_derecha and flecha_derecha.has_focus():
		flecha_derecha.release_focus()
		
	indice_central = (indice_central + 1) % lista_filtrada.size()
	actualizar_posiciones_carrusel(true)
	
	if flecha_derecha:
		if tween_der: tween_der.kill()
		offset_dinamico_der = Vector2.ZERO
		
		# Animamos el rebote elástico usando la variable global de control 'tween_der'
		tween_der = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_der.tween_property(self, "offset_dinamico_der", Vector2.ZERO, 0.25).from(Vector2(20, 0))
		tween_der.tween_callback(iniciar_bucle_flechas)

func _on_left_btn_pressed():
	if lista_filtrada.size() == 0: return

	if flecha_izquierda and flecha_izquierda.has_focus():
		flecha_izquierda.release_focus()
		
	indice_central = (indice_central - 1 + lista_filtrada.size()) % lista_filtrada.size()
	actualizar_posiciones_carrusel(true)
	
	if flecha_izquierda:
		if tween_izq: tween_izq.kill()
		offset_dinamico_izq = Vector2.ZERO
		
		# Animamos el rebote elástico usando la variable global de control 'tween_izq'
		tween_izq = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_izq.tween_property(self, "offset_dinamico_izq", Vector2.ZERO, 0.25).from(Vector2(-20, 0))
		tween_izq.tween_callback(iniciar_bucle_flechas)
