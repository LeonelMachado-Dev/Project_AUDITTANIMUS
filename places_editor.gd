extends Control
@onready var input_nombre = $AnimusPanel/inputName
@onready var input_descripcion = $AnimusPanel/inputDescription
@onready var file_dialog_foto = $AnimusPanel/FileDialog_Image
# Componentes internos del visor de recorte
@onready var picture_editor = $AnimusPanel/PictureEditor
@onready var visor_container = $AnimusPanel/PictureEditor/VisorContainer
@onready var original_pic = $AnimusPanel/PictureEditor/VisorContainer/ClipControl/originalPicture

var editing_place: bool = false
var id_place_to_edit = null
var path_original_pic_db: String = "" # Para saber cuál borrar si se cambia la foto

# Variables mecánicas de arrastre de imagen
var drag: bool = false
var path_original_pic: String = ""
var loaded_pic_raw: Image = null
var confirmed_pic: bool = false # Nos dice si el usuario ya presionó el botón de fijar encuadre

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_default_pic_to_visor()
	
func load_default_pic_to_visor():
	var textura_por_defecto = load("res://Images/TEST SUBJECTS/no_foto.png")
	if textura_por_defecto:
		original_pic.texture = textura_por_defecto
		original_pic.size = Vector2(460, 300)
		original_pic.position = Vector2.ZERO
	original_pic.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmed_pic = false
	
func limpiar_formulario():
	input_nombre.clear()
	input_descripcion.text = ""
	
	# Reseteamos la ruta de la foto en el script para las validaciones
	path_original_pic = ""
	loaded_pic_raw = null
	
	# Cargamos el marcador de posición (Placeholder) en el TextureRect
	var textura_por_defecto = load("res://Images/TEST SUBJECTS/no_foto.png")
	if textura_por_defecto:
		original_pic.texture = textura_por_defecto
		original_pic.size = Vector2(460, 300)
		original_pic.position = Vector2.ZERO
		
	original_pic.mouse_filter = Control.MOUSE_FILTER_STOP


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
