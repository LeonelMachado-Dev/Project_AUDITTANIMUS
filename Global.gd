extends Node

var click_effect : AudioStreamPlayer
var sujeto_seleccionado_id: int = 0
var indice_carrusel_guardado : int = 0
var disclaimer_ya_mostrado: bool = false
var sfx_permitido: bool = true
var music_player : AudioStreamPlayer

func _ready():
	click_effect = AudioStreamPlayer.new()
	add_child(click_effect)
	click_effect.stream = load("res://music/Click-sound-AC2-Soundtrack.mp3")
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music" 
	add_child(music_player)

func reproducir_tick():
	if sfx_permitido and click_effect and click_effect.stream:
		click_effect.play()

func set_track(nuevo_stream: AudioStream):
	music_player.stop() 
	if nuevo_stream is AudioStreamMP3:
		nuevo_stream.loop = true
	elif nuevo_stream is AudioStreamOggVorbis:
		nuevo_stream.loop = true
	
	music_player.stream = nuevo_stream
	music_player.play()
	print("Audio actualizado y configurado en bucle correctamente")
	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
