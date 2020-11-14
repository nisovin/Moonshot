extends Node2D

signal status_changed
signal became_untargetable

const REPAIR_SPEED = 50

export(int) var max_health = 100
export(int) var health = 100
var status = 3
var points = []
var ids = []

var behind_count = 0
var targeted_by_count = 0
var repairing = false
var repair_amount = 0

onready var target_position = $Target.global_position

func _ready():
	points.append(global_position + Vector2(-24, -8))
	points.append(global_position + Vector2(-8, -8))
	points.append(global_position + Vector2(8, -8))
	points.append(global_position + Vector2(24, -8))
	$Label.hide()
	$RepairProgress.hide()
	if Game.is_server():
		$BehindDetector.queue_free()
		$RepairDetector.queue_free()
		set_physics_process(false)
		
func _physics_process(delta):
	if repairing:
		repair_amount += REPAIR_SPEED * delta
		$RepairProgress.value = repair_amount
		if repair_amount >= 100:
			finish_repair()

func load_data(data):
	status = data.status
	
func get_data():
	return {"status": status}

func apply_damage(dam):
	if health <= 0 and dam > 0: return false
	health -= dam
	if health < 0: health = 0
	elif health > max_health: health = max_health
	var new_status = status
	if health <= 0:
		new_status = 0
	elif health <= max_health * .25:
		new_status = 1
	elif health <= max_health * .50:
		new_status = 2
	else:
		new_status = 3
	if status != new_status:
		rpc("update_status", new_status)
		emit_signal("status_changed", ids, new_status)
	return true

master func repair(amount):
	apply_damage(-amount)

remotesync func update_status(new_status):
	if new_status == 0 and status != 0:
		$CollisionCenter.set_deferred("disabled", true)
		$CollisionLeft.set_deferred("disabled", false)
		$CollisionRight.set_deferred("disabled", false)
	elif new_status > 0 and status == 0:
		$CollisionCenter.set_deferred("disabled", false)
		$CollisionLeft.set_deferred("disabled", true)
		$CollisionRight.set_deferred("disabled", true)
	if new_status < status:
		stop_repair()
	status = new_status
	if status == 3:
		$Sprite.texture = preload("res://map/wall3.png")
	elif status == 2:
		$Sprite.texture = preload("res://map/wall2.png")
	elif status == 1:
		$Sprite.texture = preload("res://map/wall1.png")
	else:
		$Sprite.texture = preload("res://map/wall0.png")
	update_modulate()

func interact(body):
	if status < 3:
		start_repair()
	
func start_repair():
	repairing = true
	repair_amount = 0
	$RepairProgress.value = 0
	$RepairProgress.show()
	
func stop_repair():
	repairing = false
	$RepairProgress.hide()

func finish_repair():
	repairing = false
	$RepairProgress.hide()
	rpc("repair", max_health * 0.24)

func update_modulate():
	if behind_count > 0 and status >= 2:
		$Sprite.modulate = Color(1, 1, 1, 0.6)
	else:
		$Sprite.modulate = Color.white
		

func _on_BehindDetector_body_entered(body):
	behind_count += 1
	update_modulate()

func _on_BehindDetector_body_exited(body):
	behind_count -= 1
	update_modulate()

func _on_RepairDetector_body_entered(body):
	if status < 3 and body == Game.player:
		body.interact_with = self
		$Label.show()
	elif repairing and body.is_in_group("enemies"):
		pass #stop_repair()

func _on_RepairDetector_body_exited(body):
	if body == Game.player:
		if body.interact_with == self:
			body.interact_with = null
		$Label.hide()
		if repairing:
			stop_repair()
