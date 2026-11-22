extends CharacterBody2D

@export var land_tilemap: TileMapLayer
@export var water_tilemap: TileMapLayer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var low_oxygen_audio = $AudioStreamPlayer2D
const BUBBLES = preload("uid://cfjyle2rxd8s3")

@export var health_ui: TextureRect
@export var vignette_shader : ShaderMaterial

var is_dead: bool = false

var land_speed := 130.0
var land_accel := 900.0
var land_friction := 1200.0
var land_jump_velocity := -300.0
var land_gravity := 900.0

@export var zero_level_y: = 48
const c_swim_speed := 130.0
const c_swim_accel := 500.0
const c_water_gravity := 190.0
const c_swim_impulse := -120.0
const c_max_water_fall_speed := 145.0
const c_vignette_ir = 0.4
const c_vignette_or = 0.9

const d_swim_speed := 10.0
const d_swim_accel := 500.0
const d_water_gravity := 240.0
const d_swim_impulse := -60.0
const d_max_water_fall_speed := 145.0
const d_vignette_ir = 0.2
const d_vignette_or = 0.7

var swim_speed := c_swim_speed
var swim_accel := c_swim_accel
var water_gravity := c_water_gravity
var swim_impulse := c_swim_impulse
var max_water_fall_speed := c_max_water_fall_speed

var max_health: float = 100.0
var max_oxygen: float = 100.0

var can_move:bool = true

var oxygen_drain_rate: float = 4.0
var low_oxygen_threshold: float = 20.0
var low_oxygen_health_damage: float = 8.0
var full_oxygen_heal_rate: float = 5.0

var health: float = 100.0
var oxygen: float = 100.0

var in_water := false

@export var shallow_color := Color(0.274, 0.632, 0.776)
@export var deep_color := Color(0.15, 0.2, 0.35, 1.0)

@export var start_depth := 40.0
@export var max_depth := 2145.0

func _ready() -> void:
	health = max_health
	oxygen = max_oxygen

func _physics_process(delta: float) -> void:
	health_ui.modulate.s = (max_health - health)/100
	
	swim_speed = c_swim_speed + ((global_position.y - 2*zero_level_y)/2145)*(d_swim_speed - c_swim_speed)
	swim_impulse = c_swim_impulse + ((global_position.y - 2*zero_level_y)/2145)*(d_swim_impulse - c_swim_impulse)
	water_gravity = c_water_gravity + ((global_position.y - 2*zero_level_y)/2145)*(d_water_gravity - c_water_gravity)
	swim_accel = c_swim_accel + ((global_position.y - 2*zero_level_y)/2145)*(d_swim_accel - c_swim_accel)
	
	vignette_shader.set_shader_parameter("inner_radius", c_vignette_ir + ((global_position.y - 2*zero_level_y)/2145)*(d_vignette_ir - c_vignette_ir))
	vignette_shader.set_shader_parameter("outer_radius", c_vignette_or + ((global_position.y - 2*zero_level_y)/2145)*(d_vignette_or - c_vignette_or))
	
	in_water = is_inside_water()

	if in_water:
		handle_water_movement(delta)
		collision_shape_2d.rotation_degrees = 90
		collision_shape_2d.position = Vector2(-4, -3)
	else:
		handle_land_movement(delta)
		collision_shape_2d.rotation_degrees = 0
		collision_shape_2d.position = Vector2(0, 3)
	
	handle_animation()
	handle_survival(delta)
	update_low_oxygen_audio()
	move_and_slide()

func is_inside_water() -> bool:
	if water_tilemap == null:
		return false
	
	var cell := water_tilemap.local_to_map(water_tilemap.to_local(global_position))
	var tile_data := water_tilemap.get_cell_tile_data(cell)
	return tile_data != null

func handle_land_movement(delta: float) -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * land_speed, land_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, land_friction * delta)

	if not is_on_floor():
		velocity.y += land_gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = land_jump_velocity

func handle_water_movement(delta: float) -> void:
	if can_move:
		var input_dir := Input.get_axis("ui_left", "ui_right")
		
		if input_dir != 0:
			velocity.x = move_toward(velocity.x, input_dir * swim_speed, swim_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, swim_accel * delta)
		
		
		velocity.y += water_gravity * delta

		if velocity.y > max_water_fall_speed:
			velocity.y = max_water_fall_speed
		
		if velocity.y < 0:
			if !sprite.flip_h:
				create_tween().tween_property(self,"rotation_degrees",15.0,0.1)
			else:
				create_tween().tween_property(self,"rotation_degrees",-15.0,0.1)
		elif velocity.y > 0:
			if !sprite.flip_h:
				create_tween().tween_property(self,"rotation_degrees",-30.0,0.1)
			else:
				create_tween().tween_property(self,"rotation_degrees",30.0,0.1)
		else:
			create_tween().tween_property(self,"rotation_degrees",0,0.5)
		
		if Input.is_action_pressed("ui_up"):
			velocity.y = swim_impulse

func handle_animation() -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if input_dir > 0:
		sprite.flip_h = true
	elif input_dir < 0:
		sprite.flip_h = false
	
	if in_water:
		sprite.play("swim")
	elif velocity.x != 0:
		sprite.play("walk")
	else:
		sprite.play("idle")

func handle_survival(delta: float) -> void:
	oxygen -= oxygen_drain_rate * delta
	oxygen = clampf(oxygen, 0.0, max_oxygen)

	if oxygen <= low_oxygen_threshold:
		health -= low_oxygen_health_damage * delta

	health = clampf(health, 0.0, max_health)

	if health <= 0:
		die()

func take_damage(amount: float) -> void:
	health -= amount
	health = clampf(health, 0.0, max_health)

	if health <= 0:
		die()

func add_oxygen(amount: float) -> void:
	oxygen += amount
	health = max_health
	oxygen = clampf(oxygen, 0.0, max_oxygen)

func die() -> void:
	if is_dead:
		return

	is_dead = true
	call_deferred("_death_sequence")

func _death_sequence()->void:
	can_move = false
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Camera2D"):
		$Camera2D.set_physics_process(false)
	var parent := get_parent()
	if parent != null:
		var bubbles = BUBBLES.instantiate()
		parent.add_child(bubbles)
		bubbles.global_position = global_position
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(2.0).timeout
	if is_inside_tree():
		get_tree().call_deferred("reload_current_scene")

func update_low_oxygen_audio() -> void:

	var oxygen_ratio: float = oxygen / max_oxygen

	if oxygen_ratio > 0.5:
		low_oxygen_audio.volume_db = -30
		return

	var t: float = inverse_lerp(0.5, 0.0, oxygen_ratio)

	low_oxygen_audio.volume_db = lerpf(-15.0, 0.0, t)
	low_oxygen_audio.pitch_scale += randf_range(-0.03, 0.03)
	low_oxygen_audio.pitch_scale = lerpf(1.0, 1.4, t)
