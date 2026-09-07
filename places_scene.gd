extends Control

@onready var background = $Background
@onready var fog = $NeblinaAnimus
@onready var card_container = $Interface/PlacesCarrousel/Carrousel
#@onready var click_effect = $click_effect
@onready var confirm_popup = $PopUpConfirmacion
@onready var delete_button = $Interface/deletePlacesBtn
@onready var delete_status_label = $Interface/status
@onready var label_BG = $Interface/Label_BG
@onready var edit_button = $Interface/editPlacesBtn
@onready var back_button = $Interface/backBtn
@onready var add_button = $Interface/addPlacesBtn
@onready var browser_field = $Interface/browser
var last_spin_time : float = 0.0
var filtered_list = [] # Temporary box for the filtered cards while filtering
var entrance_scene = preload("res://places_card.tscn")
var delete_mode_active: bool = false
var card_to_delete = null
enum InterfaceState { NORMAL, PURGE_MODE, WAITING_CONFIRMATION, EDIT_MODE }
var current_state = InterfaceState.NORMAL
# --- CAROUSEL -----------------------------------------------------------------
var instances_list = []
var central_index = 0
var horizontal_spacing = 340
var background_scale = 0.65
var background_opacity = 0.25

# --- arrow animation ---
@onready var left_arrow = $Interface/leftBtn
@onready var right_arrow = $Interface/rightBtn

# Original position variables correctly declared to fix the errors
var original_left_arrow_pos: Vector2
var original_right_arrow_pos: Vector2
var left_tween: Tween
var right_tween: Tween
# --- CRITICAL SOLUTION: ANIMATION ISOLATION PROPERTIES ---
# We animate these variables instead of the node's physical position to avoid corrupting Godot's anchors
var dynamic_left_offset: Vector2 = Vector2.ZERO:
	set(val):
		dynamic_left_offset = val
		if is_instance_valid(left_arrow):
			left_arrow.position = original_left_arrow_pos + dynamic_left_offset

var dynamic_right_offset: Vector2 = Vector2.ZERO:
	set(val):
		dynamic_right_offset = val
		if is_instance_valid(right_arrow):
			right_arrow.position = original_right_arrow_pos + dynamic_right_offset

func _ready():
	label_BG.visible = false
	resize_animus_screen()
	central_index = 0
	Global.selected_place_id = 0
	fill_list()

	if browser_field:
		browser_field.placeholder_text = "FILTRO DE LUGARES"
	
	if confirm_popup:
		confirm_popup.get_ok_button().text = "CONFIRMAR"
		confirm_popup.get_cancel_button().text = "CANCELAR"
		
		if not confirm_popup.confirmed.is_connected(_on_delete_confirmed):
			confirm_popup.confirmed.connect(_on_delete_confirmed)
		if not confirm_popup.canceled.is_connected(_on_delete_canceled):
			confirm_popup.canceled.connect(_on_delete_canceled)
	
	if delete_button and not delete_button.pressed.is_connected(_on_delete_button_pressed):
		delete_button.pressed.connect(_on_delete_button_pressed)
		
	if edit_button and not edit_button.pressed.is_connected(_on_edit_button_pressed):
		edit_button.pressed.connect(_on_edit_button_pressed)
		
	if back_button:
		back_button.text = "REGRESAR"
		
	if add_button:
		add_button.text = "AÑADIR"
		
	if edit_button:
		edit_button.text = "EDITAR"
	
	if delete_button:
		delete_button.text = "BORRAR"
		
	get_tree().root.size_changed.connect(resize_animus_screen)
	
	# We force a one-frame wait to make sure the initial layout is correct
	await get_tree().process_frame
	reset_reference_positions()

func _animate_and_wait_button(button: Button) -> void:
	if not is_instance_valid(button): return
	
	# Ensure the pivot in the center
	button.pivot_offset = button.size / 2
	
	var tween = create_tween()
	
	# 1. Shrink ultra fast (0.02 seconds)
	tween.tween_property(button, "scale", Vector2(0.92, 0.92), 0.02)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# 2. Return to original size with a firm pop (0.08 seconds)
	tween.tween_property(button, "scale", Vector2.ONE, 0.08)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	# Total wait time of only 0.1 seconds before doing the action
	await tween.finished

func resize_animus_screen():
	var screen_size = get_viewport_rect().size
	if background: background.size = screen_size
	if fog: fog.size = screen_size
	if card_container: card_container.position = screen_size / 2
	
	# 1. Kill immediately any running tween (of floating or clicks)
	if left_tween: left_tween.kill()
	if right_tween: right_tween.kill()
	
	# 2. Reset the dynamic offsets to zero
	dynamic_left_offset = Vector2.ZERO
	dynamic_right_offset = Vector2.ZERO
	
	# --- FORCED REPOSITIONING OF ARROWS IN THEIR RESPECTIVE SIDES ---
	var side_margin = 50.0 # Raise this number to move the arrows toward the center, lower it to stick them to the edge
	
	if left_arrow:
		var left_height = left_arrow.size.y if "size" in left_arrow else 0.0
		left_arrow.position = Vector2(side_margin, (screen_size.y / 2) - (left_height / 2))
		
	if right_arrow:
		var right_width = right_arrow.size.x if "size" in right_arrow else 0.0
		var right_height = right_arrow.size.y if "size" in right_arrow else 0.0
		right_arrow.position = Vector2(screen_size.x - side_margin - right_width, (screen_size.y / 2) - (right_height / 2))
	
	# 3. Wait safely one frame for the engine to process the changes
	await get_tree().process_frame
	
	# 4. Capture the new stable physical references and restart the smooth loops
	reset_reference_positions()
	
func reset_reference_positions():
	# Save the clean position calculated dynamically by code
	if left_arrow: original_left_arrow_pos = left_arrow.position
	if right_arrow: original_right_arrow_pos = right_arrow.position
	
	# Start the floating loops from the new stable base
	start_arrows_loop()

# --- CRITICAL INPUT INTERCEPTOR ---
func _on_card_pressed_in_carousel(pressed_card):
	if filtered_list.find(pressed_card) != central_index:
		return

	match current_state:
		InterfaceState.NORMAL:
			if pressed_card.has_method("go_to_details"):
				pressed_card.go_to_details()
				
		InterfaceState.PURGE_MODE:
			card_to_delete = pressed_card
			var place_name = pressed_card.place_data.get("place_name", "Desconocido")
			
			if confirm_popup:
				confirm_popup.dialog_text = "¿SEGURO QUE QUIERE BORRAR EL LUGAR: " + place_name.to_upper()
				confirm_popup.popup_centered()
				
		InterfaceState.EDIT_MODE:
			# Store the ID in the Global autoload (dedicated for Places)
			Global.selected_place_id = pressed_card.place_data["id"]
			print("[SYSTEM] Preparing edit for the place ID: ", Global.selected_place_id)
			
			get_tree().change_scene_to_file("res://places_editor.tscn")

func fill_list():
	for child in card_container.get_children():
		child.queue_free()
	instances_list.clear()

	var places = DB.get_places()
	for s in places:
		var new_card = entrance_scene.instantiate()
		card_container.add_child(new_card)
		new_card.configure(s)
		
		# Force it to intercept BEFORE the main script
		new_card.pressed.connect(func(): _on_card_pressed_in_carousel(new_card))
		new_card.pressed.connect(Global.reproducir_tick)
		
		instances_list.append(new_card)
	
	filtered_list = instances_list.duplicate()
	update_carousel_positions(false)

func _on_delete_button_pressed() -> void:
	Global.reproducir_tick()
	await _animate_and_wait_button(delete_button) # Elastic effect
	if current_state == InterfaceState.NORMAL:
		current_state = InterfaceState.PURGE_MODE
		
		if delete_status_label:
			delete_status_label.text = "MODO BORRAR"
			delete_status_label.modulate = Color("ff4d47ff")
			
		if label_BG:
			label_BG.visible = true
	else:
		current_state = InterfaceState.NORMAL
		reset_delete_interface()
		
func _on_edit_button_pressed() -> void:
	Global.reproducir_tick()
	await _animate_and_wait_button(edit_button) # Elastic effect
	if current_state == InterfaceState.NORMAL:
		current_state = InterfaceState.EDIT_MODE
		if label_BG:
			label_BG.visible = true
		if delete_status_label:
			delete_status_label.text = "MODO EDITAR"
			delete_status_label.modulate = Color("54d2faff")
	else:
		current_state = InterfaceState.NORMAL
		reset_delete_interface()

# --- POP-UP RESPONSES (YES / NO) ---
func _on_delete_confirmed():
	Global.reproducir_tick()
	if card_to_delete and card_to_delete.place_data.has("id"):
		var place_id = card_to_delete.place_data["id"]
		DB.eliminar_lugar(place_id)
		print("Place deleted successfully from the record.")
		
		# Clear the delete mode
		current_state = InterfaceState.NORMAL
		reset_delete_interface()
		
		if central_index >= filtered_list.size() - 1 and central_index > 0:
			central_index -= 1
			
		fill_list()
	card_to_delete = null

func _on_delete_canceled():
	Global.reproducir_tick()
	print("Operation safely canceled.")
	current_state = InterfaceState.NORMAL
	reset_delete_interface()
	card_to_delete = null

func reset_delete_interface():
	if delete_status_label:
		delete_status_label.text = ""
	label_BG.visible = false

# --- GENERAL CAROUSEL INPUTS ---
func _unhandled_input(event: InputEvent) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_spin_time < 0.25: return
	
	if event.is_action_pressed("ui_left_animus"):
		last_spin_time = current_time
		_on_left_btn_pressed()
	elif event.is_action_pressed("ui_right_animus"):
		last_spin_time = current_time
		_on_right_btn_pressed()

func _on_browser_text_changed(new_text: String) -> void:
	filtered_list.clear()
	var search_text = new_text.strip_edges().to_lower()
	for card in instances_list:
		var place_name = (card.place_data.get("place_name", "")).to_lower()
		if search_text == "" or search_text in place_name:
			card.visible = true
			filtered_list.append(card)
		else:
			card.visible = false
			card.set_active(false)
	if filtered_list.size() > 0:
		central_index = clampi(central_index, 0, filtered_list.size() - 1)
	else:
		central_index = 0
	update_carousel_positions(true)

func update_carousel_positions(animated: bool = true):
	var total_elements = filtered_list.size()
	if total_elements == 0: return
	for i in range(total_elements):
		var card = filtered_list[i]
		var distance_to_center = i - central_index
		var half_limit = float(total_elements) / 2.0
		if distance_to_center > half_limit: distance_to_center -= total_elements
		elif distance_to_center < -half_limit: distance_to_center += total_elements
		var target_x = distance_to_center * horizontal_spacing
		var target_y = abs(distance_to_center) * 30
		var scale_factor = max(1.0 - (abs(distance_to_center) * (1.0 - background_scale)), background_scale)
		var opacity_factor = max(1.0 - (abs(distance_to_center) * (1.0 - background_opacity)), background_opacity)
		card.z_index = 10 - abs(distance_to_center)
		card.disabled = (distance_to_center != 0)
		if animated:
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var final_position = Vector2(target_x, target_y) - (card.size * scale_factor / 2)
			tween.tween_property(card, "position", final_position, 0.4)
			tween.tween_property(card, "scale", Vector2(scale_factor, scale_factor), 0.4)
			tween.tween_property(card, "modulate:a", opacity_factor, 0.4)
		else:
			var card_size = card.size if "size" in card else Vector2.ZERO
			card.scale = Vector2(scale_factor, scale_factor)
			card.position = Vector2(target_x, target_y) - (card_size * scale_factor / 2)
			card.modulate.a = opacity_factor

	# Only the active (central) card plays its media; the rest stay frozen.
	for i in range(total_elements):
		filtered_list[i].set_active(i == central_index)

func start_arrows_loop():
	if left_tween: left_tween.kill()
	if right_tween: right_tween.kill()

	# Reset the internal offsets to start the loop clean
	dynamic_left_offset = Vector2.ZERO
	dynamic_right_offset = Vector2.ZERO

	# --- LEFT ARROW LOOP (Animating isolated property) ---
	if left_arrow:
		left_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		left_tween.tween_property(self, "dynamic_left_offset", Vector2(-12, 0), 0.8)
		left_tween.tween_property(self, "dynamic_left_offset", Vector2.ZERO, 0.8)

	# --- RIGHT ARROW LOOP (Animating isolated property) ---
	if right_arrow:
		right_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		right_tween.tween_property(self, "dynamic_right_offset", Vector2(12, 0), 0.8)
		right_tween.tween_property(self, "dynamic_right_offset", Vector2.ZERO, 0.8)
		
func _on_back_btn_pressed() -> void:
	Global.reproducir_tick()
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_add_places_btn_pressed() -> void:
	Global.reproducir_tick()
	
	# Force the safety reset. 0 means "New Record"
	Global.selected_place_id = 0
	print("[SYSTEM] Opening the editor in mode: CREATE NEW PLACE")
	
	get_tree().change_scene_to_file("res://places_editor.tscn")

func _on_right_btn_pressed() -> void:
	if filtered_list.size() == 0: return

	if right_arrow and right_arrow.has_focus():
		right_arrow.release_focus()
		
	central_index = (central_index + 1) % filtered_list.size()
	update_carousel_positions(true)
	
	if right_arrow:
		if right_tween: right_tween.kill()
		dynamic_right_offset = Vector2.ZERO
		
		# Animate the elastic bounce using the global control variable 'right_tween'
		right_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		right_tween.tween_property(self, "dynamic_right_offset", Vector2.ZERO, 0.25).from(Vector2(20, 0))
		right_tween.tween_callback(start_arrows_loop)

func _on_left_btn_pressed():
	if filtered_list.size() == 0: return

	if left_arrow and left_arrow.has_focus():
		left_arrow.release_focus()
		
	central_index = (central_index - 1 + filtered_list.size()) % filtered_list.size()
	update_carousel_positions(true)
	
	if left_arrow:
		if left_tween: left_tween.kill()
		dynamic_left_offset = Vector2.ZERO
		
		# Animate the elastic bounce using the global control variable 'left_tween'
		left_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		left_tween.tween_property(self, "dynamic_left_offset", Vector2.ZERO, 0.25).from(Vector2(-20, 0))
		left_tween.tween_callback(start_arrows_loop)
