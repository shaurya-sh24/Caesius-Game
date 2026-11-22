extends Area2D

@export var needlefish: CharacterBody2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_projectile") or area.is_in_group("harpoon"):
		if area.get_parent().can_damage:
			needlefish.take_damage(1)
			area.get_parent().start_retract()
