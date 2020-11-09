extends KinematicBody2D

const SERIALIZE_FIELDS = [ "global_position", "velocity" ]

var velocity = Vector2.ZERO

var local_knockback = 0
var dead = false

var controller
onready var neighbors = $Neighbors
onready var visual = $Visual
onready var visual_anim = $Visual/AnimationPlayer

func load_data(data):
	for field in SERIALIZE_FIELDS:
		if field in data:
			set(field, data[field])
	if is_network_master():
		controller = $EnemyController
	else:
		$EnemyController.queue_free()
	if not is_network_master():
		visual.enable_smoothing()

func get_data():
	var data = {}
	data.id = int(name)
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	return data

remotesync func set_movement(vel, pos):
	position = pos
	velocity = vel
	local_knockback = 0

func hit(data):
	if controller.hit(data):
		rpc("show_hit")
	
remotesync func show_hit():
	if not visual_anim.is_playing():
		visual_anim.play("hurt")

func local_knockback(vel, dur):
	if dead: return
	velocity = vel
	local_knockback = dur
	
func _physics_process(delta):
	if velocity == Vector2.ZERO: return
	var before = position
	var col = move_and_collide(velocity * delta)
	visual.move(position - before)
	if col and is_network_master():
		controller.collide(col)
	if local_knockback > 0:
		local_knockback -= delta
		if local_knockback <= 0:
			local_knockback = 0
			velocity = Vector2.ZERO
	
func ai_tick():
	controller.ai_tick()

remotesync func die():
	dead = true
	$CollisionShape2D.disabled = true
	visual_anim.play("die")
	yield(get_tree().create_timer(2.1), "timeout")
	delete()

func delete():
	visual.queue_free()
	queue_free()
