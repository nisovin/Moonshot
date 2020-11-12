extends Node2D

signal status_changed
signal became_untargetable

export var max_health = 100
var health = max_health
var status = 3
var points = []
var ids = []

var behind_count = 0
var targeted_by_count = 0

onready var target_position = $Target.global_position

func _ready():
	health = max_health
	points.append(global_position + Vector2(-24, -8))
	points.append(global_position + Vector2(-8, -8))
	points.append(global_position + Vector2(8, -8))
	points.append(global_position + Vector2(24, -8))

func apply_damage(dam):
	health -= dam
	if health < 100:
		modulate = Color(1, health / 100.0, health / 100.0)
	return true

func _on_BehindDetector_body_entered(body):
	behind_count += 1
	$Sprite.modulate = Color(1, 1, 1, 0.6)

func _on_BehindDetector_body_exited(body):
	behind_count -= 1
	if behind_count == 0:
		$Sprite.modulate = Color.white
