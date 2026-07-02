extends Control
@onready var acceptBtn = $UnavailablePanel/MainContainer/AcceptBtn
@onready var main_container = $UnavailablePanel/MainContainer
@onready var unavailable_panel = $UnavailablePanel
@onready var panel_text = $UnavailablePanel/MainContainer/Text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if unavailable_panel:
		unavailable_panel.visible = false
	
func panel_tex():
	if not is_instance_valid(panel_text):
		return

	# Detectamos el idioma actual del sistema o del archivo .cfg
	var idioma_actual = TranslationServer.get_locale()

	var disclaimer_es = """Project Audittanimus es un sistema libre de lucro, un fan-project creado por un fan para fans de la franquicia Assassin's Creed. Todo archivo del juego, inspiración o similitud a la franquicia de Ubisoft es de su propiedad. 

NO DISTRIBUIR CON FINES DE LUCRO. PROYECTO DE UN FAN PARA FANS DE LA FRANQUICIA."""

	# Tu texto traducido al Inglés de forma profesional
	var disclaimer_en = """Project Audittanimus is a non-profit system, a fan-project created by a fan for fans of the Assassin's Creed franchise. Every game file, inspiration, or similarity to the Ubisoft franchise belongs to them. 

DO NOT DISTRIBUTE FOR PROFIT. A PROJECT BY A FAN FOR FANS OF THE FRANCHISE."""

	# Cambiamos el texto según el idioma actual
	if idioma_actual.begins_with("en"):
		panel_text.text = disclaimer_en
	else:
		panel_text.text = disclaimer_es
