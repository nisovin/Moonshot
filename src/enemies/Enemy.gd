extends KinematicBody2D

const SERIALIZE_FIELDS = [ "global_position", "velocity" ]

var velocity = Vector2.ZERO
var move_duration = 0

var last_hit = 0
var dead = false

var controller
onready var neighbors = $Neighbors
onready var visual = $Visual
onready var visual_anim = $Visual/AnimationPlayer
onready var stun_particles = $Visual/StunParticles

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

remotesync func set_movement(vel, pos, dur = 0):
	position = pos
	velocity = vel
	move_duration = dur
	visual.paused = vel == Vector2.ZERO
	if not dead:
		stun_particles.emitting = vel == Vector2.ZERO
		stun_particles.visible = stun_particles.emitting

func hit(data):
	if controller.hit(data):
		rpc("show_hit")
	
remotesync func show_hit():
	if not visual_anim.is_playing():
		visual_anim.play("hurt")

func local_hit(vel = null, dur = 0):
	if dead: return
	last_hit = OS.get_ticks_msec()
	if vel != null:
		set_movement(vel, position, dur)
	
func _physics_process(delta):
	if velocity == Vector2.ZERO: return
	var before = position
	var col = move_and_collide(velocity * delta)
	visual.move(position - before)
	if col and is_network_master():
		controller.collide(col)
	if move_duration > 0:
		move_duration -= delta
		if move_duration <= 0:
			velocity = Vector2.ZERO
	
func ai_tick():
	controller.ai_tick()

remotesync func die():
	dead = true
	if not Game.is_server():
		print(last_hit, " ", OS.get_ticks_msec())
		if Game.player != null and last_hit > OS.get_ticks_msec() - 10000:
			Game.player.got_kill(self, last_hit > OS.get_ticks_msec() - 250)
		stun_particles.emitting = false
		stun_particles.visible = false
		visual_anim.play("die")
		$CollisionShape2D.set_deferred("disabled", true)
		yield(get_tree().create_timer(2.1), "timeout")
	delete()

func delete():
	visual.queue_free()
	queue_free()
