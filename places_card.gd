extends Button

@onready var media_viewer = $MediaViewer
@onready var name_label = $Label

# Place information loaded from the database
var place_data = {}

func configure(data):
	place_data = data
	
	# 1. Place name
	var place_name = data.get("place_name", "")
	name_label.text = place_name.to_upper()
	
	# 2. Videos on cards are always silent (only the central one plays).
	media_viewer.set_audio_muted(true)
	
	# 3. Load panoramic picture from external path (user://...)
	var picture_path = data.get("image_path", "")
	
	if picture_path != "" and FileAccess.file_exists(picture_path):
		var ext = picture_path.get_extension().to_lower()
		if MediaViewer.is_video_file(picture_path):
			# Los videos verticales NO se cargan: la tarjeta es horizontal (16:9).
			var reason: String = media_viewer.video_orientation_block_reason(picture_path)
			if reason != "":
				print("[Animus OS] VIDEO BLOQUEADO: ", reason, " Se usara la imagen generica en la tarjeta.")
				load_default_picture()
				return
			# The place media is a video -> play it, freezing at the first frame
			# until the card becomes active (set_active()).
			if media_viewer.display(picture_path):
				media_viewer.request_freeze_on_frame()
				return
			load_default_picture()
			return
		if ext == "gif":
			# Animated GIFs are not animated reliably from external paths.
			load_default_picture()
			return
		if media_viewer.display(picture_path):
			return
		print("[Animus OS] Error processing place picture: ", picture_path)
		load_default_picture()
		return
		
	load_default_picture()

func load_default_picture():
	if media_viewer != null and ResourceLoader.exists("res://Images/no_place.jpg"):
		media_viewer.display_texture(load("res://Images/no_place.jpg"))
	elif media_viewer != null:
		media_viewer.clear()

# Only the active (central) card plays its video; the rest stay frozen.
func set_active(active: bool) -> void:
	if media_viewer == null or not media_viewer.is_video():
		return
	if active:
		media_viewer.play()
	else:
		media_viewer.pause()

func go_to_details():
	var place_name = place_data.get("place_name", "").to_upper()
	print("[Animus OS] Place selected: ", place_name)
	
	# Store the ID in the Global autoload (dedicated for Places)
	Global.selected_place_id = place_data.get("id", 0)
	print("[Animus OS] Loading place data ID: ", Global.selected_place_id)
	
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		main_loop.change_scene_to_file("res://places_detail.tscn")
