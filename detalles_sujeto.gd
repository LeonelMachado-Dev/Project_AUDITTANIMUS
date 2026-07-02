extends Control

@onready var nombre_label = $HBoxContainer/InfoDerecha/NombreLabel
@onready var birth_year_label = $HBoxContainer/InfoDerecha/birthYear_label
@onready var location_label = $HBoxContainer/InfoDerecha/location_label
@onready var texto_contenido = $HBoxContainer/InfoDerecha/AnimusPanel/TextoContenido
@onready var FotoSujeto = $HBoxContainer/ColumnaIzquierda/FotoSujeto
@onready var glitch_timer = $GlitchTimer
@onready var glitch_sound = $GlitchSound
@onready var animus_panel: PanelAnimus = $HBoxContainer/InfoDerecha/AnimusPanel
@onready var contenedor_datos: Control = $HBoxContainer/InfoDerecha/AnimusPanel/ColumnsContainer/infoContainer
@onready var psycoBtn = $HBoxContainer/ColumnaIzquierda/ContenedorBotones/BtnPsico
@onready var BioBtn = $HBoxContainer/ColumnaIzquierda/ContenedorBotones/BtnBio

var datos_sujeto = {}
var posicion_original_foto : Vector2

func _ready():
	glitch_timer.timeout.connect(_on_glitch_timer_timeout)
	glitch_timer.wait_time = randf_range(3.0, 7.0)
	
	var id_elegido = Global.sujeto_seleccionado_id
	var consulta = "SELECT * FROM sujetos WHERE id = " + str(id_elegido)
	DB.db.query(consulta)
	
	if DB.db.query_result.size() > 0:
		datos_sujeto = DB.db.query_result[0]
		
		if is_instance_valid(texto_contenido):
			texto_contenido.modulate.a = 0.0
		if is_instance_valid(animus_panel):
			animus_panel.generar_panel(true)
			
		# Inicializamos toda la interfaz del sujeto de una sola vez
		subject_picture()
		basic_subject_info()
		
		# Por defecto, abrimos mostrando la biografía
		biography()

func _animar_y_esperar_boton(boton: Button) -> void:
	if not is_instance_valid(boton): return
	boton.pivot_offset = boton.size / 2
	var tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(0.92, 0.92), 0.02).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(boton, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

# --- AHORA ESTO TIENE SENTIDO: Llena solo las etiquetas fijas ---
func basic_subject_info():
	nombre_label.visible_ratio = 0.0
	nombre_label.text = (datos_sujeto["nombre"] + " " + datos_sujeto["apellido"]).to_upper()
	
	birth_year_label.visible_ratio = 1.0
	birth_year_label.text = (tr("KEY_BIRTH_YEAR") + " " + datos_sujeto["birth_year"])
	
	location_label.visible_ratio = 1.0
	location_label.text = (tr("KEY_COMMON_LOCATION") + " " + datos_sujeto["ubicacion_frecuente"]).to_upper()
	
	animar_titulo()

# --- ESPECÍFICO: Solo cambia el cuadro central por la Biografía ---
func biography():
	texto_contenido.visible_ratio = 1.0 
	texto_contenido.bbcode_enabled = true
	texto_contenido.clear()
	
	var bio_txt = str(datos_sujeto.get("descripcion", "")).strip_edges()
	texto_contenido.append_text(bio_txt)

# --- ESPECÍFICO: Solo cambia el cuadro central por el Análisis ---
func psyco_analyse():
	texto_contenido.visible_ratio = 1.0 
	texto_contenido.bbcode_enabled = true
	texto_contenido.clear()
	
	var analisis_txt = str(datos_sujeto.get("analisis_detallado", "")).strip_edges()
	
	if analisis_txt == "" or analisis_txt == "null" or analisis_txt == "<null>":
		texto_contenido.append_text("[color=#b33a3a]ESTE SUJETO NO TIENE ANALISIS DETALLADO[/color]")
	else:
		texto_contenido.append_text(analisis_txt)

func subject_picture():
	var ruta_foto = str(datos_sujeto.get("imagen_path", "")) 
	if ruta_foto != "" and ruta_foto != "null" and FileAccess.file_exists(ruta_foto):
		var img = Image.load_from_file(ruta_foto)
		if img:
			var textura_externa = ImageTexture.create_from_image(img)
			FotoSujeto.texture = textura_externa
			animar_foto()
		else:
			FotoSujeto.texture = preload("res://Images/TEST SUBJECTS/no_foto.png")
	else:
		FotoSujeto.texture = preload("res://Images/TEST SUBJECTS/no_foto.png")

func animar_titulo():
	var tween = create_tween()
	tween.tween_property(nombre_label, "visible_ratio", 1.0, 0.6).set_trans(Tween.TRANS_LINEAR)
	
func animar_foto():
	FotoSujeto.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(FotoSujeto, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_BOUNCE)

func _on_glitch_timer_timeout():
	ejecutar_glitch()
	glitch_timer.wait_time = randf_range(4.0, 10.0)
	glitch_timer.start()

func ejecutar_glitch():
	if glitch_sound.stream:
		glitch_sound.play()
	
	posicion_original_foto = FotoSujeto.global_position
	if not FotoSujeto.texture: return

	FotoSujeto.visible = false
	var contenedor_glitch = Control.new()
	add_child(contenedor_glitch)
	contenedor_glitch.global_position = posicion_original_foto
	
	var tamano_textura_real = FotoSujeto.texture.get_size()
	var alto_total_ui = FotoSujeto.size.y
	var tiras_creadas = []
	var y_actual_ui = 0.0
	
	while y_actual_ui < alto_total_ui:
		var alto_tira_ui = randf_range(8.0, 55.0) 
		if y_actual_ui + alto_tira_ui > alto_total_ui:
			alto_tira_ui = alto_total_ui - y_actual_ui
			
		var proporcion_y = y_actual_ui / alto_total_ui
		var proporcion_alto = alto_tira_ui / alto_total_ui
		var y_textura = proporcion_y * tamano_textura_real.y
		var alto_textura = proporcion_alto * tamano_textura_real.y
		
		if alto_tira_ui <= 1.0: break
			
		var tira = TextureRect.new()
		contenedor_glitch.add_child(tira)
		
		var atlas_tira = AtlasTexture.new()
		atlas_tira.atlas = FotoSujeto.texture
		atlas_tira.region = Rect2(0, y_textura, tamano_textura_real.x, alto_textura)
		
		tira.texture = atlas_tira
		tira.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tira.stretch_mode = TextureRect.STRETCH_SCALE
		tira.size = Vector2(FotoSujeto.size.x, alto_tira_ui)
		tira.texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST
		tira.position = Vector2(0, y_actual_ui)
		tiras_creadas.append(tira)
		y_actual_ui += alto_tira_ui

	var tween = create_tween().set_parallel(true)
	for i in range(4):
		var tiempo_vibracion = 0.03 * i
		var desfase_vibracion = Vector2(randf_range(-14.0, 14.0), randf_range(-12.0, 12.0))
		tween.tween_property(contenedor_glitch, "global_position", posicion_original_foto + desfase_vibracion, 0.03).set_delay(tiempo_vibracion)
	
	for tira in tiras_creadas:
		if randf() > 0.4:
			var desgarro_compresion = randf_range(-120.0, 120.0)
			tween.tween_property(tira, "position:x", tira.position.x + desgarro_compresion, 0.07)
			tween.tween_property(tira, "scale:x", randf_range(1.4, 2.0), 0.05).set_delay(0.07)
			var color_virus = [Color(0.1, 4.0, 4.0), Color(4.0, 0.1, 4.0), Color(5.0, 5.0, 0.1)].pick_random()
			tween.tween_property(tira, "modulate", color_virus, 0.07)
		else:
			tween.tween_property(tira, "modulate", Color(2.5, 2.5, 2.5, 0.8), 0.05)

	var tween_limpieza = create_tween()
	tween_limpieza.tween_interval(0.15)
	tween_limpieza.finished.connect(func():
		FotoSujeto.visible = true
		contenedor_glitch.queue_free()
	)

# --- LAS SEÑALES AHORA QUEDAN IMPECABLES ---
func _on_btn_bio_pressed():
	await _animar_y_esperar_boton(BioBtn)
	biography()

func _on_btn_psico_pressed():
	await _animar_y_esperar_boton(psycoBtn)
	psyco_analyse()

func _on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
