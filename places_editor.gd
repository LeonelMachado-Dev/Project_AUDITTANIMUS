extends Control

# UI nodes (located inside AnimusPanel)
@onready var input_name = $AnimusPanel/inputName
@onready var input_description = $AnimusPanel/inputDescription
@onready var input_date = $AnimusPanel/inputDate
@onready var input_analyse = $AnimusPanel/inputAnalyse
@onready var file_dialog_picture = $AnimusPanel/FileDialog_Image

# Crop viewer internal components
@onready var picture_editor = $AnimusPanel/PictureEditor
@onready var viewer_container = $AnimusPanel/PictureEditor/VisorContainer
@onready var original_pic = $AnimusPanel/PictureEditor/VisorContainer/ClipControl/originalPicture
@onready var editor_preview: MediaViewer = $AnimusPanel/PictureEditor/EditorPreview

# Pop-up controllers
@onready var advice_popup = $"AnimusPanel/Advice-PopUp" if has_node("AnimusPanel/Advice-PopUp") else $"Advice-PopUp"
@onready var success_popup = $"AnimusPanel/Success-Pop_Up" if has_node("AnimusPanel/Success-Pop_Up") else $"Success-Pop_Up"

const PLACEHOLDER_VIDEO_PATH := "res://Videos/glitch_background.mp4"

# --- EDIT MODE VS CREATE MODE ---
var editing_place: bool = false
var place_id_to_edit = null
var original_picture_db_path: String = "" # To know which file to delete if the picture changes

# Image drag mechanics (only for static images)
var dragging: bool = false
var original_picture_path: String = ""
var loaded_picture_raw: Image = null
var confirmed_picture: bool = false

# Video media (mp4) support
var loaded_video_path: String = ""
var media_is_video: bool = false
var video_changed: bool = false
var media_save_failed: bool = false

# Music volume
var _editor_music_was: float = -1.0
const MUSIC_BUS := "Music"
const MUSIC_VIDEO_LEVEL := 10.0
const VIDEO_MAX_SECONDS := 60.0

func _ready() -> void:
	picture_editor.visible = true
	file_dialog_picture.file_selected.connect(_on_picture_selected_dialog)
	file_dialog_picture.filters = [
		"*.png ; Imágenes PNG",
		"*.jpg ; Imágenes JPG",
		"*.jpeg ; Imágenes JPEG",
		"*.gif ; GIF Animado",
		"*.mp4 ; Videos MP4",
		"*.webm ; Videos WEBM",
		"*.ogv ; Videos OGV"
	]
	
	input_name.placeholder_text = "NOMBRE DEL SUJETO"
	input_date.placeholder_text = "FECHA DE LA IMAGEN"
	input_description.placeholder_text = "ESCRIBA LA RESEÑA HISTORICA DEL LUGAR"
	input_analyse.placeholder_text = "ESCRIBA LA NOTA DEL LUGAR"
	
	# HYBRID MODE CHECK (Edit or Create Place?)
	if Global.selected_place_id != null and Global.selected_place_id > 0:
		editing_place = true
		place_id_to_edit = Global.selected_place_id
		load_data_for_edit(place_id_to_edit)
	else:
		editing_place = false
		place_id_to_edit = null
		original_picture_db_path = ""
		load_default_picture_to_viewer()

func load_data_for_edit(chosen_id):
	print("[Animus OS] Loading place record for edit. ID: ", chosen_id)
	
	var query = "SELECT * FROM places WHERE id = " + str(chosen_id)
	DB.db.query(query)
	
	if DB.db.query_result.size() > 0:
		var place_data = DB.db.query_result[0]
		
		# 1. Fill text fields
		input_name.text = str(place_data.get("place_name", ""))
		input_description.text = str(place_data.get("place_description", ""))
		input_date.text = str(place_data.get("picture_date", ""))
		input_analyse.text = str(place_data.get("personal_analyse", ""))
		
		# 2. Preload the stored media (image or video)
		original_picture_db_path = str(place_data.get("image_path", ""))
		
		if original_picture_db_path == PLACEHOLDER_VIDEO_PATH:
			# The place has no real media stored (it uses the default glitch video).
			load_default_picture_to_viewer()
		elif original_picture_db_path != "" and original_picture_db_path != "null" and original_picture_db_path != "<null>" and FileAccess.file_exists(original_picture_db_path):
			if MediaViewer.is_video_file(original_picture_db_path):
				# Stored media is a video -> stretch it into the 460x300 box
				# (vertical videos are blocked: not allowed in the horizontal container).
				var stored_reason: String = editor_preview.video_orientation_block_reason(original_picture_db_path)
				if stored_reason != "":
					print("[Animus OS] VIDEO BLOQUEADO: ", stored_reason)
					load_default_picture_to_viewer()
				else:
					var stored_duration: float = editor_preview.get_video_duration(original_picture_db_path)
					if stored_duration > VIDEO_MAX_SECONDS:
						print("[Animus OS] VIDEO BLOQUEADO: duracion de ", stored_duration, "s supera el limite de ", VIDEO_MAX_SECONDS, "s.")
						load_default_picture_to_viewer()
					else:
						_show_media_mode()
						if editor_preview.display_video_path(original_picture_db_path):
							media_is_video = true
							loaded_video_path = original_picture_db_path
							video_changed = false
							loaded_picture_raw = null
							confirmed_picture = false
							_lower_music_for_video()
						else:
							load_default_picture_to_viewer()
			else:
				# Stored media is a static image -> enable cropping
				media_is_video = false
				loaded_picture_raw = Image.load_from_file(original_picture_db_path)
				if loaded_picture_raw:
					_show_crop_mode()
					var texture = ImageTexture.create_from_image(loaded_picture_raw)
					original_pic.texture = texture
					original_pic.size = Vector2(460, 300)
					original_pic.position = Vector2.ZERO
					confirmed_picture = true
					original_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
				else:
					load_default_picture_to_viewer()
		else:
			load_default_picture_to_viewer()
	else:
		load_default_picture_to_viewer()

func load_default_picture_to_viewer():
	_restore_music()
	media_is_video = false
	loaded_video_path = ""
	video_changed = false
	loaded_picture_raw = null
	confirmed_picture = false
	_show_media_mode()
	editor_preview.show_placeholder(PLACEHOLDER_VIDEO_PATH)

func _show_media_mode():
	editor_preview.visible = true
	editor_preview.clear()
	original_pic.visible = false
	original_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	original_pic.texture = null
	dragging = false

func _show_crop_mode():
	editor_preview.visible = false
	editor_preview.clear()
	original_pic.visible = true
	original_pic.mouse_filter = Control.MOUSE_FILTER_STOP

func _get_music_percent() -> float:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx == -1:
		return -1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) * 100.0

func _set_music_percent(percent: float) -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(percent, 0.0, 100.0) / 100.0))

# Baja la musica a 10% mientras hay un video cargado en el editor (solo la primera vez).
func _lower_music_for_video():
	if not media_is_video:
		return
	if _editor_music_was >= 0.0:
		return
	_editor_music_was = _get_music_percent()
	if _editor_music_was > MUSIC_VIDEO_LEVEL + 0.001:
		_set_music_percent(MUSIC_VIDEO_LEVEL)
	else:
		_editor_music_was = -1.0

func _restore_music():
	if _editor_music_was >= 0.0:
		_set_music_percent(_editor_music_was)
	_editor_music_was = -1.0

func _exit_tree():
	_restore_music()

func _on_picture_selected_dialog(path: String):
	_restore_music()
	original_picture_path = path
	
	if MediaViewer.is_video_file(path):
		# Los videos verticales NO se cargan: el contenedor es horizontal.
		var reason: String = editor_preview.video_orientation_block_reason(path)
		if reason != "":
			print("[Animus OS] VIDEO BLOQUEADO: ", reason)
			_show_warning_popup("Este video no cumple las dimensiones pre-establecidas del contenedor, debe ser un video horizontal. Seleccione otro")
			return

		# Los videos no pueden durar mas de 1 minuto.
		var duration: float = editor_preview.get_video_duration(path)
		if duration > VIDEO_MAX_SECONDS:
			print("[Animus OS] VIDEO BLOQUEADO: duracion de ", duration, "s supera el limite de ", VIDEO_MAX_SECONDS, "s.")
			_show_warning_popup("Este video dura mas de 1 minuto. Seleccione un video de maximo un minuto de duracion.")
			return

		# VIDEO selected -> stretch into the 460x300 container, no cropping
		_show_media_mode()
		if editor_preview.display_video_path(path):
			media_is_video = true
			loaded_video_path = path
			video_changed = true
			loaded_picture_raw = null
			confirmed_picture = false
			_lower_music_for_video()
		else:
			# Could not build a stream for this path -> fall back to placeholder
			media_is_video = false
			loaded_video_path = ""
			video_changed = false
			loaded_picture_raw = null
			editor_preview.show_placeholder(PLACEHOLDER_VIDEO_PATH)
			_show_warning_popup("No se pudo cargar el video como recurso. Se mantiene el placeholder por defecto.")
		picture_editor.visible = true
		return
	
	# IMAGE selected -> cropping flow
	media_is_video = false
	loaded_picture_raw = Image.load_from_file(path)
	
	if loaded_picture_raw:
		_show_crop_mode()
		var texture = ImageTexture.create_from_image(loaded_picture_raw)
		original_pic.texture = texture
		original_pic.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# HORIZONTAL FITTING MATH (460x300)
		var scale_width = 460.0 / loaded_picture_raw.get_width()
		var scale_height = 300.0 / loaded_picture_raw.get_height()
		var scale_factor = max(scale_width, scale_height)
		
		original_pic.size = loaded_picture_raw.get_size() * scale_factor
		original_pic.position = (Vector2(460, 300) - original_pic.size) / 2
		picture_editor.visible = true

func _on_confirm_btn_pressed() -> void:
	if media_is_video:
		confirmed_picture = true
		_show_success_popup("Encuadre del lugar verificado. El video se usara en su resolucion original.")
		return
	if not loaded_picture_raw:
		_show_warning_popup("Error de edición: No hay ninguna imagen cargada para recortar.")
		return
		
	confirmed_picture = true
	original_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show_success_popup("Encuadre del lugar verificado. La imagen final se generará al guardar.")

func process_physical_crop() -> String:
	media_save_failed = false
	
	if media_is_video:
		var result = _persist_video()
		if result == "" and loaded_video_path != "":
			media_save_failed = true
		return result
	
	if loaded_picture_raw:
		# 1. Scale calculation relative to 460x300
		var scale_x = loaded_picture_raw.get_width() / original_pic.size.x
		var scale_y = loaded_picture_raw.get_height() / original_pic.size.y
		
		# 2. Exact crop origin
		var local_offset = original_pic.position
		var crop_origin_x = abs(local_offset.x) * scale_x
		var crop_origin_y = abs(local_offset.y) * scale_y
		
		var crop_width = 460.0 * scale_x
		var crop_height = 300.0 * scale_y
		
		# 3. Region extraction and resizing (460x300 Lanczos)
		var origin_region = Rect2i(int(crop_origin_x), int(crop_origin_y), int(crop_width), int(crop_height))
		var cropped_image = loaded_picture_raw.get_region(origin_region)
		cropped_image.resize(460, 300, Image.INTERPOLATE_LANCZOS)
		
		# 4. Ensure the places directory exists
		if not DirAccess.dir_exists_absolute("user://places"):
			DirAccess.make_dir_absolute("user://places")
			
		var timestamp = Time.get_unix_time_from_system()
		var clean_name = input_name.text.validate_filename().to_lower().strip_edges().replace(" ", "_")
		if clean_name == "":
			clean_name = "place"
			
		var final_save_path = "user://places/" + clean_name + "_" + str(int(timestamp)) + ".png"
		
		# 5. Save PNG
		var save_error = cropped_image.save_png(final_save_path)
		if save_error == OK:
			print("[Animus OS] Place picture processed successfully: ", final_save_path)
			return final_save_path
		else:
			media_save_failed = true
			print("[Error] Failed to write place PNG file.")
			return ""
	
	# No media loaded -> store empty path; the detail viewer shows the glitch video placeholder.
	print("[Animus OS] No media loaded for the place. Storing empty image_path (placeholder will show).")
	return ""

func _persist_video() -> String:
	# In edit mode and the video was not changed, keep the existing stored path.
	if not video_changed and original_picture_db_path != "" and original_picture_db_path.begins_with("user://"):
		return original_picture_db_path
	
	if loaded_video_path == "":
		return ""
	
	if not DirAccess.dir_exists_absolute("user://places"):
		DirAccess.make_dir_absolute("user://places")
	
	var timestamp = int(Time.get_unix_time_from_system())
	var clean_name = input_name.text.validate_filename().to_lower().strip_edges().replace(" ", "_")
	if clean_name == "":
		clean_name = "place"
	
	var ext = loaded_video_path.get_extension()
	var dest = "user://places/" + clean_name + "_" + str(timestamp) + "." + ext
	
	var err = DirAccess.copy_absolute(loaded_video_path, dest)
	if err == OK:
		print("[Animus OS] Place video copied successfully: ", dest)
		return dest
	else:
		print("[Error] Failed to copy place video. Code: ", err)
		return ""

func _on_save_all_btn_pressed() -> void:
	# Input validation
	if input_name.text.strip_edges() == "":
		_show_warning_popup("Error de registro: El campo 'NOMBRE' es obligatorio.")
		return
		
	if input_date.text.strip_edges() == "":
		_show_warning_popup("Error de registro: El campo 'FECHA' es obligatorio.")
		return
		
	if input_description.text.strip_escapes().strip_edges() == "":
		_show_warning_popup("Error de registro: Se requiere una 'DESCRIPCIÓN' válida para guardar el lugar.")
		return

	# Physical media processing (image crop or video persist)
	var final_picture_path = process_physical_crop()
	if media_save_failed:
		_show_warning_popup("Error crítico: No se pudo gestionar el media del lugar.")
		return

	# Database operation
	if editing_place:
		var update_query = "UPDATE places SET " + \
			"place_name = '" + input_name.text.replace("'", "''") + "', " + \
			"picture_date = '" + input_date.text.replace("'", "''") + "', " + \
			"place_description = '" + input_description.text.replace("'", "''") + "', " + \
			"personal_analyse = '" + input_analyse.text.replace("'", "''") + "', " + \
			"image_path = '" + final_picture_path + "' " + \
			"WHERE id = " + str(place_id_to_edit)
			
		DB.db.query(update_query)
		print("[Database] Place record updated. ID: ", place_id_to_edit)
		
		# Cleanup of obsolete file in user://
		if final_picture_path != original_picture_db_path and original_picture_db_path.begins_with("user://"):
			if original_picture_db_path != "" and FileAccess.file_exists(original_picture_db_path):
				DirAccess.remove_absolute(original_picture_db_path)
				print("[DISK] Previous place picture removed.")
				
		_show_success_popup("Expediente del lugar actualizado con éxito en el núcleo.")
		_restore_music()
		await get_tree().create_timer(1.5).timeout
		_exit_to_main_menu()
	else:
		var new_data = {
			"place_name": input_name.text,
			"picture_date": input_date.text,
			"place_description": input_description.text,
			"personal_analyse": input_analyse.text,
			"image_path": final_picture_path
		}
		
		var new_id = -1
		if DB.has_method("insert_place"):
			new_id = DB.insert_place(new_data)
		else:
			var insert_query = "INSERT INTO places (place_name, picture_date, place_description, personal_analyse, image_path) VALUES ('" + \
				input_name.text.replace("'", "''") + "', '" + \
				input_date.text.replace("'", "''") + "', '" + \
				input_description.text.replace("'", "''") + "', '" + \
				input_analyse.text.replace("'", "''") + "', '" + \
				final_picture_path + "')"
			DB.db.query(insert_query)
			new_id = DB.db.get_last_insert_rowid() if DB.db.has_method("get_last_insert_rowid") else 1
			
		if new_id != -1:
			print("[Database] Place inserted successfully. ID: ", new_id)
			_show_success_popup("Lugar guardado con éxito en la base de datos.")
			clear_form()
			# Reset to create mode for a new place
			editing_place = false
			Global.selected_place_id = 0
		else:
			if final_picture_path.begins_with("user://"):
				DirAccess.remove_absolute(final_picture_path)
			_show_warning_popup("Error de SQLite: No se pudo registrar el nuevo lugar.")

func clear_form():
	input_name.clear()
	input_description.text = ""
	input_analyse.text = ""
	original_picture_path = ""
	loaded_video_path = ""
	media_is_video = false
	video_changed = false
	loaded_picture_raw = null
	load_default_picture_to_viewer()

func _input(event: InputEvent) -> void:
	if not picture_editor.visible: return
	if media_is_video: return # no dragging for videos
	if original_pic.mouse_filter == Control.MOUSE_FILTER_IGNORE: return

	# Drag interactions adapted to the 460x300 crop box
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = viewer_container.get_local_mouse_position()
				if mouse_pos.x >= 0 and mouse_pos.x <= 460 and mouse_pos.y >= 0 and mouse_pos.y <= 300:
					dragging = true
			else:
				dragging = false
			
	if event is InputEventMouseMotion and dragging:
		original_pic.position += event.relative
		
		# Boundary restrictions within 460x300
		var limit_x_min = 460.0 - original_pic.size.x
		var limit_y_min = 300.0 - original_pic.size.y
		
		if limit_x_min < 0:
			original_pic.position.x = clamp(original_pic.position.x, limit_x_min, 0)
		else:
			original_pic.position.x = 0
			
		if limit_y_min < 0:
			original_pic.position.y = clamp(original_pic.position.y, limit_y_min, 0)
		else:
			original_pic.position.y = 0

func _on_select_image_btn_pressed() -> void:
	file_dialog_picture.popup_centered_clamped(Vector2(800, 600))

func _on_return_btn_pressed() -> void:
	_exit_to_main_menu()

func _exit_to_main_menu():
	Global.selected_place_id = 0
	get_tree().change_scene_to_file("res://places_scene.tscn")

func _show_warning_popup(message: String):
	if advice_popup:
		advice_popup.dialog_text = message
		advice_popup.popup_centered()

func _show_success_popup(message: String):
	if success_popup:
		success_popup.dialog_text = message
		success_popup.popup_centered()
