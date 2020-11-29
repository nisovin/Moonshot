extends KinematicBody2D

const SERIALIZE_FIELDS = [ "type_id", "global_position", "velocity" ]

var velocity = Vector2.ZERO
var dir = "down"
var move_duration = 0
var last_physics_tick = 0

var type_id = 0
var health: float = 50
var max_health: float = 50
var immune_to_knockback = false
var immune_to_stun = false
var minimap_color = Color.red
var minimap_big = false
var death_sound = null
var last_hit = 0
var dead = false

var controller
onready var neighbors = $Neighbors
onready var visual = $Visual
onready var visual_anim = $Visual/AnimationPlayer
onready var sprite = $Visual/AnimatedSprite
onready var stun_particles = $Visual/StunParticles
onready var healthbar = $Visual/Node2D/TextureProgress
onready var collision = $CollisionShape2D
onready var hitbox_collision = $Hitbox/CollisionShape2D
#
#func _process(delta):
#	update()
#
#func _draw():
#	draw_line(Vector2.ZERO, controller.target_direction * 32, Color.red, 2)
#	draw_circle(controller.target_position - position, 10, Color.yellow)
#	draw_line(Vector2.ZERO, velocity, Color.blue, 2)

func load_data(data):
	for field in SERIALIZE_FIELDS:
		if field in data:
			set(field, data[field])
	controller = $EnemyController
	controller.init(type_id)
	$Visual/Node2D.position.y = -controller.type.height - 5
	max_health = controller.type.max_health
	health = max_health
	immune_to_knockback = controller.type.immune_to_knockback
	immune_to_stun = controller.type.immune_to_stun
	minimap_color = controller.type.minimap_color
	minimap_big = controller.type.minimap_big
	death_sound = controller.type.death_sound
	if not is_network_master():
		controller.queue_free()
		visual.enable_smoothing()
	if not Game.is_server():
		healthbar.rect_size.x = min(ceil(health / 5), 32)
		if health >= 150:
			healthbar.rect_size.y = 6
		healthbar.rect_position.x = -healthbar.rect_size.x / 2
		healthbar.visible = false
	#if Game.is_server():
	#	set_physics_process(false)

func get_data():
	var data = {}
	data.id = int(name)
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	return data

func calculate_damage(dam, target):
	if target.is_in_group("players"):
		dam *= 1 - target.get_armor()
	if Game.level.time_of_day == "midday":
		dam *= 1.5
	return dam

remotesync func set_movement(vel, pos, dur = 0):
	position = pos
	velocity = vel
	move_duration = dur
	visual.paused = vel == Vector2.ZERO
	#if not dead:
	#	stun_particles.emitting = vel == Vector2.ZERO
	#	stun_particles.visible = stun_particles.emitting

func hit(data):
	last_hit = OS.get_ticks_msec()
	if controller.hit(data):
		rpc("show_hit", health)
	
remotesync func show_hit(h):
	if dead or Game.is_server(): return
	var dam = health - h
	health = h
	if health < max_health:
		healthbar.visible = true
		healthbar.value = health / max_health
	if not visual_anim.is_playing():
		visual_anim.play("hurt")
	if Game.is_client() and last_hit > OS.get_ticks_msec() - 500 and Settings.gameplay_fct_enemies:
		N.fct(self, dam, Color.magenta)
	if Game.is_solo():
		Audio.play("enemy_hit", Audio.ENEMIES, 0.4)

func local_hit(player, vel = null, dur = 0):
	if dead: return
	if player == Game.player:
		last_hit = OS.get_ticks_msec()
	if vel != null:
		if (vel == Vector2.ZERO and not immune_to_stun) or (vel != Vector2.ZERO and not immune_to_knockback):
			set_movement(vel, position, dur)
	Audio.play("enemy_hit", Audio.ENEMIES, 0.4)
	
func physics_tick(delta):
	last_physics_tick = Engine.get_physics_frames()
	if velocity == Vector2.ZERO: return
	var before = position
	if collision.disabled:
		position += velocity * delta
	else:
		var col = move_and_collide(velocity * delta)
		if col and is_network_master():
			controller.collide(col)
	visual.move(position - before)
	if move_duration > 0:
		move_duration -= delta
		if move_duration <= 0:
			velocity = Vector2.ZERO
	
func _physics_process(delta):
	physics_tick(delta)
	if velocity != Vector2.ZERO:
		if abs(velocity.x) >= abs(velocity.y):
			if velocity.x > 0:
				dir = "right"
			else:
				dir = "left"
		else:
			if velocity.y > 0:
				dir = "down"
			else:
				dir = "up"
		if sprite.frames.has_animation("walk_" + dir):
			sprite.play("walk_" + dir)
		else:
			sprite.play("default")
	else:
		if sprite.frames.has_animation("idle_" + dir):
			sprite.play("idle_" + dir)
		elif sprite.frames.has_animation("walk_" + dir):
			sprite.play("walk_" + dir)
		else:
			sprite.play("default")
	
remotesync func die():
	if dead: return
	dead = true
	if not Game.is_server():
		if Game.player != null and last_hit > 0 and last_hit > OS.get_ticks_msec() - 10000:
			Game.player.got_kill(self, last_hit > OS.get_ticks_msec() - 250)
		healthbar.visible = false
		stun_particles.visible = false
		visual_anim.play("die")
		if death_sound != null:
			Audio.play_at_position(position, death_sound, Audio.ENEMIES)
		# disable player collision
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 1)
		$Hitbox.queue_free()
		yield(get_tree().create_timer(2.1), "timeout")
	delete()

func delete():
	visual.queue_free()
	queue_free()
