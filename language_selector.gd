extends Control

const RUTA_CONFIG = "user://config_animus.cfg"

# Referencias a tus botones físicos en la escena
@onready var animus_panel = $CanvasLayer/ColorRect/AnimusPanel # Ajusta el nombre si se llama diferente en tu árbol
@onready var headerLabel: Label = $CanvasLayer/ColorRect/AnimusPanel/headerLabel
@onready var EspañolBtn: Button = $CanvasLayer/ColorRect/AnimusPanel/EspañolBtn
@onready var EnglishBtn: Button = $CanvasLayer/ColorRect/AnimusPanel/EnglishBtn

func _ready() -> void:
	# Conectamos las señales de "pressed" de tus botones visuales a las funciones
	EspañolBtn.pressed.connect(_on_btn_espanol_pressed)
	EnglishBtn.pressed.connect(_on_btn_ingles_pressed)
	
	# Opcional: Si quieres que tus botones tengan el comportamiento de foco por click que tenías
	EspañolBtn.focus_mode = Control.FOCUS_CLICK
	EnglishBtn.focus_mode = Control.FOCUS_CLICK
	
	# Preparamos la interfaz oculta al arrancar
	headerLabel.modulate.a = 0.0
	EspañolBtn.modulate.a = 0.0
	EnglishBtn.modulate.a = 0.0
	
	# Llamamos a nuestra propia animación sincronizada con los tiempos del panel
	animar_interfaz_usuario()
	
func animar_interfaz_usuario() -> void:
	# Leemos los tiempos exactos configurados en tu panel para que no queden valores "hardcodeados"
	var tiempo_espera = animus_panel.tiempo_espera_texto
	var duracion = animus_panel.duracion_aparicion_texto
	
	var tween = create_tween().set_parallel(true)
	
	# Aparece el título
	tween.tween_property(headerLabel, "modulate:a", 1.0, duracion)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_delay(tiempo_espera)
		
	# Aparece el botón Español
	tween.tween_property(EspañolBtn, "modulate:a", 1.0, duracion)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_delay(tiempo_espera + 0.15)
		
	# Aparece el botón Inglés
	tween.tween_property(EnglishBtn, "modulate:a", 1.0, duracion)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_delay(tiempo_espera + 0.3)

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
