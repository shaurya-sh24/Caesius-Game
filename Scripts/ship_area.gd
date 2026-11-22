extends Area2D

@onready var player: CharacterBody2D = $"../Player"
@onready var black_screen: ColorRect = $"../CanvasLayer/ColorRect"

@export var swim_time: float = 5.0
@export var fade_time: float = 3.0

var triggered := false


func _ready() -> void:
	black_screen.modulate.a = 0.0


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if body != player:
		return

	triggered = true
	start_end_cutscene()

func start_end_cutscene() -> void:
	player.can_move = false
	player.velocity = Vector2.ZERO

	var swim_tween := create_tween()
	swim_tween.tween_property(player,"global_position",global_position,swim_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	swim_tween.finished.connect(_fade_to_black)


func _fade_to_black() -> void:
	var fade_tween := create_tween()
	fade_tween.tween_property(black_screen,"modulate:a",1.0,fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	fade_tween.finished.connect(_end_game)


func _end_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
