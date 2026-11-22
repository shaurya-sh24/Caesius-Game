extends Node

@onready var music: AudioStreamPlayer = $AudioStreamPlayer

var bg_music = preload("res://Assets/Sound/music.mp3")

func play_music(stream: AudioStream = bg_music) -> void:
	if music.stream == stream and music.playing:
		return
	music.stream = stream
	music.play()

func stop_music() -> void:
	music.stop()
