extends CharacterBody2D

enum SharkState {
	PATROL,
	CIRCLE,
	WINDUP,
	DASH,
	RECOVER,
	DEAD
}

@onready var shark_dash_audio: AudioStreamPlayer2D = $SharkDashAudio

@export var player: CharacterBody2D

@export var patrol_speed := 60.0
@export var circle_speed := 120.0
@export var dash_speed := 360.0
@export var acceleration := 8.0

@export var detection_range := 365
@export var orbit_radius := 120.0
@export var orbit_speed := 2.4

@export var circle_time := 1.6
@export var windup_time := 0.35
@export var dash_time := 0.45
@export var recover_time := 0.7

@export var health := 2
@export var bubbles_scene: PackedScene

var state := SharkState.PATROL

var start_position: Vector2
var patrol_direction := 1

var orbit_angle := 0.0
var state_timer := 0.0
var dash_direction := Vector2.ZERO


func _ready() -> void:
	start_position = global_position
	state_timer = circle_time


func _physics_process(delta: float) -> void:
	if player == null:
		return

	match state:
		SharkState.PATROL:
			patrol_state(delta)

		SharkState.CIRCLE:
			circle_state(delta)

		SharkState.WINDUP:
			windup_state(delta)

		SharkState.DASH:
			dash_state(delta)

		SharkState.RECOVER:
			recover_state(delta)

		SharkState.DEAD:
			return

	move_and_slide()
	update_facing()


func patrol_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, patrol_direction * patrol_speed, acceleration * 20.0 * delta)
	velocity.y = move_toward(velocity.y, 0.0, acceleration * 20.0 * delta)

	if abs(global_position.x - start_position.x) > 160:
		patrol_direction *= -1

	if global_position.distance_to(player.global_position) < detection_range:
		start_circle()


func circle_state(delta: float) -> void:
	state_timer -= delta
	orbit_angle += orbit_speed * delta

	var orbit_target := player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius

	var dir := (orbit_target - global_position).normalized()
	velocity = velocity.lerp(dir * circle_speed, acceleration * delta)

	if state_timer <= 0.0:
		start_windup()


func windup_state(delta: float) -> void:
	state_timer -= delta

	var away_dir := (global_position - player.global_position).normalized()
	velocity = velocity.lerp(away_dir * 70.0, acceleration * delta)

	if state_timer <= 0.0:
		start_dash()


func dash_state(delta: float) -> void:
	
	if !shark_dash_audio.playing:
		shark_dash_audio.play()
	
	state_timer -= delta

	velocity = dash_direction * dash_speed

	if state_timer <= 0.0:
		start_recover()


func recover_state(delta: float) -> void:
	state_timer -= delta

	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)

	if state_timer <= 0.0:
		start_circle()


func start_circle() -> void:
	state = SharkState.CIRCLE
	state_timer = circle_time
	orbit_angle = randf() * TAU


func start_windup() -> void:
	state = SharkState.WINDUP
	state_timer = windup_time


func start_dash() -> void:
	state = SharkState.DASH
	state_timer = dash_time
	dash_direction = (player.global_position - global_position).normalized()


func start_recover() -> void:
	state = SharkState.RECOVER
	state_timer = recover_time


func take_damage(amount: int = 1) -> void:
	if state == SharkState.DEAD:
		return
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	state = SharkState.DEAD
	velocity = Vector2.ZERO

	spawn_bubbles()

	queue_free()


func spawn_bubbles() -> void:
	if bubbles_scene == null:
		return
	for i in range(2):
		var bubble = bubbles_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", bubble)
		bubble.global_position = global_position + Vector2(randf_range(-16, 16),randf_range(-16, 16))
		bubble.player = player


func update_facing() -> void:
	if velocity.x > 5:
		$AnimatedSprite2D.flip_h = true
	elif velocity.x < -5:
		$AnimatedSprite2D.flip_h = false
