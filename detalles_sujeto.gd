extends Control

@onready var nombre_label = $HBoxContainer/InfoDerecha/NombreLabel
@onready var birth_year_label = $HBoxContainer/InfoDerecha/birthYear_label
@onready var location_label = $HBoxContainer/InfoDerecha/location_label
@onready var texto_contenido = $HBoxContainer/InfoDerecha/TextoContenido
@onready var FotoSujeto = $HBoxContainer/ColumnaIzquierda/FotoSujeto
@onready var glitch_timer = $GlitchTimer
@onready var glitch_sound = $GlitchSound

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
		mostrar_datos("descripcion")
		
	

func mostrar_datos(columna):
	texto_contenido.visible_ratio = 1.0 
	texto_contenido.bbcode_enabled = true
	
	# 1. Limpiamos por completo la caja para eliminar el mensaje de error anterior
	texto_contenido.clear()
	
	# 2. Inyectamos la biografía de forma limpia
	texto_contenido.append_text(str(datos_sujeto.get(columna, "")))
	
	# El resto de tu animación de cabecera sigue igual
	nombre_label.visible_ratio = 0.0
	nombre_label.text = (datos_sujeto["nombre"] + " " + datos_sujeto["apellido"]).to_upper()
	birth_year_label.visible_ratio = 1.0
	birth_year_label.text = ("AÑO DE NACIMIENTO:" + " " + datos_sujeto["birth_year"])
	location_label.visible_ratio = 1.0
	location_label.text = ("LOCALIZACION FRECUENTE:" + " " + datos_sujeto["ubicacion_frecuente"]).to_upper()
	animar_titulo()
	
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
		
func mostrar_analisis():
	texto_contenido.visible_ratio = 1.0 
	
	# Convertimos a string de forma segura y limpiamos espacios invisibles
	var analisis_txt = str(datos_sujeto.get("analisis_detallado", "")).strip_edges()
	texto_contenido.clear()
	# Validamos de manera exhaustiva todas las representaciones que SQLite da para campos vacíos
	if analisis_txt == "" or analisis_txt == "null" or analisis_txt == "<null>":
		texto_contenido.append_text("[color=#b33a3a]ESTE SUJETO NO TIENE ANALISIS DETALLADO[/color]")
	else:
		texto_contenido.text = analisis_txt

func animar_titulo():
	# Solo animamos el Label del nombre
	var tween = create_tween()
	tween.tween_property(nombre_label, "visible_ratio", 1.0, 0.6).set_trans(Tween.TRANS_LINEAR)
	
func animar_foto():
	FotoSujeto.modulate.a = 0
	var tween = create_tween()
	# Hace un pequeño parpadeo rápido
	tween.tween_property(FotoSujeto, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_BOUNCE)

func _on_glitch_timer_timeout():
	# Ejecutamos el efecto visual y sonoro
	ejecutar_glitch()
	
	# Cambiamos el próximo tiempo de espera para que sea impredecible (entre 4 y 10 segundos)
	glitch_timer.wait_time = randf_range(4.0, 10.0)
	glitch_timer.start()

func ejecutar_glitch():
	# 1. Sonido de error de señal
	if glitch_sound.stream:
		glitch_sound.play()
	
	posicion_original_foto = FotoSujeto.global_position

	if not FotoSujeto.texture:
		return

	# Ocultamos la foto original para procesar la distorsión analógica
	FotoSujeto.visible = false
	
	# Contenedor libre en la raíz para evitar restricciones del HBoxContainer
	var contenedor_glitch = Control.new()
	add_child(contenedor_glitch)
	contenedor_glitch.global_position = posicion_original_foto
	
	var tamano_textura_real = FotoSujeto.texture.get_size()
	var alto_total_ui = FotoSujeto.size.y
	
	# --- GENERACIÓN DE CORTES ASIMÉTRICOS (Efecto JPEG/Señal Corrupta) ---
	var tiras_creadas = []
	var y_actual_ui = 0.0
	
	# En lugar de usar un bucle 'for' fijo, usamos un 'while' para crear tiras de tamaños caóticos
	while y_actual_ui < alto_total_ui:
		# Unas tiras serán líneas milimétricas de estática y otras bloques enormes congelados
		var alto_tira_ui = randf_range(8.0, 55.0) 
		
		# Aseguramos que la última tira no se pase del borde inferior
		if y_actual_ui + alto_tira_ui > alto_total_ui:
			alto_tira_ui = alto_total_ui - y_actual_ui
			
		# Calculamos la proporción matemática correspondiente en la textura real
		var proporcion_y = y_actual_ui / alto_total_ui
		var proporcion_alto = alto_tira_ui / alto_total_ui
		
		var y_textura = proporcion_y * tamano_textura_real.y
		var alto_textura = proporcion_alto * tamano_textura_real.y
		
		# Si el fragmento es demasiado pequeño para procesarse, saltamos
		if alto_tira_ui <= 1.0:
			break
			
		# Creación del bloque defectuoso
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
		
		# Colocamos la tira en su altura correspondiente
		tira.position = Vector2(0, y_actual_ui)
		tiras_creadas.append(tira)
		
		# Avanzamos la posición para el siguiente corte
		y_actual_ui += alto_tira_ui

	# 2. ANIMACIÓN EN PARALELO (Vibración de máquina + Desgarro JPEG)
	var tween = create_tween().set_parallel(true)
	
	# --- EFECTO VIBRACIÓN (Jitter / Shake de alta frecuencia) ---
	# La imagen completa salta caóticamente de posición simulando pérdida de sincronismo
	for i in range(4):
		var tiempo_vibracion = 0.03 * i
		var desfase_vibracion = Vector2(randf_range(-14.0, 14.0), randf_range(-12.0, 12.0))
		tween.tween_property(contenedor_glitch, "global_position", posicion_original_foto + desfase_vibracion, 0.03).set_delay(tiempo_vibracion)
	
	# --- EFECTO ARRASTRE DE PÍXEL (Datamoshing) ---
	for tira in tiras_creadas:
		# Solo algunas tiras sufrirán el arrastre severo de señal, emulando la compresión rota
		if randf() > 0.4:
			# Desplazamiento horizontal agresivo hacia un lado
			var desgarro_compresion = randf_range(-120.0, 120.0)
			tween.tween_property(tira, "position:x", tira.position.x + desgarro_compresion, 0.07)
			
			# En la fase 2 (contragolpe), estiramos el bloque simulando el "barrido" de bits corruptos
			tween.tween_property(tira, "scale:x", randf_range(1.4, 2.0), 0.05).set_delay(0.07)
			
			# Modulación cromática extrema (Colores fluorescentes quemados típicos del fallo de video)
			var color_virus = [Color(0.1, 4.0, 4.0), Color(4.0, 0.1, 4.0), Color(5.0, 5.0, 0.1)].pick_random()
			tween.tween_property(tira, "modulate", color_virus, 0.07)
		else:
			# Las tiras que no se desplazan tanto, hacen un pequeño parpadeo de brillo (estática limpia)
			tween.tween_property(tira, "modulate", Color(2.5, 2.5, 2.5, 0.8), 0.05)

	# 3. RESTAURACIÓN DEL SISTEMA
	var tween_limpieza = create_tween()
	# Duración exacta del micro-corte de señal (0.15 segundos)
	tween_limpieza.tween_interval(0.15)
	
	tween_limpieza.finished.connect(func():
		FotoSujeto.visible = true
		contenedor_glitch.queue_free()
	)

# CONECTA ESTAS SEÑALES EN EL PANEL "NODO" DE CADA BOTÓN:
func _on_btn_bio_pressed():
	mostrar_datos("descripcion")

func _on_btn_psico_pressed():
	# Si no tienes columna 'perfil' en tu DB todavía, te dará error. 
	# Asegúrate de que el nombre coincida con tu columna de SQLite
	mostrar_analisis()

func _on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
