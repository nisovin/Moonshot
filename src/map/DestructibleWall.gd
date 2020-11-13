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
var repairing = false

onready var target_position = $Target.global_position

func _ready():
	health = max_health
	points.append(global_position + Vector2(-24, -8))
	points.append(global_position + Vector2(-8, -8))
	points.append(global_position + Vector2(8, -8))
	points.append(global_position + Vector2(24, -8))
	if Game.is_server():
		$BehindDetector.queue_free()
		$RepairDetector.queue_free()

func apply_damage(dam):
	health -= dam
	if health < 100:
		modulate = Color(1, health / 100.0, health / 100.0)
	if health <= 0 and status > 0:
		status = 0
		rpc("update_status", status)
		emit_signal("status_changed", ids, status)
	return true
	
remotesync func update_status(new_status):
	status = new_status
	if status == 0:
		$CollisionCenter.set_deferred("disabled", true)
		$CollisionLeft.set_deferred("disabled", false)
		$CollisionRight.set_deferred("disabled", false)
		$Sprite.hide()

func interact(body):
	pass
	
func start_repair():
	pass
	
func stop_repair():
	pass

func _on_BehindDetector_body_entered(body):
	behind_count += 1
	$Sprite.modulate = Color(1, 1, 1, 0.6)

func _on_BehindDetector_body_exited(body):
	behind_count -= 1
	if behind_count == 0:
		$Sprite.modulate = Color.white

func _on_RepairDetector_body_entered(body):
	if status < 3 and body == Game.player:
		body.interact_with = self
		$Label.show()
	elif repairing and body.is_in_group("enemies"):
		stop_repair()

func _on_RepairDetector_body_exited(body):
	if body == Game.player:
		if body.interact_with == self:
			body.interact_with = null
		$Label.hide()
		if repairing:
			stop_repair()
