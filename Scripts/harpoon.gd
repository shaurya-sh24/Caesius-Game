extends Node2D

enum HarpoonState {
	IDLE,
	SHOOTING,
	ATTACHED,
	RETRACTING,
	PULLING_PLAYER
}

@onready var harpoon_attach_audio: AudioStreamPlayer2D = $Tip/HarpoonAttachAudio
@onready var player_move_audio: AudioStreamPlayer2D = $PlayerMoveAudio


@export var player : CharacterBody2D
@export var harpoon_tip : Area2D
@export var rope : Line2D
@onready var tip_sprite: Sprite2D = $Tip/Sprite2D

@export var shoot_speed := 700.0
@export var pull_speed := 320.0
@export var retract_speed := 900.0
@export var max_distance := 500.0

@export var rope_block_mask: int = 2
@export var rope_cut_check_enabled := true

var can_attach := false

var can_damage = false

var state = HarpoonState.IDLE

var attached_body : Node = null

var direction : Vector2
var attached_point : Vector2
var current_distance := 0.0


func _ready() -> void:
	harpoon_tip.body_entered.connect(_on_harpoon_body_entered)
	reset_harpoon()

func _process(delta: float) -> void:
	if state == HarpoonState.IDLE:
		var mouse_pos = get_global_mouse_position()
		var dir = mouse_pos - global_position
		rotation = dir.angle()

func _physics_process(delta: float) -> void:
	handle_input()
	match state:
		HarpoonState.IDLE:
			idle_state()
		HarpoonState.SHOOTING:
			shooting_state(delta)
		HarpoonState.ATTACHED:
			attached_state()
		HarpoonState.RETRACTING:
			retracting_state(delta)
		HarpoonState.PULLING_PLAYER:
			pulling_player_state(delta)
	if rope_cut_check_enabled:
		check_rope_cut()
	
	
	update_rope()

func handle_input() -> void:
	if Input.is_action_just_pressed("left_click"):
		match state:
			HarpoonState.IDLE:
				fire_harpoon()
			HarpoonState.SHOOTING:
				start_retract()
			HarpoonState.ATTACHED:
				release_harpoon()

	if Input.is_action_just_pressed("right_click"):
		match state:
			HarpoonState.SHOOTING:
				start_retract()
			HarpoonState.ATTACHED:
				player_move_audio.play()
				start_pull_player()

func idle_state() -> void:
	can_damage = false
	tip_sprite.visible = false
	var spawn_offset := 20.0
	var mouse_pos := get_global_mouse_position()
	direction = (mouse_pos - player.global_position).normalized()
	harpoon_tip.global_position = player.global_position + direction * spawn_offset


func shooting_state(delta: float) -> void:
	can_damage = true
	tip_sprite.visible = true
	harpoon_tip.global_position += direction * shoot_speed * delta
	current_distance += shoot_speed * delta
	if current_distance >= max_distance:
		start_retract()


func attached_state() -> void:
	can_damage = false
	tip_sprite.visible = true
	harpoon_tip.global_position = attached_point


func retracting_state(delta: float) -> void:
	can_damage = false
	tip_sprite.visible = true
	var dir := (player.global_position - harpoon_tip.global_position).normalized()
	harpoon_tip.global_position += dir * retract_speed * delta
	if harpoon_tip.global_position.distance_to(player.global_position) < 12:
		reset_harpoon()


func pulling_player_state(delta: float) -> void:
	can_damage = false
	tip_sprite.visible = true
	harpoon_tip.global_position = attached_point
	var dir := (attached_point - player.global_position).normalized()
	player.velocity = player.velocity.lerp(dir * pull_speed, 0.08)
	if player.global_position.distance_to(attached_point) < 50:
		start_retract()

func fire_harpoon() -> void:
	state = HarpoonState.SHOOTING
	current_distance = 0.0
	can_attach = false
	var mouse_pos := get_global_mouse_position()
	direction = (mouse_pos - player.global_position).normalized()
	var spawn_offset := 20.0
	harpoon_tip.monitoring = false
	harpoon_tip.global_position = player.global_position + direction * spawn_offset
	harpoon_tip.rotation = direction.angle()
	await get_tree().physics_frame
	await get_tree().physics_frame
	harpoon_tip.monitoring = true
	can_attach = true


func release_harpoon() -> void:
	start_retract()


func start_retract() -> void:
	tip_sprite.visible = true
	state = HarpoonState.RETRACTING


func start_pull_player() -> void:
	state = HarpoonState.PULLING_PLAYER


func reset_harpoon() -> void:
	state = HarpoonState.IDLE
	attached_body = null
	current_distance = 0.0
	harpoon_tip.global_position = player.global_position
	rope.visible = false

func _on_harpoon_body_entered(body: Node) -> void:
	if state != HarpoonState.SHOOTING:
		return
	if not can_attach:
		return
	if body == player:
		return
		
	if body is TileMapLayer:
		var tilemap := body as TileMapLayer
		var cell := tilemap.local_to_map(tilemap.to_local(harpoon_tip.global_position))

		var tile_data := tilemap.get_cell_tile_data(cell)

		if tile_data != null:
			var hookable: bool = tile_data.get_custom_data("hookable")

			if not hookable:
				start_retract()
				return

	
	state = HarpoonState.ATTACHED
	attached_point = harpoon_tip.global_position
	attached_body = body
	harpoon_attach_audio.play()

func update_rope() -> void:
	
	if state == HarpoonState.IDLE:
		rope.visible = false
		return
	rope.visible = true
	rope.clear_points()
	rope.add_point(to_local(player.global_position))
	rope.add_point(to_local(harpoon_tip.global_position))

func check_rope_cut() -> void:
	if state not in [
		HarpoonState.ATTACHED,
		HarpoonState.PULLING_PLAYER
	]: return
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(player.global_position, harpoon_tip.global_position)
	query.collision_mask = rope_block_mask
	query.exclude = [
		player.get_rid(),
		harpoon_tip.get_rid()]
	var result := space_state.intersect_ray(query)
	
	if result.is_empty():
		return
	
	var hit_pos = result["position"]
	if hit_pos.distance_to(attached_point) < 8:
		return
	reset_harpoon()
