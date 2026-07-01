extends Control

const RUTA_CONFIG = "user://config_animus.cfg"

func _ready() -> void:
	var config = ConfigFile.new()
	
	# Intentamos cargar el archivo de configuración
	if config.load(RUTA_CONFIG) == OK:
		# Si el archivo existe, buscamos si ya se guardó el idioma
		var idioma_guardado = config.get_value("Localization", "idioma", "")
		
		if idioma_guardado != "":
			# El usuario ya configuró su idioma antes, lo aplicamos
			TranslationServer.set_locale(idioma_guardado)
			print("[BOOT] Usuario existente. Cargando idioma: ", idioma_guardado)
			
			# SOLUCIÓN: Cambiamos de escena de forma diferida para evitar el error de nodos ocupados
			get_tree().change_scene_to_file.call_deferred("res://main_menu.tscn")
			return

	# Si el archivo no existe o no tiene idioma, es la primera vez
	print("[BOOT] Primera vez detectada o configuración limpia. Abriendo selector...")
	# SOLUCIÓN: También diferido aquí
	get_tree().change_scene_to_file.call_deferred("res://selector_idioma_inicio.tscn")
