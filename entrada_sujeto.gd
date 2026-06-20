extends Button

@onready var foto_sujeto = $TextureRect
@onready var label_nombre = $First_and_LastName_Label

# Esta variable guardará la información de la base de datos
var datos_sujeto = {} 

# Esta función se activa desde el Main para ponerle el nombre al botón
func configurar(data):
	# ¡IMPORTANTE! Guardamos los datos para usarlos en el clic después
	datos_sujeto = data 
	
	# 1. Asignamos el nombre y apellido en mayúsculas al Label de abajo
	var nombre = data.get("nombre", "")
	var apellido = data.get("apellido", "")
	label_nombre.text = (nombre + " " + apellido).to_upper()
	
	# 2. Cargar la foto desde la ruta externa (user://...)
	var ruta_foto = data.get("imagen_path", "")
	
	if ruta_foto != "" and FileAccess.file_exists(ruta_foto):
		# Cargamos la imagen directamente usando el método estático de Godot
		var img = Image.load_from_file(ruta_foto)
		
		# Verificamos si el objeto imagen es válido y tiene un tamaño real
		if img and img.get_width() > 0:
			# Si se cargó con éxito, la convertimos en textura de Godot
			var textura = ImageTexture.create_from_image(img)
			foto_sujeto.texture = textura
		else:
			print("Error al procesar la imagen del sujeto en la ruta: ", ruta_foto)
			cargar_imagen_defecto()
	else:
		# Si no hay foto o el archivo no existe, ponemos una silueta para que no quede vacío
		print("No se encontró el archivo de imagen en: ", ruta_foto)
		cargar_imagen_defecto()
		
func cargar_imagen_defecto():
	# Puedes crear una imagen gris o una silueta en tu proyecto para emergencias
	if ResourceLoader.exists("res://Images/TEST SUBJECTS/no_foto.png"):
		foto_sujeto.texture = load("res://Images/TEST SUBJECTS/no_foto.png")
	else:
		foto_sujeto.texture = null # O dejarlo vacío (se verá el fondo blanco del panel)

#func _on_pressed():
	#var escena_principal = get_tree().current_scene
	#
	## Si está en Modo Purga O en Modo Edición, la tarjeta se frena y deja trabajar a main.gd
	#if escena_principal:
		#var estado = escena_principal.get("estado_actual")
		## Comprobamos si el estado actual es diferente de 0 (0 suele ser EstadoInterfaz.NORMAL)
		#if estado != null and estado != 0:
			#return
		#
	#cambiar_a_detalles()

# Separamos la lógica de cambio de escena para que main.gd pueda llamarla de forma segura
func cambiar_a_detalles():
	var nombre_completo = (datos_sujeto.get("nombre", "") + " " + datos_sujeto.get("apellido", "")).to_upper()
	print("Has seleccionado a: ", nombre_completo)
	
	# Guardamos el ID en el Autoload Global
	Global.sujeto_seleccionado_id = datos_sujeto.get("id", 0)
	print("Cargando datos del sujeto ID: ", Global.sujeto_seleccionado_id)
	
	# Cambiamos de escena usando la vía más segura para evitar el error de data.tree
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		main_loop.change_scene_to_file("res://DetallesSujeto.tscn")
