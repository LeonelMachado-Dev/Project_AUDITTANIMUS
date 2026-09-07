class_name MediaViewer
extends Control

@onready var image_rect: TextureRect = $ImageRect
@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var placeholder_layer: ColorRect = $PlaceholderLayer

var mp4_player: Control = null

var current_path: String = ""
var current_is_video: bool = false
var current_is_placeholder: bool = false
var current_is_mp4: bool = false
var freeze_on_frame: bool = false
var _audio_muted: bool = false

const VIDEO_EXTENSIONS: Array[String] = ["mp4", "webm", "ogv", "ogg", "avi", "mov", "m4v", "mkv"]
const IMAGE_EXTENSIONS: Array[String] = ["jpg", "jpeg", "png", "bmp", "webp"]
const MP4_EXTENSIONS: Array[String] = ["mp4", "mov", "m4v", "avi", "mkv"]

func _ready() -> void:
	image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_rect.texture = null
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.visible = false
	placeholder_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder_layer.color = Color(0, 0, 0, 0)
	placeholder_layer.visible = false
	_setup_mp4_player()

func _setup_mp4_player() -> void:
	if mp4_player != null:
		return
	var script: GDScript = load("res://addons/MP4Player/MP4VideoPlayer.gd")
	if script == null:
		return
	var node: Control = Control.new()
	node.set_script(script)
	node.name = "MP4VideoPlayer"
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	mp4_player = node

func _mp4_available() -> bool:
	return mp4_player != null and mp4_player.get("player") != null

func display(path: String) -> bool:
	clear()
	if path == "" or path == "null" or path == "<null>":
		return false

	if _is_video_path(path):
		if _is_mp4_path(path):
			return _display_mp4(path)
		var stream: VideoStream = load(path)
		if stream == null:
			return false
		video_player.stream = stream
		video_player.visible = true
		video_player.autoplay = true
		video_player.play()
		_apply_audio_volume()
		current_path = path
		current_is_video = true
		current_is_mp4 = false
		return true

	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image:
			image_rect.texture = ImageTexture.create_from_image(image)
			image_rect.visible = true
			current_path = path
			current_is_video = false
			current_is_mp4 = false
			return true

	# Fallback: allow already-imported textures (e.g. res:// AnimatedTexture for gif)
	var imported: Resource = load(path)
	if imported is Texture2D:
		image_rect.texture = imported
		image_rect.visible = true
		current_path = path
		current_is_video = false
		current_is_mp4 = false
		return true

	return false

func display_texture(texture: Texture2D) -> void:
	clear()
	if texture == null:
		return
	image_rect.texture = texture
	image_rect.visible = true
	current_is_video = false

func display_video_path(path: String) -> bool:
	clear()
	if _is_mp4_path(path):
		return _display_mp4(path)
	var stream: VideoStream = load(path)
	if stream == null:
		return false
	video_player.stream = stream
	video_player.visible = true
	video_player.autoplay = true
	video_player.play()
	_apply_audio_volume()
	current_path = path
	current_is_video = true
	current_is_mp4 = false
	return true

func _display_mp4(path: String, loop: bool = true) -> bool:
	if not _mp4_available():
		return false
	if mp4_player.get("loop_enabled") != null:
		mp4_player.set("loop_enabled", loop)
	var ok: bool = mp4_player.call("open", path)
	if not ok:
		return false
	_apply_audio_volume()
	mp4_player.call("play")
	mp4_player.visible = true
	current_path = path
	current_is_video = true
	current_is_mp4 = true
	return true

func _apply_audio_volume() -> void:
	var vol: float = -80.0 if _audio_muted else -14.0
	if mp4_player != null and mp4_player.get("audio_player") != null:
		mp4_player.get("audio_player").volume_db = vol
	video_player.volume_db = -80.0 if _audio_muted else 0.0

# Silencia (muted=true) o restaura el audio del video (mp4/ffmpeg o VideoStreamPlayer).
func set_audio_muted(muted: bool) -> void:
	_audio_muted = muted
	_apply_audio_volume()

func show_placeholder(placeholder_res) -> bool:
	clear()
	if placeholder_res is Texture2D:
		image_rect.texture = placeholder_res
		image_rect.visible = true
		current_is_placeholder = true
		return true
	if placeholder_res is String:
		return show_placeholder_path(placeholder_res)
	# Assume it's a VideoStream
	if placeholder_res is VideoStream:
		video_player.stream = placeholder_res
		video_player.visible = true
		video_player.autoplay = true
		video_player.play()
		_apply_audio_volume()
		current_is_placeholder = true
		return true
	current_is_placeholder = false
	return false

func show_placeholder_path(path: String) -> bool:
	clear()
	if _is_mp4_path(path):
		if _display_mp4(path, true):
			current_is_placeholder = true
			return true
		return false
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image:
			image_rect.texture = ImageTexture.create_from_image(image)
			image_rect.visible = true
			current_is_placeholder = true
			return true
	var stream: VideoStream = load(path)
	if stream != null:
		video_player.stream = stream
		video_player.visible = true
		video_player.autoplay = true
		video_player.play()
		_apply_audio_volume()
		current_is_placeholder = true
		return true
	return false

func clear() -> void:
	image_rect.texture = null
	image_rect.visible = false
	video_player.stop()
	video_player.stream = null
	video_player.visible = false
	if mp4_player != null and mp4_player.get("player") != null:
		mp4_player.call("stop")
		mp4_player.visible = false
	placeholder_layer.visible = false
	current_is_placeholder = false
	current_path = ""
	current_is_video = false
	current_is_mp4 = false

func play() -> void:
	freeze_on_frame = false
	if current_is_video:
		if current_is_mp4:
			if mp4_player != null and mp4_player.call("is_playing") == false:
				mp4_player.call("play")
		elif not video_player.is_playing():
			video_player.play()

func pause() -> void:
	if current_is_video:
		if current_is_mp4:
			if mp4_player != null:
				mp4_player.call("pause")
		elif video_player.is_playing():
			video_player.pause()

# Congela el video en cuanto se decodifica el primer fotograma util (para tarjetas inactivas).
func request_freeze_on_frame() -> void:
	if current_is_mp4 and freeze_on_frame == false:
		freeze_on_frame = true

func _process(_delta: float) -> void:
	if freeze_on_frame and current_is_mp4 and mp4_player != null:
		var frame: Texture2D = mp4_player.call("get_frame_texture")
		if frame != null:
			freeze_on_frame = false
			mp4_player.call("pause")

# --- Fullscreen player helpers (mp4 via FFmpeg + VideoStreamPlayer fallback) ---
func get_media_position() -> float:
	if current_is_mp4 and mp4_player != null:
		return float(mp4_player.call("get_video_position"))
	return video_player.stream_position

func get_media_duration() -> float:
	if current_is_mp4 and mp4_player != null:
		return float(mp4_player.call("get_video_duration"))
	var stream: VideoStream = video_player.stream
	return stream.get_duration() if stream else 0.0

func set_media_position(seconds: float) -> bool:
	if current_is_mp4 and mp4_player != null:
		return bool(mp4_player.call("seek", seconds))
	video_player.stream_position = seconds
	return true

func is_media_playing() -> bool:
	if current_is_mp4 and mp4_player != null:
		return bool(mp4_player.call("is_playing"))
	return video_player.is_playing()

func is_video() -> bool:
	return current_is_video

func is_placeholder() -> bool:
	return current_is_placeholder

func get_displayed_texture() -> Texture2D:
	return image_rect.texture

func get_displayed_stream() -> VideoStream:
	return video_player.stream

func _is_video_path(path: String) -> bool:
	return path.get_extension().to_lower() in VIDEO_EXTENSIONS

func _is_mp4_path(path: String) -> bool:
	return path.get_extension().to_lower() in MP4_EXTENSIONS

# Rotation/signature helpers reused by other scripts
static func is_video_file(path: String) -> bool:
	return path.get_extension().to_lower() in ["mp4", "webm", "ogv", "ogg", "avi", "mov", "m4v", "mkv"]

static func is_mp4_file(path: String) -> bool:
	return path.get_extension().to_lower() in ["mp4", "mov", "m4v", "avi", "mkv"]

static func is_image_file(path: String) -> bool:
	return path.get_extension().to_lower() in ["jpg", "jpeg", "png", "bmp", "webp"]

# Devuelve las dimensiones (WxH) de un video. Solo los formatos mp4/ffmpeg
# permiten leerlas directamente (probe de decodificador). Si no se puede
# determinar, devuelve Vector2i.ZERO (se interpreta como "desconocido").
func get_video_dimensions(path: String) -> Vector2i:
	var ext: String = path.get_extension().to_lower()
	if ext not in MP4_EXTENSIONS:
		return Vector2i.ZERO
	if not _mp4_available():
		return Vector2i.ZERO
	var probe := Control.new()
	probe.set_script(load("res://addons/MP4Player/MP4VideoPlayer.gd"))
	probe.name = "_ProbeDims"
	probe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(probe)
	probe.set("loop_enabled", false)
	var ok: bool = probe.call("open", path)
	var dims := Vector2i.ZERO
	if ok:
		var audio = probe.get("audio_player")
		if audio != null:
			audio.volume_db = -80.0
		var w: int = int(probe.call("get_video_width"))
		var h: int = int(probe.call("get_video_height"))
		if w > 0 and h > 0:
			dims = Vector2i(w, h)
	probe.call("stop")
	probe.queue_free()
	return dims

# Razón de bloqueo de un video vertical. Devuelve "" si el video es permitido
# (horizontal, 16:9 o similar) o si no se pueden conocer sus dimensiones.
func video_orientation_block_reason(path: String) -> String:
	var dims := get_video_dimensions(path)
	if dims == Vector2i.ZERO:
		return ""
	if dims.y <= dims.x:
		return ""
	return "El video '%s' es vertical (%dx%d). Solo se admiten videos horizontales 16:9." % [path.get_file(), dims.x, dims.y]

# Devuelve la duracion (segundos) de un video mp4/ffmpeg (probe de decodificador).
# Devuelve 0.0 si no se puede determinar (formato desconocido o fallo de apertura).
func get_video_duration(path: String) -> float:
	var ext: String = path.get_extension().to_lower()
	if ext not in MP4_EXTENSIONS:
		return 0.0
	if not _mp4_available():
		return 0.0
	var probe := Control.new()
	probe.set_script(load("res://addons/MP4Player/MP4VideoPlayer.gd"))
	probe.name = "_ProbeDur"
	probe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(probe)
	probe.set("loop_enabled", false)
	var ok: bool = probe.call("open", path)
	var duration := 0.0
	if ok:
		var audio = probe.get("audio_player")
		if audio != null:
			audio.volume_db = -80.0
		duration = float(probe.call("get_video_duration"))
	probe.call("stop")
	probe.queue_free()
	return duration
