extends Control

const RUTA_CONFIG = "user://config_animus.cfg"

# Referencias a tus botones físicos en la escena
@onready var EspañolBtn: Button = $CanvasLayer/ColorRect/AnimusPanel/EspañolBtn
@onready var EnglishBtn: Button = $CanvasLayer/ColorRect/AnimusPanel/EnglishBtn

func _ready() -> void:
	# Conectamos las señales de "pressed" de tus botones visuales a las funciones
	EspañolBtn.pressed.connect(_on_btn_espanol_pressed)
	EnglishBtn.pressed.connect(_on_btn_ingles_pressed)
	
	# Opcional: Si quieres que tus botones tengan el comportamiento de foco por click que tenías
	EspañolBtn.focus_mode = Control.FOCUS_CLICK
	EnglishBtn.focus_mode = Control.FOCUS_CLICK

func _on_btn_espanol_pressed() -> void:
	_aplicar_cambio_idioma("es")

func _on_btn_ingles_pressed() -> void:
	_aplicar_cambio_idioma("en")

func _aplicar_cambio_idioma(codigo_idioma: String) -> void:
	Global.reproducir_tick()
	TranslationServer.set_locale(codigo_idioma)
	
	# Al guardar esto, el script 'boot.gd' sabrá en el próximo inicio que no es la primera vez
	guardar_preferencia("Localization", "idioma", codigo_idioma)
	
	# Pasamos al menú principal
	get_tree().change_scene_to_file("res://main_menu.tscn")

# Reutilizamos tu lógica exacta para escribir el archivo .cfg
func guardar_preferencia(seccion: String, clave: String, valor: Variant) -> void:
	var config = ConfigFile.new()
	config.load(RUTA_CONFIG) # Si no existe, Godot lo crea automáticamente al guardar
	config.set_value(seccion, clave, valor)
	config.save(RUTA_CONFIG)
