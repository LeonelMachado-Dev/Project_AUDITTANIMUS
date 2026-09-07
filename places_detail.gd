extends Control

@onready var name_label = $HBoxContainer/InfoDerecha/NombreLabel
@onready var date_label = $HBoxContainer/InfoDerecha/location_label
@onready var content_text = $HBoxContainer/InfoDerecha/AnimusPanel/TextoContenido
@onready var place_media: MediaViewer = $HBoxContainer/ColumnaIzquierda/PlaceMedia
@onready var glitch_timer = $GlitchTimer
@onready var glitch_sound = $GlitchSound
@onready var animus_panel: PanelAnimus = $HBoxContainer/InfoDerecha/AnimusPanel
@onready var note_button = $HBoxContainer/ColumnaIzquierda/ContenedorBotones/BtnNota
@onready var review_button = $HBoxContainer/ColumnaIzquierda/ContenedorBotones/BtnResena
@onready var volver_button = $HBoxContainer/ColumnaIzquierda/ContenedorBotones/BtnVolver
@onready var fullscreen_overlay = $FullscreenOverlay
@onready var fullscreen_viewer: MediaViewer = $FullscreenOverlay/FullscreenViewer
@onready var video_controls_bar: Control = $FullscreenOverlay/VideoControlsBar
@onready var fs_play_pause_btn: Button = $FullscreenOverlay/VideoControlsBar/HBox/PlayPauseBtn
@onready var fs_slider: HSlider = $FullscreenOverlay/VideoControlsBar/HBox/Slider
@onready var fs_time_label: Label = $FullscreenOverlay/VideoControlsBar/HBox/TimeLabel
@onready var fs_mute_btn: Button = $FullscreenOverlay/VideoControlsBar/HBox/MuteBtn

var place_data = {}
var glitch_enabled_for_current := false
var original_picture_position : Vector2
var _fs_scrubbing := false
var _fs_was_playing := false
var _fs_muted := false
var _fs_music_was := -1.0

const MUSIC_BUS := "Music"
const MUSIC_VIDEO_LEVEL := 10.0

const PLACEHOLDER_VIDEO_PATH := "res://Videos/glitch_background.mp4"

func _ready():
	glitch_timer.timeout.connect(_on_glitch_timer_timeout)
	glitch_timer.wait_time = randf_range(3.0, 7.0)
	
	
	var chosen_id = Global.selected_place_id
	var query = "SELECT * FROM places WHERE id = " + str(chosen_id)
	DB.db.query(query)
	
	if DB.db.query_result.size() > 0:
		place_data = DB.db.query_result[0]
		
		if is_instance_valid(content_text):
			content_text.modulate.a = 0.0
		if is_instance_valid(animus_panel):
			animus_panel.generar_panel(true)
			
		place_media.set_audio_muted(true)
		place_picture_render()
		basic_place_info()
		place_note()

func _animate_and_wait_button(button: Button) -> void:
	if not is_instance_valid(button): return
	button.pivot_offset = button.size / 2
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.92, 0.92), 0.02).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

# --- Fills only the fixed labels ---
func basic_place_info():
	name_label.visible_ratio = 0.0
	name_label.text = str(place_data.get("place_name", "")).to_upper()
	
	date_label.visible_ratio = 1.0
	date_label.text = ("FECHA DE LA IMAGEN: " + str(place_data.get("picture_date", ""))).to_upper()
	
	animate_title()

# --- Shows the place REVIEW (place_description) ---
func place_review():
	content_text.visible_ratio = 1.0
	content_text.bbcode_enabled = true
	content_text.clear()
	
	var desc_txt = str(place_data.get("place_description", "")).strip_edges()
	content_text.append_text(desc_txt)

# --- Shows the place NOTE (personal_analyse) - DEFAULT VIEW ---
func place_note():
	content_text.visible_ratio = 1.0
	content_text.bbcode_enabled = true
	content_text.clear()
	
	var note_txt = str(place_data.get("personal_analyse", "")).strip_edges()
	
	if note_txt == "" or note_txt == "null" or note_txt == "<null>":
		content_text.append_text("[color=#ffffff]ESTE LUGAR NO TIENE NINGUNA NOTA[/color]")
	else:
		content_text.append_text(note_txt)

func place_picture_render():
	var picture_path = str(place_data.get("image_path", ""))
	if picture_path != "" and picture_path != "null" and picture_path != "<null>" and FileAccess.file_exists(picture_path):
		if MediaViewer.is_video_file(picture_path):
			var reason: String = place_media.video_orientation_block_reason(picture_path)
			if reason != "":
				print("[Animus OS] VIDEO BLOQUEADO: ", reason, " Se usara el video de respaldo.")
				_show_placeholder_video()
				return
		var ok = place_media.display(picture_path)
		if not ok:
			_show_placeholder_video()
		else:
			glitch_enabled_for_current = not place_media.is_video()
			animate_picture()
	else:
		_show_placeholder_video()

func _show_placeholder_video():
	place_media.show_placeholder(PLACEHOLDER_VIDEO_PATH)
	glitch_enabled_for_current = false

func animate_title():
	var tween = create_tween()
	tween.tween_property(name_label, "visible_ratio", 1.0, 0.6).set_trans(Tween.TRANS_LINEAR)
	
func animate_picture():
	place_media.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(place_media, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_BOUNCE)

func _on_glitch_timer_timeout():
	if glitch_enabled_for_current:
		run_glitch()
	glitch_timer.wait_time = randf_range(4.0, 10.0)
	glitch_timer.start()

func run_glitch():
	if glitch_sound and glitch_sound.stream:
		glitch_sound.play()

	# El glitch en tiras solo aplica sobre imágenes estáticas (jpg/jpeg/png).
	var base_texture = place_media.get_displayed_texture()
	if not base_texture: return

	original_picture_position = place_media.position

	# Construimos el glitch COMO HIJO del propio contenedor de la imagen.
	# De esta forma queda confinado al área de la foto y JAMÁS invade la
	# descripción ni el resto de la escena.
	var glitch_container = Control.new()
	glitch_container.clip_contents = true
	glitch_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	place_media.image_rect.add_child(glitch_container)

	var real_texture_size = base_texture.get_size()
	var total_ui_height = place_media.size.y
	var created_strips = []
	var current_ui_y = 0.0
	
	while current_ui_y < total_ui_height:
		var strip_ui_height = randf_range(8.0, 55.0)
		if current_ui_y + strip_ui_height > total_ui_height:
			strip_ui_height = total_ui_height - current_ui_y
			
		var y_ratio = current_ui_y / total_ui_height
		var height_ratio = strip_ui_height / total_ui_height
		var texture_y = y_ratio * real_texture_size.y
		var texture_height = height_ratio * real_texture_size.y
		
		if strip_ui_height <= 1.0: break
			
		var strip = TextureRect.new()
		glitch_container.add_child(strip)
		
		var atlas_strip = AtlasTexture.new()
		atlas_strip.atlas = base_texture
		atlas_strip.region = Rect2(0, texture_y, real_texture_size.x, texture_height)
		
		strip.texture = atlas_strip
		strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		strip.stretch_mode = TextureRect.STRETCH_SCALE
		strip.size = Vector2(place_media.size.x, strip_ui_height)
		strip.position = Vector2(0, current_ui_y)
		strip.texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST
		created_strips.append(strip)
		current_ui_y += strip_ui_height

	var tween = create_tween().set_parallel(true)
	for i in range(4):
		var vibration_time = 0.03 * i
		var vibration_offset = Vector2(randf_range(-14.0, 14.0), randf_range(-12.0, 12.0))
		tween.tween_property(glitch_container, "position", original_picture_position + vibration_offset, 0.03).set_delay(vibration_time)
	
	for strip in created_strips:
		if randf() > 0.4:
			var tear_compression = randf_range(-120.0, 120.0)
			tween.tween_property(strip, "position:x", strip.position.x + tear_compression, 0.07)
			tween.tween_property(strip, "scale:x", randf_range(1.4, 2.0), 0.05).set_delay(0.07)
			var virus_color = [Color(0.1, 4.0, 4.0), Color(4.0, 0.1, 4.0), Color(5.0, 5.0, 0.1)].pick_random()
			tween.tween_property(strip, "modulate", virus_color, 0.07)
		else:
			tween.tween_property(strip, "modulate", Color(2.5, 2.5, 2.5, 0.8), 0.05)

	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(0.15)
	cleanup_tween.finished.connect(func():
		glitch_container.queue_free()
	)

# --- FULLSCREEN MEDIA VIEWER ---
func _on_place_media_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_open_fullscreen()

func _open_fullscreen():
	# Reproduce la misma fuente en grande, oscureciendo el fondo.
	var src_path = place_media.current_path
	var ok = false

	if src_path != "" and FileAccess.file_exists(src_path) and not place_media.is_placeholder():
		if place_media.is_video():
			place_media.pause()
		fullscreen_viewer.display(src_path)
		ok = true

	if not ok:
		if place_media.is_placeholder():
			# Placeholder glitch video (mp4 via FFmpeg) o imagen de respaldo.
			fullscreen_viewer.show_placeholder(PLACEHOLDER_VIDEO_PATH)
			ok = true
		else:
			var tx: Texture2D = place_media.get_displayed_texture()
			if tx:
				fullscreen_viewer.display_texture(tx)
				ok = true

	fullscreen_overlay.visible = true
	_setup_fs_controls()
	_lower_music_for_video()

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

func _lower_music_for_video():
	# Para que se oiga el video del reproductor, la musica de fondo se baja a 30% max.
	if not fullscreen_viewer.is_video():
		return
	if _fs_music_was >= 0.0:
		return
	_fs_music_was = _get_music_percent()
	if _fs_music_was > MUSIC_VIDEO_LEVEL + 0.001:
		_set_music_percent(MUSIC_VIDEO_LEVEL)
	else:
		_fs_music_was = -1.0

func _restore_music():
	if _fs_music_was >= 0.0:
		_set_music_percent(_fs_music_was)
	_fs_music_was = -1.0

func _setup_fs_controls():
	var is_video := fullscreen_viewer.is_video()
	video_controls_bar.visible = is_video
	if not is_video:
		return
	fullscreen_viewer.set_audio_muted(_fs_muted)
	var dur := fullscreen_viewer.get_media_duration()
	fs_slider.max_value = maxf(dur, 1.0)
	fs_slider.set_value_no_signal(clampf(fullscreen_viewer.get_media_position(), 0.0, fs_slider.max_value))
	_sync_fs_controls()

func _sync_fs_controls():
	if is_instance_valid(fs_play_pause_btn):
		fs_play_pause_btn.text = "PAUSAR" if fullscreen_viewer.is_media_playing() else "REANUDAR"
	if is_instance_valid(fs_mute_btn):
		fs_mute_btn.text = "CON SONIDO" if _fs_muted else "SILENCIAR"

func _process(_delta: float) -> void:
	if not fullscreen_overlay.visible or not fullscreen_viewer.is_video():
		return
	if video_controls_bar == null or not video_controls_bar.visible:
		return
	if _fs_scrubbing:
		if is_instance_valid(fs_time_label):
			fs_time_label.text = "%s / %s" % [_format_time(fs_slider.value), _format_time(fullscreen_viewer.get_media_duration())]
		return
	var pos := fullscreen_viewer.get_media_position()
	var dur := fullscreen_viewer.get_media_duration()
	if is_instance_valid(fs_slider):
		fs_slider.max_value = maxf(dur, 1.0)
		fs_slider.set_value_no_signal(clampf(pos, 0.0, fs_slider.max_value))
	if is_instance_valid(fs_time_label):
		fs_time_label.text = "%s / %s" % [_format_time(pos), _format_time(dur)]

func _format_time(seconds: float) -> String:
	if seconds < 0.0:
		seconds = 0.0
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]

func _on_fs_play_pause_pressed():
	if not fullscreen_viewer.is_video():
		return
	if fullscreen_viewer.is_media_playing():
		fullscreen_viewer.pause()
	else:
		fullscreen_viewer.play()
	_sync_fs_controls()

func _on_fs_mute_pressed():
	_fs_muted = not _fs_muted
	fullscreen_viewer.set_audio_muted(_fs_muted)
	_sync_fs_controls()

func _seek_fullscreen(pos: float) -> void:
	var was_playing: bool = fullscreen_viewer.is_media_playing()
	fullscreen_viewer.pause()
	fullscreen_viewer.set_media_position(pos)
	if was_playing:
		fullscreen_viewer.play()
	_sync_fs_controls()

func _on_fs_slider_value_changed(value: float):
	if _fs_scrubbing:
		return
	if fullscreen_viewer.is_video():
		_seek_fullscreen(value)

func _on_fs_slider_drag_started():
	_fs_scrubbing = true
	_fs_was_playing = fullscreen_viewer.is_media_playing()
	fullscreen_viewer.pause()
	if is_instance_valid(fs_play_pause_btn):
		fs_play_pause_btn.text = "REANUDAR"

func _on_fs_slider_drag_ended(_value_changed: bool):
	_fs_scrubbing = false
	var was_playing: bool = _fs_was_playing
	if fullscreen_viewer.is_video():
		fullscreen_viewer.pause()
		fullscreen_viewer.set_media_position(fs_slider.value)
		if was_playing:
			fullscreen_viewer.play()
	_sync_fs_controls()

func _on_fullscreen_close_pressed():
	_close_fullscreen()

func _on_fullscreen_dim_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_fullscreen()

func _exit_tree():
	_restore_music()

func _close_fullscreen():
	_fs_scrubbing = false
	_restore_music()
	fullscreen_viewer.clear()
	fullscreen_overlay.visible = false
	if place_media.is_video():
		place_media.play()

# --- SIGNALS ---
func _on_btn_note_pressed():
	await _animate_and_wait_button(note_button)
	place_note()

func _on_btn_review_pressed():
	await _animate_and_wait_button(review_button)
	place_review()

func _on_back_button_pressed():
	Global.selected_place_id = 0
	get_tree().change_scene_to_file("res://places_scene.tscn")
