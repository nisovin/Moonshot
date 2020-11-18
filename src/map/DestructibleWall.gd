extends Node2D

signal status_changed
signal became_untargetable

const REPAIR_SPEED = 50
const FULL_STATUS = 4
const TILE_IDS = [3,4,5,6,7]

export(int) var max_health = 100
export(int) var health = 100
export(String) var section = "forward"
var status = FULL_STATUS
var points = []
var ids = []

var behind_count = 0
var targeted_by_count = 0
var repairing = false
var repair_amount = 0

onready var target_position = $Target.global_position
onready var label = $Z/Label
onready var progress = $Z/RepairProgress
var tile_map: TileMap
var tile_v

func _ready():
	points.append(global_position + Vector2(-24, -8))
	points.append(global_position + Vector2(-8, -8))
	points.append(global_position + Vector2(8, -8))
	points.append(global_position + Vector2(24, -8))
	label.hide()
	progress.hide()
	if Game.is_server():
		$BehindDetector.queue_free()
		$RepairDetector.queue_free()
		set_physics_process(false)
	tile_map = get_parent().get_parent()
	tile_v = tile_map.world_to_map(position + Vector2(-24, 8))
	#tile_map.set_cellv(tile_v, TILE_IDS[FULL_STATUS])
		
func _physics_process(delta):
	if repairing:
		repair_amount += REPAIR_SPEED * delta
		progress.value = repair_amount
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
	elif health <= max_health * .3:
		new_status = 1
	elif health <= max_health * .6:
		new_status = 2
	elif health <= max_health * .9:
		new_status = 3
	else:
		new_status = 4
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
		$Particles2D.emitting = true
	status = new_status
	#tile_map.set_cellv(tile_v, TILE_IDS[status])
	if status == 4:
		$Sprite.texture = preload("res://map/wall4.png")
	elif status == 3:
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
	progress.value = 0
	progress.show()
	
func stop_repair():
	repairing = false
	progress.hide()

func finish_repair():
	repairing = false
	progress.hide()
	rpc("repair", max_health * 0.24)

func update_modulate():
	if behind_count > 0 and status >= 3:
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
		label.show()
	elif repairing and body.is_in_group("enemies"):
		stop_repair()

func _on_RepairDetector_body_exited(body):
	if body == Game.player:
		if body.interact_with == self:
			body.interact_with = null
		label.hide()
		if repairing:
			stop_repair()
