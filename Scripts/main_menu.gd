extends Control

@export var game_scene_path: String = "res://Scenes/world.tscn"

@onready var play_button: Button = $VBoxContainer/Button
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer


func _ready() -> void:
	video_player.visible = false

	play_button.pressed.connect(_on_play_pressed)
	video_player.finished.connect(_on_video_finished)


func _on_play_pressed() -> void:
	video_player.visible = true
	video_player.play()


func _on_video_finished() -> void:
	get_tree().change_scene_to_file(game_scene_path)


func _on_quit_pressed() -> void:
	get_tree().quit()
