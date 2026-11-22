extends Area2D

@export var rise_speed := 40.0
@export var lifetime := 12.0
@export var oxygen_amount := 100

@export var player: CharacterBody2D

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position.y -= rise_speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body == player:
		body.add_oxygen(oxygen_amount)
		queue_free()
