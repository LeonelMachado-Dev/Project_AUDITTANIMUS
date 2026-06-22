extends Control

const RUTA_CONFIG = "user://config_animus.cfg"

@onready var fondo = $Background
@onready var neblina = $NeblinaAnimus
@onready var pila_cuadros = $interface/PillarBlocks
@onready var contenedor_botones = $interface/buttonsContainer
@onready var panel_disclaimer = $DisclaimerPanel
@onready var boton_aceptar_disclaimer = $DisclaimerPanel/VisorContainer/AcceptBtn
@onready var visor_container = $DisclaimerPanel/VisorContainer

# Configuración estética estilo AC2
var color_gris_animus = Color("5a5a5a", 0.6)
var color_rojo_animus = Color("a61c2e", 0.9)
var cuadros_nodos = [] 
var velocidad_movimiento: float = 2.0  
var amplitud_movimiento: float = 8.0   
var linea_conectora: Line2D
var indice_boton_actual: int = -1

# Botones principales
@onready var subjectsBtn = $interface/buttonsContainer/subjectsBtn
@onready var locationsBtn = $interface/buttonsContainer/lugaresBtn
@onready var memoriesBtn = $interface/buttonsContainer/memoriesBtn
@onready var editorBtn = $interface/buttonsContainer/EditorBtn
@onready var exitBtn = $interface/buttonsContainer/exitBtn

# --- AUDIO & PANEL NODES ---
@onready var panel_sonido = $interface/soundPanel 
@onready var slider_musica = $interface/soundPanel/soundSlider 
@onready var sfx_check_btn = $interface/soundPanel/sfxCheckButton
@onready var btn_cargar_cancion = $interface/soundPanel/load_musicBtn 
@onready var defaultMusicBtn = $interface/soundPanel/defaultMusicBtn
@onready var returnBtn = $interface/soundPanel/returnBtn
@onready var file_dialog_musica = $interface/FileDialogMusic 

# --- SISTEMA DE PANEL DINÁMICO ANIMUS V3 (Columnas Ondulantes AC2) ---
var panel_animus_activo: Control
var bloques_cuerpo_animus: Array[ColorRect] = []
var scroll_creditos_animus: ScrollContainer
var velocidad_onda_animus: float = 3.0     # Velocidad del flujo de la onda
var frecuencia_onda_animus: float = 0.05   # Controla qué tan "ondulado" se ve horizontalmente
var amplitud_onda_animus: float = 12.0     # Cuánto suben y bajan los rectángulos (el relieve)
var velocidad_scroll_creditos: float = 30.0
var label_salir_animus: Label
var tiempo_parpadeo: float = 0.0
var usuario_scrolleando: bool = false
var tiempo_inactividad_scroll: float = 0.0
var scroll_acumulado: float = 0.0

# --- ELEMENTOS CREADOS POR CÓDIGO ---
var visualizador_padre: Control
var circulo_album: Panel
var icono_nota: Label
var rectangulos_giro = []
var panel_texto_cancion: Panel
var label_nombre_cancion: Label
var anillo_giro_padre: Control
var posicion_oculto: Vector2
var posicion_visible: Vector2
var mouse_sobre_visualizador: bool = false
var sfx_permitido: bool = true
var detector_mouse_estatico: Control        
var velocidad_texto: float = 45.0           
var limite_izquierdo_texto: float = 0.0     

enum EstadosMenu { PRINCIPAL, EDICION, SONIDO }
var estado_actual = EstadosMenu.PRINCIPAL

func _ready():
	inicializar_linea_conectora()
	crear_visualizador_animus_dinamico()
	cargar_preferencias_usuario()
	ajustar_pantalla_menu()
	get_tree().root.size_changed.connect(ajustar_pantalla_menu)
	construir_pila_bloques()
	vincular_eventos_botones()
	inicializar_sistema_audio()
	
	if panel_sonido: panel_sonido.visible = false
	chequear_primer_inicio()
	ir_a_menu_principal()
	
func ajustar_pantalla_menu():
	var screen_size = get_viewport_rect().size
	if fondo: fondo.size = screen_size
	if neblina: neblina.size = screen_size
	
	if panel_disclaimer:
		panel_disclaimer.size = screen_size
		
	if visor_container:
		var centro_x = (screen_size.x / 2.0) - (visor_container.size.x / 2.0)
		var centro_y = (screen_size.y / 2.0) - (visor_container.size.y / 2.0)
		visor_container.global_position = Vector2(centro_x, centro_y)
		
	if pila_cuadros:
		pila_cuadros.global_position = Vector2(120, 0)
		
	if contenedor_botones:
		contenedor_botones.global_position = Vector2(340, screen_size.y * 0.35)
		
	if panel_sonido:
		panel_sonido.global_position = Vector2(550, screen_size.y * 0.28)
	
	if visualizador_padre:
		posicion_visible = Vector2(screen_size.x - visualizador_padre.size.x, screen_size.y - visualizador_padre.size.y - 15)
		posicion_oculto = Vector2(screen_size.x - 135, screen_size.y - visualizador_padre.size.y - 15)
		visualizador_padre.global_position = posicion_visible if mouse_sobre_visualizador else posicion_oculto
		
	if detector_mouse_estatico:
		detector_mouse_estatico.size = Vector2(350, 160)
		detector_mouse_estatico.global_position = Vector2(screen_size.x - 150, screen_size.y - 160)

func inicializar_linea_conectora():
	linea_conectora = Line2D.new()
	add_child(linea_conectora)
	linea_conectora.width = 1.5
	linea_conectora.default_color = color_rojo_animus
	linea_conectora.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	linea_conectora.visible = false 

func crear_visualizador_animus_dinamico():
	detector_mouse_estatico = Control.new()
	detector_mouse_estatico.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(detector_mouse_estatico)
	
	visualizador_padre = Control.new()
	visualizador_padre.size = Vector2(480, 90) 
	visualizador_padre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visualizador_padre)
	
	var x_offset = 100
	
	circulo_album = Panel.new()
	circulo_album.size = Vector2(60, 60)
	circulo_album.position = Vector2(15 + x_offset, 15)
	circulo_album.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	var estilo_circulo = StyleBoxFlat.new()
	estilo_circulo.corner_radius_top_left = 30
	estilo_circulo.corner_radius_top_right = 30
	estilo_circulo.corner_radius_bottom_left = 30
	estilo_circulo.corner_radius_bottom_right = 30
	estilo_circulo.bg_color = Color("1a1a1a", 0.85)
	estilo_circulo.border_width_left = 2
	estilo_circulo.border_width_top = 2
	estilo_circulo.border_width_right = 2
	estilo_circulo.border_width_bottom = 2
	estilo_circulo.border_color = color_rojo_animus
	circulo_album.add_theme_stylebox_override("panel", estilo_circulo)
	visualizador_padre.add_child(circulo_album)
	
	icono_nota = Label.new()
	icono_nota.text = "♪"
	icono_nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono_nota.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icono_nota.size = circulo_album.size
	icono_nota.add_theme_color_override("font_color", Color.WHITE)
	icono_nota.add_theme_font_size_override("font_size", 24)
	icono_nota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circulo_album.add_child(icono_nota)
	
	anillo_giro_padre = Control.new()
	anillo_giro_padre.position = circulo_album.position + (circulo_album.size / 2.0)
	anillo_giro_padre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visualizador_padre.add_child(anillo_giro_padre)
	
	var radio_orbita = 36.0 
	var total_fragmentos = 8
	for i in range(total_fragmentos):
		var angulo_radianes = (i * (PI * 2.0 / total_fragmentos))
		var fragmento = ColorRect.new()
		fragmento.size = Vector2(12, 3)
		fragmento.color = color_rojo_animus
		fragmento.color.a = randf_range(0.5, 0.9)
		fragmento.pivot_offset = fragmento.size / 2.0
		fragmento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var posX = cos(angulo_radianes) * radio_orbita
		var posY = sin(angulo_radianes) * radio_orbita
		fragmento.position = Vector2(posX, posY) - fragmento.pivot_offset
		fragmento.rotation = angulo_radianes + (PI / 2.0)
		anillo_giro_padre.add_child(fragmento)
		
	panel_texto_cancion = Panel.new()
	panel_texto_cancion.size = Vector2(280, 40)
	panel_texto_cancion.position = Vector2(90 + x_offset, 25)
	panel_texto_cancion.clip_contents = true 
	panel_texto_cancion.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	var estilo_texto_panel = StyleBoxFlat.new()
	estilo_texto_panel.bg_color = color_gris_animus
	estilo_texto_panel.border_width_left = 3
	estilo_texto_panel.border_color = color_rojo_animus
	panel_texto_cancion.add_theme_stylebox_override("panel", estilo_texto_panel)
	visualizador_padre.add_child(panel_texto_cancion)
	
	label_nombre_cancion = Label.new()
	label_nombre_cancion.autowrap_mode = TextServer.AUTOWRAP_OFF
	label_nombre_cancion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_nombre_cancion.size = Vector2(2000, 40)
	label_nombre_cancion.position = Vector2(15, 0)
	label_nombre_cancion.add_theme_font_size_override("font_size", 13)
	label_nombre_cancion.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	panel_texto_cancion.add_child(label_nombre_cancion)
	
	detector_mouse_estatico.mouse_entered.connect(_on_visualizador_mouse_entered)
	detector_mouse_estatico.mouse_exited.connect(_on_visualizador_mouse_exited)
	
func cargar_preferencias_usuario():
	var config = ConfigFile.new()
	if config.load(RUTA_CONFIG) == OK:
		# --- NUEVA LÓGICA: CARGAR IDIOMA GUARDADO ---
		var idioma_guardado = config.get_value("Localization", "idioma", "")
		if idioma_guardado != "":
			TranslationServer.set_locale(idioma_guardado)
			print("[SISTEMA] Idioma cargado desde la configuración: ", idioma_guardado)
		
		var vol_guardado = config.get_value("Audio", "volumen_musica", 80.0)
		if slider_musica: slider_musica.value = vol_guardado
		_on_volume_slider_changed(vol_guardado)
		
		Global.sfx_permitido = config.get_value("Audio", "sfx_activado", true)
		if sfx_check_btn: sfx_check_btn.button_pressed = Global.sfx_permitido
		
		var ultima_pista = config.get_value("Audio", "ruta_origen_musica", "")
		actualizar_interfaz_visualizador(ultima_pista)
	else:
		if sfx_check_btn: sfx_check_btn.button_pressed = Global.sfx_permitido
		actualizar_interfaz_visualizador("")

func guardar_preferencia(seccion: String, clave: String, valor: Variant):
	var config = ConfigFile.new()
	config.load(RUTA_CONFIG)
	config.set_value(seccion, clave, valor)
	config.save(RUTA_CONFIG)
	
# --- MOTOR DE AUDIO DINÁMICO ---
func inicializar_sistema_audio():
	if slider_musica:
		slider_musica.value_changed.connect(_on_volume_slider_changed)
		
	if sfx_check_btn:
		sfx_check_btn.toggled.connect(_on_sfx_toggled)
		
	if btn_cargar_cancion and file_dialog_musica:
		btn_cargar_cancion.pressed.connect(func(): file_dialog_musica.popup_centered(Vector2(700, 500)))
		file_dialog_musica.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog_musica.access = FileDialog.ACCESS_FILESYSTEM 
		file_dialog_musica.file_selected.connect(_on_musica_seleccionada_dialog)
		file_dialog_musica.filters = ["*.mp3 ; Archivos MP3", "*.ogg ; Archivos OGG"]
		
	if defaultMusicBtn:
		defaultMusicBtn.pressed.connect(_on_restaurar_musica_defecto)
		
	if returnBtn:
		returnBtn.pressed.connect(func():
			ejecutar_sfx_tick()
			ir_a_modo_edicion()
		)

	# ¡MAGIA AQUÍ! Solo cargamos/reproducimos si el Autoload NO está reproduciendo nada.
	# Al volver de "Sujetos", la canción ya estará sonando, por lo que ignorará esto y seguirá fluida.
	if not Global.music_player.playing:
		cargar_musica_guardada()
	
func ejecutar_sfx_tick():
	if sfx_permitido:
		Global.reproducir_tick()
	
func cargar_musica_guardada():
	var ruta_mp3 = "user://animus_background.mp3"
	var ruta_ogg = "user://animus_background.ogg"
	
	var ruta_final = ""
	if FileAccess.file_exists(ruta_mp3): ruta_final = ruta_mp3
	elif FileAccess.file_exists(ruta_ogg): ruta_final = ruta_ogg
	
	if ruta_final != "":
		var archivo = FileAccess.open(ruta_final, FileAccess.READ)
		if archivo:
			var bytes = archivo.get_buffer(archivo.get_length())
			var stream
			
			# Lógica limpia sin duplicados
			if ruta_final.get_extension() == "mp3":
				stream = AudioStreamMP3.new()
				stream.data = bytes
				stream.loop = true
			else:
				stream = AudioStreamOggVorbis.load_from_buffer(bytes)
				if stream:
					stream.loop = true
					
			if stream:
				Global.set_track(stream)
				print("[Audio Animus] Pista personalizada cargada y reproduciéndose.")
	else:
		if not Global.music_player.playing:
			_on_restaurar_musica_defecto()
			print("[Audio Animus] Usando pista de fondo por defecto.")

func _on_volume_slider_changed(value: float):
	var db = linear_to_db(value / 100.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, db)
	guardar_preferencia("Audio", "volumen_musica", value)
	
func _on_sfx_toggled(button_pressed: bool):
	Global.sfx_permitido = button_pressed
	guardar_preferencia("Audio", "sfx_activado", button_pressed)
	Global.reproducir_tick()
	
func _on_musica_seleccionada_dialog(path: String):
	ejecutar_sfx_tick()
	
	var extension = path.get_extension().to_lower()
	var destino = "user://animus_background." + extension
	
	var extension_alterna = "ogg" if extension == "mp3" else "mp3"
	var archivo_viejo = "user://animus_background." + extension_alterna
	if FileAccess.file_exists(archivo_viejo):
		DirAccess.remove_absolute(archivo_viejo)
	
	if FileAccess.file_exists(destino):
		DirAccess.remove_absolute(destino)

	var error = DirAccess.copy_absolute(path, destino)
	if error == OK:
		guardar_preferencia("Audio", "ruta_origen_musica", path)
		actualizar_interfaz_visualizador(path)
		cargar_musica_guardada() 
	else:
		print("[Error] No se pudo copiar el archivo...")

func _on_restaurar_musica_defecto():
	ejecutar_sfx_tick()
	
	var path_mp3 = "user://animus_background.mp3"
	var path_ogg = "user://animus_background.ogg"
	
	if FileAccess.file_exists(path_mp3): DirAccess.remove_absolute(path_mp3)
	if FileAccess.file_exists(path_ogg): DirAccess.remove_absolute(path_ogg)
	
	guardar_preferencia("Audio", "ruta_origen_musica", "")
	actualizar_interfaz_visualizador("")
	
	var stream_original = load("res://music/animus2.0_theme.mp3")
	Global.set_track(stream_original)
	
func actualizar_interfaz_visualizador(ruta_archivo: String):
	if not is_instance_valid(label_nombre_cancion) or label_nombre_cancion == null: 
		return
		
	# Reemplazamos los strings fijos por tr() para que reaccionen al instante
	if ruta_archivo == "":
		label_nombre_cancion.text = tr("KEY_REPRODUCIENDO_DEFECTO")
	else:
		var nombre_limpio = ruta_archivo.get_file().get_basename()
		label_nombre_cancion.text = tr("KEY_REPRODUCIENDO_PERSONAL") + " " + nombre_limpio + " — "
		
	label_nombre_cancion.position.x = 15
	
	var fuente = label_nombre_cancion.get_theme_font("font")
	var t_size = 13
	if label_nombre_cancion.has_theme_font_size_override("font_size"):
		t_size = label_nombre_cancion.get_theme_font_size("font_size")
		
	if fuente:
		var string_size = fuente.get_string_size(label_nombre_cancion.text, HORIZONTAL_ALIGNMENT_LEFT, -1, t_size)
		limite_izquierdo_texto = -string_size.x
	else:
		limite_izquierdo_texto = -400.0
		
	ajustar_pantalla_menu()
		
func _on_visualizador_mouse_entered():
	mouse_sobre_visualizador = true
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(visualizador_padre, "global_position", posicion_visible, 0.4)

func _on_visualizador_mouse_exited():
	mouse_sobre_visualizador = false
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(visualizador_padre, "global_position", posicion_oculto, 0.5)
		
func chequear_primer_inicio():
	if Global.disclaimer_ya_mostrado:
		panel_disclaimer.visible = false
		contenedor_botones.visible = true
		pila_cuadros.visible = true
		ir_a_menu_principal()
	else:
		panel_disclaimer.visible = true
		contenedor_botones.visible = false
		linea_conectora.visible = false
		pila_cuadros.visible = true
		
		if not boton_aceptar_disclaimer.pressed.is_connected(_on_disclaimer_aceptado):
			boton_aceptar_disclaimer.pressed.connect(_on_disclaimer_aceptado)
		
func _on_disclaimer_aceptado():
	Global.reproducir_tick()
	Global.disclaimer_ya_mostrado = true 
	panel_disclaimer.visible = false
	contenedor_botones.visible = true
	ir_a_menu_principal()
	
func ir_a_menu_principal():
	estado_actual = EstadosMenu.PRINCIPAL
	if panel_sonido: panel_sonido.visible = false
	contenedor_botones.visible = true
	
	# we use tr() to look in real-time the translate
	subjectsBtn.text = tr("KEY_SUJETOS")
	locationsBtn.text = tr("KEY_LUGARES")
	memoriesBtn.text = tr("KEY_RECUERDOS")
	editorBtn.text = tr("KEY_OPCIONES")
	exitBtn.text = tr("KEY_SALIR")
	
func ir_a_modo_edicion():
	estado_actual = EstadosMenu.EDICION
	if panel_sonido: panel_sonido.visible = false
	contenedor_botones.visible = true
	
	subjectsBtn.text = tr("KEY_VIDEO")
	locationsBtn.text = tr("KEY_SONIDO")
	memoriesBtn.text = tr("KEY_LENGUAJE")
	editorBtn.text = tr("KEY_CREDITOS")
	exitBtn.text = tr("KEY_REGRESAR")

func ir_a_sub_panel_sonido():
	estado_actual = EstadosMenu.SONIDO
	contenedor_botones.visible = false 
	linea_conectora.visible = false
	
	if panel_sonido:
		panel_sonido.visible = true
		
		# --- TRADUCCIÓN DINÁMICA DE LOS NODOS DEL PANEL DE AUDIO ---
		# Buscamos los Labels e hilos de texto dentro de tu nodo contenedor del panel de sonido
		if panel_sonido.has_node("titleLabel"):
			panel_sonido.get_node("titleLabel").text = tr("KEY_TITULO_SONIDO")
		if panel_sonido.has_node("volumeLabel"):
			panel_sonido.get_node("volumeLabel").text = tr("KEY_VOLUMEN_MUSICA")
			
		# Traducimos los textos dinámicos de tus CheckButtons y Botones interactivos
		if sfx_check_btn:
			sfx_check_btn.text = tr("KEY_EFECTOS_SONIDO")
		if btn_cargar_cancion:
			btn_cargar_cancion.text = tr("KEY_CARGAR_PISTA")
		if defaultMusicBtn:
			defaultMusicBtn.text = tr("KEY_PISTA_DEFECTO")
		if returnBtn:
			returnBtn.text = tr("KEY_REGRESAR")
		
		# Mantener tu lógica original para configurar el slider de volumen
		var bus_idx = AudioServer.get_bus_index("Music")
		if bus_idx != -1:
			var volumen_actual_db = AudioServer.get_bus_volume_db(bus_idx)
			slider_musica.value = db_to_linear(volumen_actual_db) * 100.0

func _on_subjects_btn_pressed():
	Global.reproducir_tick()
	if estado_actual == EstadosMenu.PRINCIPAL:
		get_tree().change_scene_to_file("res://main.tscn")
	elif estado_actual == EstadosMenu.EDICION:
		print("SOON as posible...")

func _on_lugares_btn_pressed() -> void:
	Global.reproducir_tick()
	if estado_actual == EstadosMenu.PRINCIPAL:
		print("Accediendo a la base de datos de ubicaciones geográficas...")
	elif estado_actual == EstadosMenu.EDICION:
		ir_a_sub_panel_sonido()

func _on_memories_btn_pressed() -> void:
	Global.reproducir_tick()
	if estado_actual == EstadosMenu.PRINCIPAL:
		print("Cargando secuencias de ADN de memoria genética...")
	elif estado_actual == EstadosMenu.EDICION:
		generar_panel_idiomas_animus()
		print("Starting the language section")

func _on_editor_btn_pressed() -> void:
	Global.reproducir_tick()
	if estado_actual == EstadosMenu.PRINCIPAL:
		ir_a_modo_edicion()
	elif estado_actual == EstadosMenu.EDICION:
		# Ocultamos la botonera para centrar la atención en el Animus
		contenedor_botones.visible = false
		linea_conectora.visible = false
		
		# Diseñamos los créditos
		var texto_creditos = "=== AudittAnimus ===\n\n\n" + \
							"DESARROLLADOR PRINCIPAL\nAlejandro Audittore / Leonel Machado\n\n\n" + \
							"DESARROLLO DE FUNCIONES DE INTELIGENCIA ARTIFICIAL\nGiscard Fuenmayor\n\n\n" + \
							"DESARROLLO DEL CLIENTE WEB\nAlejandro Audittore / Leonel Machado\nJary Gainza\n\n\n" + \
							"AGRADECIMIENTOS ESPECIALES\n" + \
							"SUBJECT1\nSUBJECT2\nSUBJECT3\n\n\n" + \
							"DISEÑO DE INTERFAZ\nInspirado en Assassin's Creed 2\n(Producto original de Ubisoft Montreal)\n\n\n" + \
							"Gracias por usar el proyecto."
		generar_panel_animus_procedimental(Vector2(650, 400), true, texto_creditos)

func _on_exit_btn_pressed():
	Global.reproducir_tick()
	if estado_actual == EstadosMenu.PRINCIPAL:
		print("Cerrando sesión en el Animus. Adiós.")
		get_tree().quit()
	elif estado_actual == EstadosMenu.EDICION:
		ir_a_menu_principal()
		
func generar_panel_idiomas_animus():
	if panel_animus_activo:
		cerrar_panel_animus()

	contenedor_botones.visible = false
	linea_conectora.visible = false

	# 1. Creamos la base procedural (500x350 para dar espacio al nuevo botón)
	generar_panel_animus_procedimental(Vector2(500, 350), false, "")
	
	# 2. Capa superior para evitar que los botones queden detrás
	var contenedor_interfaz_idioma = Control.new()
	contenedor_interfaz_idioma.size = Vector2(500, 350)
	contenedor_interfaz_idioma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_animus_activo.add_child(contenedor_interfaz_idioma)
	
	# 3. Contenedor vertical
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(440, 290)
	vbox.position = Vector2(30, 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_interfaz_idioma.add_child(vbox)
	
	# 4. Título del Panel
	var label_titulo = Label.new()
	label_titulo.text = tr("KEY_TITULO_IDIOMA")
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 16)
	vbox.add_child(label_titulo)
	
	var separador = Control.new()
	separador.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(separador)
	
	# 5. Botón de ESPAÑOL
	var btn_es = Button.new()
	btn_es.text = tr("KEY_BOTON_ESPANOL")
	btn_es.custom_minimum_size = Vector2(200, 40)
	btn_es.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# SOLUCIÓN ERROR 2: Si el borde gris te molesta visualmente, podemos quitar el modo
	# de enfoque por teclado del botón o cambiarlo a modo "click" (FOCUS_CLICK)
	btn_es.focus_mode = Control.FOCUS_CLICK
	btn_es.pressed.connect(func(): _aplicar_cambio_idioma("es"))
	vbox.add_child(btn_es)
	
	# 6. Botón de INGLÉS
	var btn_en = Button.new()
	btn_en.text = tr("KEY_BOTON_INGLES")
	btn_en.custom_minimum_size = Vector2(200, 40)
	btn_en.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_en.focus_mode = Control.FOCUS_CLICK
	btn_en.pressed.connect(func(): _aplicar_cambio_idioma("en"))
	vbox.add_child(btn_en)
	
	var separador2 = Control.new()
	separador2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(separador2)
	
	# 7. ¡NUEVO! Botón de VOLVER
	var btn_volver = Button.new()
	# Recuerda añadir "KEY_REGRESAR" en tu Excel si no lo habías hecho antes
	btn_volver.text = tr("KEY_REGRESAR") 
	btn_volver.custom_minimum_size = Vector2(200, 40)
	btn_volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_volver.focus_mode = Control.FOCUS_CLICK
	btn_volver.pressed.connect(func():
		ejecutar_sfx_tick()
		cerrar_panel_animus()
		ir_a_modo_edicion()
	)
	vbox.add_child(btn_volver)
	
	# Modificamos sutilmente el parpadeo inferior para que avise también de Escape aquí
	if is_instance_valid(label_salir_animus):
		label_salir_animus.text = tr("KEY_TEXTO_SALIR")

func _aplicar_cambio_idioma(codigo_idioma: String):
	Global.reproducir_tick()
	TranslationServer.set_locale(codigo_idioma)
	print("[SISTEMA] Idioma cambiado a: ", codigo_idioma)
	guardar_preferencia("Localization", "idioma", codigo_idioma)
	var config = ConfigFile.new()
	var ultima_pista = ""
	if config.load(RUTA_CONFIG) == OK:
		ultima_pista = config.get_value("Audio", "ruta_origen_musica", "")
	actualizar_interfaz_visualizador(ultima_pista)
	# ----------------------------
	cerrar_panel_animus()
	ir_a_modo_edicion()

func _input(event: InputEvent) -> void:
	if estado_actual == EstadosMenu.SONIDO:
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			Global.reproducir_tick()
			ir_a_modo_edicion()
			
func generar_panel_animus_procedimental(dimensiones: Vector2, es_creditos: bool, texto_contenido: String):
	if panel_animus_activo:
		panel_animus_activo.queue_free()
		bloques_cuerpo_animus.clear()

	var screen_size = get_viewport_rect().size

	# 1. Contenedor base centrado
	panel_animus_activo = Control.new()
	panel_animus_activo.size = dimensiones
	panel_animus_activo.global_position = (screen_size / 2.0) - (dimensiones / 2.0)
	add_child(panel_animus_activo)

	# 2. Construcción por Columnas Ondulantes (24 bloques)
	var total_columnas = 24
	var ancho_columna = dimensiones.x / total_columnas
	
	for i in range(total_columnas):
		var columna = ColorRect.new()
		columna.color = Color("101010", 0.65)
		columna.size = Vector2(ancho_columna + 0.5, dimensiones.y)
		columna.position = Vector2(i * ancho_columna, 0)
		columna.modulate.a = 0.0
		panel_animus_activo.add_child(columna)
		bloques_cuerpo_animus.append(columna)
		
		var marca_roja_superior = ColorRect.new()
		marca_roja_superior.color = color_rojo_animus
		marca_roja_superior.size = Vector2(columna.size.x, 3)
		marca_roja_superior.position = Vector2(0, 0)
		columna.add_child(marca_roja_superior)
		
		var marca_roja_inferior = ColorRect.new()
		marca_roja_inferior.color = color_rojo_animus
		marca_roja_inferior.size = Vector2(columna.size.x, 3)
		marca_roja_inferior.position = Vector2(0, dimensiones.y - 3)
		columna.add_child(marca_roja_inferior)

	# 3. Capa contenedora para la información (Estática al centro)
	var contenedor_datos = Control.new()
	contenedor_datos.size = dimensiones
	contenedor_datos.clip_contents = true 
	contenedor_datos.modulate.a = 0.0
	panel_animus_activo.add_child(contenedor_datos)

# 4. text and scroll block---------------------------------------------------------
	if es_creditos:
		scroll_creditos_animus = ScrollContainer.new()
		scroll_creditos_animus.size = dimensiones - Vector2(60, 60)
		scroll_creditos_animus.position = Vector2(30, 30)
		scroll_creditos_animus.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll_creditos_animus.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		contenedor_datos.add_child(scroll_creditos_animus)

		scroll_creditos_animus.gui_input.connect(_on_scroll_gui_input)

		# SOLUCIÓN 1: El VBoxContainer DEBE tener un tamaño mínimo configurado y expandirse
		var vbox_creditos = VBoxContainer.new()
		vbox_creditos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_creditos.size_flags_vertical = Control.SIZE_EXPAND_FILL # Fuerza la expansión vertical
		scroll_creditos_animus.add_child(vbox_creditos)

		# SOLUCIÓN 2: Garantizar que el espacio inicial empuje el texto de abajo hacia arriba
		var espacio_inicio = Control.new()
		espacio_inicio.custom_minimum_size = Vector2(0, 50) # <-- CAMBIADO a 50 para que sea visible de inmediato
		vbox_creditos.add_child(espacio_inicio)

		var label_texto = Label.new()
		label_texto.text = texto_contenido
		label_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_texto.autowrap_mode = TextServer.AUTOWRAP_WORD
		label_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_texto.add_theme_font_size_override("font_size", 14)
		vbox_creditos.add_child(label_texto)
		
		# SOLUCIÓN 3: El espacio final le da el margen extra para dejar que el texto suba del todo
		var espacio_final = Control.new()
		espacio_final.custom_minimum_size = Vector2(0, dimensiones.y)
		vbox_creditos.add_child(espacio_final)

		# Label de Salida (Negro, abajo del panel externo)
		label_salir_animus = Label.new()
		label_salir_animus.text = tr("KEY_TEXTO_SALIR") # 
		label_salir_animus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_salir_animus.size = Vector2(dimensiones.x, 30)
		
		var posicion_y_debajo = panel_animus_activo.global_position.y + dimensiones.y + 15
		label_salir_animus.global_position = Vector2(panel_animus_activo.global_position.x, posicion_y_debajo)
		
		label_salir_animus.add_theme_font_size_override("font_size", 12)
		label_salir_animus.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		
		add_child(label_salir_animus)
		
		usuario_scrolleando = false
		tiempo_inactividad_scroll = 0.0
		scroll_creditos_animus.scroll_vertical = 0
		scroll_acumulado = 0.0 # <-- NUEVO: Reiniciamos la memoria de scroll al crear el panel
	else:
		scroll_creditos_animus = null
		label_salir_animus = null
		var label_sujeto = Label.new()
		label_sujeto.text = texto_contenido
		label_sujeto.size = dimensiones - Vector2(60, 60)
		label_sujeto.position = Vector2(30, 30)
		label_sujeto.autowrap_mode = TextServer.AUTOWRAP_WORD
		contenedor_datos.add_child(label_sujeto)
#-----------------------------------------------End text and scroll block---------------------------

	# 5. Credits Panel construction
	var tween = create_tween().set_parallel(true)
	
	for i in range(bloques_cuerpo_animus.size()):
		var delay_construccion = i * 0.04
		tween.tween_property(bloques_cuerpo_animus[i], "modulate:a", 1.0, 0.2)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay_construccion)

	tween.chain().tween_property(contenedor_datos, "modulate:a", 1.0, 0.4)

func construir_pila_bloques():
	for child in pila_cuadros.get_children():
		if child != contenedor_botones:
			child.queue_free()
			
	cuadros_nodos.clear()
	
	var total_bloques_pilar = 35 
	var separacion_vertical = 24  
	
	for i in range(total_bloques_pilar):
		var bloque_3d = Control.new()
		pila_cuadros.add_child(bloque_3d)
		
		var desfase_curva_x = sin(i * 0.3) * 15.0
		bloque_3d.position = Vector2(desfase_curva_x, i * separacion_vertical)
		
		var cara_frontal = ColorRect.new()
		bloque_3d.add_child(cara_frontal)
		cara_frontal.size = Vector2(150, 14)
		cara_frontal.position = Vector2(0, 8)
		cara_frontal.color = Color("3a3a3a", 0.7)
		
		var cara_superior = Polygon2D.new()
		bloque_3d.add_child(cara_superior)
		var puntos = PackedVector2Array([
			Vector2(0, 8),
			Vector2(30, 0),
			Vector2(180, 0),
			Vector2(150, 8)
		])
		cara_superior.polygon = puntos
		cara_superior.color = color_gris_animus
		
		var linea_luz = Line2D.new()
		bloque_3d.add_child(linea_luz)
		linea_luz.points = PackedVector2Array([Vector2(0, 8), Vector2(150, 8)])
		linea_luz.width = 1.0
		linea_luz.default_color = Color("ffffff", 0.3)
		
		var piezas_bloque = {
			"objeto": bloque_3d,
			"x_base": desfase_curva_x,
			"frontal": cara_frontal,
			"superior": cara_superior
		}
		cuadros_nodos.append(piezas_bloque)
		
func _on_boton_seleccionado(indice_boton: int):
	if estado_actual == EstadosMenu.SONIDO: return
	indice_boton_actual = indice_boton
	linea_conectora.visible = true 
	
	for bloque in cuadros_nodos:
		bloque["frontal"].color = Color("3a3a3a", 0.7)
		bloque["superior"].color = color_gris_animus
			
	var bloque_inicial_menu = 10 
	var bloques_por_boton = 2 
	var indice_inicio = bloque_inicial_menu + (indice_boton * bloques_por_boton)
	
	for k in range(bloques_por_boton):
		var indice_bloque = indice_inicio + k
		if indice_bloque < cuadros_nodos.size():
			cuadros_nodos[indice_bloque]["superior"].color = color_rojo_animus
			cuadros_nodos[indice_bloque]["frontal"].color = Color(color_rojo_animus.r * 0.6, color_rojo_animus.g * 0.6, color_rojo_animus.b * 0.6, 0.9)
		
func vincular_eventos_botones():
	var botones = contenedor_botones.get_children()
	for i in range(botones.size()):
		var boton = botones[i]
		if boton is Button:
			boton.focus_entered.connect(_on_boton_seleccionado.bind(i))
			boton.mouse_entered.connect(func(): if estado_actual != EstadosMenu.SONIDO: boton.grab_focus())
			boton.mouse_exited.connect(_on_mouse_salio_de_boton)
			
func _on_mouse_salio_de_boton():
	await get_tree().create_timer(0.01).timeout
	var mouse_sobre_algun_boton = false
	for boton in contenedor_botones.get_children():
		if boton is Button and boton.get_global_rect().has_point(get_global_mouse_position()):
			mouse_sobre_algun_boton = true
			break
			
	if not mouse_sobre_algun_boton and estado_actual != EstadosMenu.SONIDO:
		indice_boton_actual = -1
		linea_conectora.visible = false
		var foco_actual = get_viewport().gui_get_focus_owner()
		if foco_actual and foco_actual.get_parent() == contenedor_botones:
			foco_actual.release_focus()
			
		for bloque in cuadros_nodos:
			bloque["frontal"].color = Color("3a3a3a", 0.7)
			bloque["superior"].color = color_gris_animus
			
func _process(delta: float) -> void:
	var tiempo = Time.get_ticks_msec() / 1000.0
	
	for i in range(cuadros_nodos.size()):
		var bloque = cuadros_nodos[i]
		var variacion_ondulatoria = sin((tiempo * velocidad_movimiento) - (i * 0.25)) * amplitud_movimiento
		bloque["objeto"].position.x = bloque["x_base"] + variacion_ondulatoria

	if is_instance_valid(anillo_giro_padre) and visualizador_padre.visible:
		anillo_giro_padre.rotation += 1.0 * delta 

	if is_instance_valid(label_nombre_cancion):
		label_nombre_cancion.position.x -= velocidad_texto * delta
		if label_nombre_cancion.position.x < (limite_izquierdo_texto / 2.0):
			label_nombre_cancion.position.x = panel_texto_cancion.size.x

	if indice_boton_actual != -1 and linea_conectora.visible and estado_actual != EstadosMenu.SONIDO:
		var botones = contenedor_botones.get_children()
		if indice_boton_actual < botones.size():
			var boton_activo = botones[indice_boton_actual] as Button
			var bloque_inicial_menu = 10
			var bloques_por_boton = 2
			var indice_bloque_origen = bloque_inicial_menu + (indice_boton_actual * bloques_por_boton)
			if indice_bloque_origen < cuadros_nodos.size():
				var nodo_bloque = cuadros_nodos[indice_bloque_origen]["objeto"]
				var origen_linea = nodo_bloque.global_position + Vector2(150, 8)
				var destino_linea = boton_activo.global_position + Vector2(0, boton_activo.size.y / 2)
				linea_conectora.set_point_position(0, origen_linea)
				linea_conectora.set_point_position(1, destino_linea)
				
	# --- Actualización del Panel Animus Dinámico V3 (Ondulación de Bloques) ---
	if panel_animus_activo and panel_animus_activo.visible:
		# Recorremos cada columna del panel para calcular su movimiento vertical independiente
		for i in range(bloques_cuerpo_animus.size()):
			var columna = bloques_cuerpo_animus[i]
			if is_instance_valid(columna):
				# Desfase basado en la posición X de la columna para que la onda viaje de izquierda a derecha
				var desajuste_fase = columna.position.x * frecuencia_onda_animus
				
				# Calculamos el desplazamiento vertical usando la onda de seno
				var desplazamiento_y = sin((tiempo * velocidad_onda_animus) - desajuste_fase) * amplitud_onda_animus
				# Aplicamos el movimiento directamente a la posición Y de la columna
				columna.position.y = desplazamiento_y

		# --- Control del Scroll e Interfaz de los Créditos ---
		if is_instance_valid(scroll_creditos_animus):

			# Lógica A: Auto-scroll con pausa inteligente por interacción humana
			if usuario_scrolleando:
				tiempo_inactividad_scroll += delta
				if tiempo_inactividad_scroll >= 4.0:
					usuario_scrolleando = false
					# Sincronizamos la memoria decimal con donde dejaste el scroll manualmente
					scroll_acumulado = float(scroll_creditos_animus.scroll_vertical) 
			else:
				# EL TRUCO MATEMÁTICO: Sumamos en float para no perder decimales, y lo pasamos a int
				scroll_acumulado += velocidad_scroll_creditos * delta
				scroll_creditos_animus.scroll_vertical = int(scroll_acumulado)
				
				# Bucle infinito estable
				var limite_maximo_scroll = scroll_creditos_animus.get_v_scroll_bar().max_value - scroll_creditos_animus.size.y
				
				if limite_maximo_scroll > 0 and scroll_creditos_animus.scroll_vertical >= limite_maximo_scroll:
					scroll_creditos_animus.scroll_vertical = 0
					scroll_acumulado = 0.0 # Reiniciamos al hacer el bucle
			
			# Lógica B: Animación de parpadeo (Blinking) para el indicador ESC
			if is_instance_valid(label_salir_animus):
				tiempo_parpadeo += delta * 5.0
				label_salir_animus.modulate.a = abs(sin(tiempo_parpadeo))

func _on_scroll_gui_input(event: InputEvent):
	if event is InputEventMouseButton or event is InputEventPanGesture:
		usuario_scrolleando = true
		tiempo_inactividad_scroll = 0.0
		# Mantiene sincronizado el acumulador con lo que scrolleas con el mouse
		if is_instance_valid(scroll_creditos_animus):
			scroll_acumulado = float(scroll_creditos_animus.scroll_vertical)

# Escucha la tecla ESC globalmente cuando el panel de créditos está activo
func _unhandled_input(event: InputEvent) -> void:
	if panel_animus_activo and panel_animus_activo.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			Global.reproducir_tick()
			cerrar_panel_animus()

# Función para cerrar el panel con un Fade Out limpio o eliminación directa
func cerrar_panel_animus():
	if panel_animus_activo:
		# CORRECCIÓN 2: Borrar explícitamente el Label negro de la pantalla para que no se quede flotando
		if is_instance_valid(label_salir_animus):
			label_salir_animus.queue_free()
		
		panel_animus_activo.queue_free()
		panel_animus_activo = null
		scroll_creditos_animus = null
		label_salir_animus = null
		bloques_cuerpo_animus.clear()
		
		# --- CORRECCIÓN 1: Volver al estado de EDICION para sincronizar con los botones de la pantalla ---
		estado_actual = EstadosMenu.EDICION 
		indice_boton_actual = 3 # Coloca el foco de la línea roja en el botón de "CREDITOS" (el 4to botón, índice 3)
		
		# Reactivamos la botonera secundaria para que puedas seguir navegando las opciones o regresar
		if is_instance_valid(contenedor_botones):
			contenedor_botones.visible = true
			# Forzamos a que el sistema recupere el foco visual de la botonera
			var botones = contenedor_botones.get_children()
			if botones.size() > 3 and botones[3] is Button:
				botones[3].grab_focus()
