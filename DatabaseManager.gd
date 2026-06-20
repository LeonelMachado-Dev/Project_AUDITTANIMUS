extends Node
var db_folder_path: String = ""
var db_file_path: String = ""
var db: SQLite = null

func _ready():
	configurar_rutas_sistema()
	inicializar_sistema_archivos()
	conectar_base_datos()

func configurar_rutas_sistema():
	# Si estás ejecutando desde el editor de Godot, usamos la raíz del proyecto "res://"
	# Si ya exportaste el .exe, usamos la carpeta real donde está parado el ejecutable
	if OS.has_feature("editor"):
		db_folder_path = "res://data"
	else:
		db_folder_path = OS.get_executable_path().get_base_dir().path_join("data")
	
	db_file_path = db_folder_path.path_join("animus_data.db")
	print("[Animus OS] Ruta física calculada para la DB: ", db_file_path)

func inicializar_sistema_archivos():
	# 1. Crear carpeta 'data' local al proyecto/ejecutable si no existe
	# Pasamos la ruta global (física) para que funcione fuera de res:// en el .exe exportado
	var dir_global = DirAccess.open(OS.get_executable_path().get_base_dir())
	if OS.has_feature("editor"):
		dir_global = DirAccess.open("res://")
		
	if dir_global and not dir_global.dir_exists(db_folder_path):
		dir_global.make_dir_recursive(db_folder_path)
	
	# 2. Crear carpeta externa y privada en AppData para las fotos recortadas (user://)
	var dir_user = DirAccess.open("user://")
	if dir_user and not dir_user.dir_exists("user://sujetos"):
		dir_user.make_dir_recursive("user://sujetos")

func conectar_base_datos():
	db = SQLite.new()
	
	# Le pasamos la ruta absoluta real del disco para que SQLite trabaje fuera de la sandboxing de Godot
	if OS.has_feature("editor"):
		db.path = ProjectSettings.globalize_path(db_file_path)
	else:
		db.path = db_file_path
		
	if db.open_db():
		print("[Animus OS] Base de datos conectada localmente en la carpeta del programa.")
		crear_tablas_si_no_existen()
	else:
		push_error("[CRÍTICO] No se pudo abrir o crear el archivo sqlite en: " + db.path)

#Funcion para la consulta de sujetos/personas
func obtener_sujetos():
	# Hacemos una consulta simple a la tabla que creamos en DB Browser
	db.query("SELECT * FROM sujetos")
	return db.query_result

func crear_tablas_si_no_existen():
	db.query("PRAGMA foreign_keys = ON;")
	
	var query_sujetos = """
	CREATE TABLE IF NOT EXISTS sujetos (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		nombre TEXT NOT NULL,
		apellido TEXT,
		birth_year TEXT,
		imagen_path TEXT,
		descripcion TEXT NOT NULL,
		analisis_detallado TEXT,
		ubicacion_frecuente TEXT
	);
	"""
	db.query(query_sujetos)
	
	var query_recuerdos = """
	CREATE TABLE IF NOT EXISTS recuerdos (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		sujeto_id INTEGER,
		titulo TEXT,
		media_path TEXT,
		fecha_recuerdo TEXT,
		FOREIGN KEY (sujeto_id) REFERENCES sujetos(id) ON DELETE CASCADE
	);
	"""
	db.query(query_recuerdos)
	print("[Animus OS] Estructura de tablas validada.")

func insertar_sujeto(datos: Dictionary) -> int:
	var exito = db.insert_row("sujetos", datos)
	if exito:
		db.query("SELECT last_insert_rowid() as id;")
		return db.query_result[0]["id"]
	return -1

func eliminar_sujeto(id_sujeto: int):
	# Ejecuta la consulta de borrado directo usando el ID único del registro
	db.query("DELETE FROM sujetos WHERE id = " + str(id_sujeto))
