extends Control

const RUTA_CONFIG = "user://config_animus.cfg"

func _ready() -> void:
	var config = ConfigFile.new()
	
	if config.load(RUTA_CONFIG) == OK:
		# 1. Aplicar Idioma al sistema
		var idioma_guardado = config.get_value("Localization", "idioma", "")
		if idioma_guardado != "":
			TranslationServer.set_locale(idioma_guardado)
			print("[BOOT] Idioma del sistema inicializado: ", idioma_guardado)
		
		# 2. Aplicar Volumen real al Servidor de Audio
		var vol_guardado = config.get_value("Audio", "volumen_musica", 80.0)
		var db = linear_to_db(vol_guardado / 100.0)
		var bus_idx = AudioServer.get_bus_index("Music")
		if bus_idx != -1:
			AudioServer.set_bus_volume_db(bus_idx, db)
			print("[BOOT] Volumen del bus 'Music' configurado a: ", vol_guardado, "稳定 (", db, " dB)")
			
		# 3. Aplicar estado de los Efectos de Sonido en el Autoload Global
		Global.sfx_permitido = config.get_value("Audio", "sfx_activado", true)
		print("[BOOT] SFX globales establecidos en: ", Global.sfx_permitido)
		
		# Si ya hay un idioma definido, saltamos directamente al menú principal
		if idioma_guardado != "":
			get_tree().change_scene_to_file.call_deferred("res://main_menu.tscn")
			return

	# Si el archivo no existe o no tiene idioma guardado, es la primera vez absoluta del juego
	print("[BOOT] Archivo de configuración ausente o limpio. Abriendo selector de idiomas de inicio...")
	get_tree().change_scene_to_file.call_deferred("res://selector_idioma_inicio.tscn")
