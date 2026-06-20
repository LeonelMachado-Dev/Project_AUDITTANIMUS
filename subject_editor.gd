extends Control
# Nodos de la UI (Ubicados dentro del Panel izquierdo de textos)
@onready var input_nombre = $Panel/ScrollContainer/VBoxContainer/inputName
@onready var input_apellido = $Panel/ScrollContainer/VBoxContainer/inputLastName
@onready var input_anio = $Panel/ScrollContainer/VBoxContainer/inputBirthYear
@onready var input_ubicacion = $Panel/ScrollContainer/VBoxContainer/inputCommonLocation
@onready var input_descripcion = $Panel/ScrollContainer/VBoxContainer/inputDescription
@onready var inputAnalisis = $Panel/ScrollContainer/VBoxContainer/inputAnalisis
@onready var file_dialog_foto = $Panel/FileDialog_Image
# El contenedor de recorte (PictureEditor es hijo directo de la raíz, NO del VBoxContainer para que tape toda la pantalla)
@onready var panel_recorte = $Panel/PictureEditor
# Componentes internos del visor de recorte
@onready var contenedor_visor = $Panel/PictureEditor/VisorContainer
@onready var foto_original = $Panel/PictureEditor/VisorContainer/ClipControl/originalPicture
# --- NUEVAS VARIABLES PARA EL MODO EDICIÓN ---
var editando_sujeto: bool = false
var id_sujeto_a_editar = null
var ruta_imagen_original_db: String = "" # Para saber cuál borrar si se cambia la foto
#---------------------------------------------------------------------------------------------------
# Variables mecánicas de arrastre de imagen
var arrastrando: bool = false
var ruta_foto_original: String = ""
var imagen_cargada_raw: Image = null
var foto_confirmada: bool = false # Nos dice si el usuario ya presionó el botón de fijar encuadre

func _ready():
	panel_recorte.visible = true
	file_dialog_foto.file_selected.connect(_on_foto_seleccionada_dialog)
	
	# REVISIÓN DE MODO HÍBRIDO (¿Editar o Crear?)
	if Global.sujeto_seleccionado_id != null and Global.sujeto_seleccionado_id > 0:
		editando_sujeto = true
		id_sujeto_a_editar = Global.sujeto_seleccionado_id
		cargar_datos_para_editar(id_sujeto_a_editar)
	else:
		editando_sujeto = false
		id_sujeto_a_editar = null
		ruta_imagen_original_db = ""
		
func cargar_datos_para_editar(id_elegido):
	print("[Animus OS] Cargando expediente para edición. ID: ", id_elegido)
	
	# Consultamos la base de datos de manera idéntica a detalles_sujeto.gd
	var consulta = "SELECT * FROM sujetos WHERE id = " + str(id_elegido)
	DB.db.query(consulta)
	
	if DB.db.query_result.size() > 0:
		var datos_sujeto = DB.db.query_result[0]
		
		# 1. Rellenamos los LineEdits e Inputs de texto
		input_nombre.text = str(datos_sujeto.get("nombre", ""))
		input_apellido.text = str(datos_sujeto.get("apellido", ""))
		input_anio.text = str(datos_sujeto.get("birth_year", ""))
		if input_anio.text == "null" or input_anio.text == "0":
			input_anio.text = ""
		input_ubicacion.text = str(datos_sujeto.get("ubicacion_frecuente", ""))
		input_descripcion.text = str(datos_sujeto.get("descripcion", ""))
		inputAnalisis.text = str(datos_sujeto.get("analisis_detallado", ""))
		
		# 2. Precargamos la imagen que ya tiene en la base de datos
		ruta_imagen_original_db = str(datos_sujeto.get("imagen_path", ""))
		
		if ruta_imagen_original_db != "" and ruta_imagen_original_db != "null" and FileAccess.file_exists(ruta_imagen_original_db):
			imagen_cargada_raw = Image.load_from_file(ruta_imagen_original_db)
			if imagen_cargada_raw:
				var texture = ImageTexture.create_from_image(imagen_cargada_raw)
				foto_original.texture = texture
				
				# Forzamos proporciones iniciales en el visor
				foto_original.size = Vector2(300, 400)
				foto_original.position = Vector2.ZERO
				
				# Consideramos la foto confirmada por defecto para que no obligue a recortar otra vez
				foto_confirmada = true
				foto_original.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			# Si no hay foto válida previa, cargamos el placeholder por defecto
			cargar_imagen_defecto_visor()
			
func cargar_imagen_defecto_visor():
	var textura_por_defecto = load("res://Images/TEST SUBJECTS/no_foto.png")
	if textura_por_defecto:
		foto_original.texture = textura_por_defecto
		foto_original.size = Vector2(300, 400)
		foto_original.position = Vector2.ZERO
	foto_original.mouse_filter = Control.MOUSE_FILTER_STOP
	foto_confirmada = false

func _on_foto_seleccionada_dialog(path: String):
	ruta_foto_original = path
	imagen_cargada_raw = Image.load_from_file(path)
	
	if imagen_cargada_raw:
		var texture = ImageTexture.create_from_image(imagen_cargada_raw)
		foto_original.texture = texture
		
		# Habilitamos que la imagen reciba clics y arrastres del mouse nuevamente
		foto_original.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# --- MATEMÁTICA DE AJUSTE ANIMUS ---
		# Forzamos que la foto cubra el visor de 300x400 adaptándose proporcionalmente
		var escala_ancho = 300.0 / imagen_cargada_raw.get_width()
		var escala_alto = 400.0 / imagen_cargada_raw.get_height()
		var factor_escala = max(escala_ancho, escala_alto)
		
		foto_original.size = imagen_cargada_raw.get_size() * factor_escala
		
		# Centramos la foto perfectamente dentro del recuadro de 300x400
		foto_original.position = (Vector2(300, 400) - foto_original.size) / 2
		
		# Encendemos la interfaz del editor
		panel_recorte.visible = true
# --- MECÁNICA DE ARRASTRE ISOMÉTRICO/2D DE LA FOTO ---

func _on_confirm_btn_pressed() -> void:
	# VALIDACIÓN: Si 'imagen_cargada_raw' es null, no hay nada que encuadrar
	if not imagen_cargada_raw:
		$"Advice-PopUp".dialog_text = "Error de edición: No hay ninguna imagen cargada para recortar."
		$"Advice-PopUp".popup_centered()
		return
		
	# YA NO LLAMAMOS A PROCESAR_RECORTE_FISICO() AQUÍ. 
	# Guardamos el estado en memoria de que el encuadre está listo
	foto_confirmada = true
	
	# Congelamos el mouse en la foto para mantener la composición visual fija
	foto_original.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Mostramos el Pop-up de preparación
	$"Success-Pop_Up".dialog_text = "Sincronización facial preparada. El archivo se generará al guardar el sujeto."
	$"Success-Pop_Up".popup_centered()

func procesar_recorte_fisico():
	# Si no hay ninguna imagen cargada, devolvemos la ruta de la foto por defecto de forma segura
	if not imagen_cargada_raw: 
		print("[Animus OS] No se detectó imagen externa. Asignando placeholder por defecto.")
		return "res://Images/TEST SUBJECTS/no_foto.png"
	
	# 1. Calculamos escalas
	var escala_x = imagen_cargada_raw.get_width() / foto_original.size.x
	var escala_y = imagen_cargada_raw.get_height() / foto_original.size.y
	
	# 2. Averiguamos el origen exacto del recorte
	var desfase_local = foto_original.position
	var origen_recorte_x = abs(desfase_local.x) * escala_x
	var origen_recorte_y = abs(desfase_local.y) * escala_y
	
	var ancho_recorte = 300 * escala_x
	var alto_recorte = 400 * escala_y
	
	# 3. Extraemos la región
	var region_origen = Rect2i(int(origen_recorte_x), int(origen_recorte_y), int(ancho_recorte), int(alto_recorte))
	var imagen_recortada = imagen_cargada_raw.get_region(region_origen)
	
	# 4. Redimensionamos matemáticamente a 300x400
	imagen_recortada.resize(300, 400, Image.INTERPOLATE_LANCZOS)
	
	# 5. Generamos el nombre de guardado dinámico de forma limpia
	var timestamp = Time.get_unix_time_from_system()
	var nombre_limpio = input_nombre.text.validate_filename().to_lower().strip_edges().replace(" ", "_")
	if nombre_limpio == "": 
		nombre_limpio = "sujeto"
		
	var ruta_guardado_final = "user://sujetos/" + nombre_limpio + "_" + str(int(timestamp)) + ".png"
	
	# 6. Guardamos físicamente
	var error_guardado = imagen_recortada.save_png(ruta_guardado_final)
	if error_guardado == OK:
		print("[Animus OS] Archivo físico generado con éxito en: ", ruta_guardado_final)
		return ruta_guardado_final
	else:
		print("[Error] No se pudo escribir el archivo físico PNG.")
		return ""

func _on_save_all_btn_pressed() -> void:
	# 1. VALIDACIÓN DE TEXTOS OBLIGATORIOS (Solo Nombre y Descripción)
	if input_nombre.text.strip_edges() == "":
		$"Advice-PopUp".dialog_text = "Error de registro: El campo 'NOMBRE' es obligatorio."
		$"Advice-PopUp".popup_centered()
		return
		
	if input_descripcion.text.strip_escapes().strip_edges() == "":
		$"Advice-PopUp".dialog_text = "Error de registro: Se requiere una 'DESCRIPCIÓN' válida para guardar al sujeto."
		$"Advice-PopUp".popup_centered()
		return

	# --- TRATAMIENTO DE CAMPOS OPCIONALES (Asignación Automática UNKNOWN) ---
	var birth_year: String = input_anio.text.strip_edges()
	if birth_year == "":
		birth_year = "UNKNOWN"
		
	var ubicacion: String = input_ubicacion.text.strip_edges()
	if ubicacion == "":
		ubicacion = "UNKNOWN"
		
	# Recogemos de forma segura el texto del análisis detallado
	var analisis_detallado_txt: String = inputAnalisis.text.strip_edges()

	# 2. GENERACIÓN FÍSICA O MANTENIMIENTO DE IMAGEN
	var ruta_imagen_final = procesar_recorte_fisico()
	if ruta_imagen_final == "":
		$"Advice-PopUp".dialog_text = "Error crítico de procesamiento: No se pudo gestionar la imagen del sujeto."
		$"Advice-PopUp".popup_centered()
		return

	# 3. FLUJO DE GUARDADO SEGÚN EL MODO (EDITAR VS INSERTAR)
	if editando_sujeto:
		# --- CONSULTA DE ACTUALIZACIÓN (UPDATE) ---
		var consulta_update = "UPDATE sujetos SET " + \
			"nombre = '" + input_nombre.text.replace("'", "''") + "', " + \
			"apellido = '" + input_apellido.text.replace("'", "''") + "', " + \
			"birth_year = '" + birth_year.replace("'", "''") + "', " + \
			"imagen_path = '" + ruta_imagen_final + "', " + \
			"descripcion = '" + input_descripcion.text.replace("'", "''") + "', " + \
			"ubicacion_frecuente = '" + ubicacion.replace("'", "''") + "', " + \
			"analisis_detallado = '" + analisis_detallado_txt.replace("'", "''") + "' " + \
			"WHERE id = " + str(id_sujeto_a_editar)
			
		DB.db.query(consulta_update)
		print("[Base de Datos] Registro actualizado con éxito. ID: ", id_sujeto_a_editar)
		
		# --- CONTROL DE LIMPIEZA DE ARCHIVO EN EL DISCO ---
		# Solo borramos la foto vieja si la nueva foto está guardada en user:// (evitamos borrar el placeholder res://)
		if ruta_imagen_final != ruta_imagen_original_db and ruta_imagen_original_db.begins_with("user://"):
			if ruta_imagen_original_db != "" and FileAccess.file_exists(ruta_imagen_original_db):
				DirAccess.remove_absolute(ruta_imagen_original_db)
				print("[DISCO] Imagen obsoleta borrada de user://")
				
		$"Success-Pop_Up".dialog_text = "Expediente del sujeto actualizado con éxito en el núcleo de datos."
		$"Success-Pop_Up".popup_centered()
		
		# Esperamos a cerrar el flujo y volver
		await get_tree().create_timer(1.5).timeout
		_salir_a_menu_principal()
	else:
		# --- COMPORTAMIENTO: INSERTAR NUEVO ---
		var nuevos_datos = {
			"nombre": input_nombre.text,
			"apellido": input_apellido.text,
			"birth_year": birth_year,
			"imagen_path": ruta_imagen_final,
			"descripcion": input_descripcion.text,
			"ubicacion_frecuente": ubicacion,
			"analisis_detallado": analisis_detallado_txt
		}
		
		var nuevo_id = DB.insertar_sujeto(nuevos_datos)
		
		if nuevo_id != -1:
			print("[Base de Datos] Registro completado con éxito. Sujeto ID: ", nuevo_id)
			$"Success-Pop_Up".dialog_text = "Sujeto y expediente guardados con éxito en el núcleo de datos."
			$"Success-Pop_Up".popup_centered()
			limpiar_formulario()
		else:
			# Solo intentamos borrar del disco si era una foto recortada en user://
			if ruta_imagen_final.begins_with("user://"):
				DirAccess.remove_absolute(ruta_imagen_final)
			$"Advice-PopUp".dialog_text = "Error crítico de SQLite: No se pudo escribir en la base de datos."
			$"Advice-PopUp".popup_centered()

func limpiar_formulario():
	input_nombre.clear()
	input_apellido.clear()
	input_anio.clear()
	input_ubicacion.clear()
	input_descripcion.text = ""
	inputAnalisis.text = "" # Nos aseguramos de limpiar también el campo de análisis al terminar
	
	# Reseteamos la ruta de la foto en el script para las validaciones
	ruta_foto_original = ""
	imagen_cargada_raw = null
	
	# Cargamos el marcador de posición (Placeholder) en el TextureRect
	var textura_por_defecto = load("res://Images/TEST SUBJECTS/no_foto.png")
	if textura_por_defecto:
		foto_original.texture = textura_por_defecto
		foto_original.size = Vector2(300, 400)
		foto_original.position = Vector2.ZERO
		
	foto_original.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_clip_control_gui_input(event: InputEvent) -> void:
	if foto_original.mouse_filter == Control.MOUSE_FILTER_IGNORE: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = event.pressed
			
	if event is InputEventMouseMotion and arrastrando:
		foto_original.position += event.relative
		var limite_x_min = 300.0 - foto_original.size.x
		var limite_y_min = 400.0 - foto_original.size.y
		if limite_x_min < 0: foto_original.position.x = clamp(foto_original.position.x, limite_x_min, 0)
		else: foto_original.position.x = 0
		if limite_y_min < 0: foto_original.position.y = clamp(foto_original.position.y, limite_y_min, 0)
		else: foto_original.position.y = 0

func _input(event: InputEvent) -> void:
	# 1. Si el panel de recorte no está visible, no hacemos nada
	if not panel_recorte.visible: 
		return
		
	# 2. Si el usuario ya confirmó el recorte, bloqueamos el arrastre
	if foto_original.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	# DETECTAR CLIC GENERAL (En cualquier parte de la pantalla)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Si hace clic, verificamos si el mouse está posicionado dentro del recuadro de 300x400
			if event.pressed:
				var mouse_pos = contenedor_visor.get_local_mouse_position()
				# ¿El clic ocurrió dentro del área de 300x400 del visor?
				if mouse_pos.x >= 0 and mouse_pos.x <= 300 and mouse_pos.y >= 0 and mouse_pos.y <= 400:
					arrastrando = true
			else:
				# Al soltar el clic, se apaga el arrastre
				arrastrando = false
			
	# DETECTAR MOVIMIENTO GENERAL
	if event is InputEventMouseMotion and arrastrando:
		# Le inyectamos el movimiento directamente a la foto sin pedirle permiso a la interfaz
		foto_original.position += event.relative
		
		# Límites inteligentes para evitar los huecos negros en el recuadro
		var limite_x_min = 300.0 - foto_original.size.x
		var limite_y_min = 400.0 - foto_original.size.y
		
		if limite_x_min < 0:
			foto_original.position.x = clamp(foto_original.position.x, limite_x_min, 0)
		else:
			foto_original.position.x = 0
			
		if limite_y_min < 0:
			foto_original.position.y = clamp(foto_original.position.y, limite_y_min, 0)
		else:
			foto_original.position.y = 0

func _on_return_btn_pressed() -> void:
	Global.reproducir_tick()
	
	# Limpiamos la memoria para que la próxima vez que entremos no crea que seguimos editando
	Global.sujeto_seleccionado_id = 0 
	
	# Cambiamos de escena a main.tscn que es donde está el carrusel de tarjetas de los sujetos
	get_tree().change_scene_to_file("res://main.tscn")

func _salir_a_menu_principal():
	Global.sujeto_seleccionado_id = 0 # Reseteo de seguridad
	get_tree().change_scene_to_file("res://main.tscn")

func _on_select_image_btn_pressed() -> void:
	file_dialog_foto.popup_centered_clamped(Vector2(800, 600))
