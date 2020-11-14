extends KinematicBody2D

signal became_untargetable

enum PlayerState { LOADING, NORMAL, TELEPORTING, ABILITY, DEAD }

const SERIALIZE_FIELDS = [ "player_name", "uuid", "state", "health", "last_combat", "exhaustion", "move_dir", "current_speed", "facing", "facing_dir", "class_id", "global_position" ]

const NORMAL_SPEED = 100

var player_name = "Player"
var uuid = ""
var authed = false
var state: int = PlayerState.NORMAL
var move_dir := Vector2.ZERO
var current_speed := NORMAL_SPEED
var facing := "down"
var facing_dir := Vector2.ZERO
var targetable = true
var targeted_by_count = 0
var interact_with = null

var health = 100
var last_hit = 0
var last_hit_amount = 0
var last_combat = 0
var last_heal_tick = 0
var exhaustion = 0
var stage_deaths = 0
var dead = false

var class_id: int = Game.PlayerClass.WARRIOR
var player_class = null

onready var collision = $CollisionShape2D
onready var visual = $Visual
onready var sprite = $Visual/Sprite/AnimatedSprite
onready var visual_anim = $Visual/AnimationPlayer
onready var nameplate = $Visual/Nameplate
onready var healthbar = $Visual/Healthbar

func _ready():
	if player_class == null:
		player_class = $WarriorClass

func load_data(data):
	for field in SERIALIZE_FIELDS:
		if field in data:
			set(field, data[field])
	nameplate.text = player_name
			
	if class_id == Game.PlayerClass.WARRIOR:
		player_class = $WarriorClass
		$ArcherClass.queue_free()
	elif class_id == Game.PlayerClass.ARCHER:
		player_class = $ArcherClass
		$WarriorClass.queue_free()
	player_class.load_data(data.class_data if data.has("class_data") else null)
	health = player_class.MAX_HEALTH
		
	if name == str(get_tree().get_network_unique_id()):
		$Camera2D.current = true
		nameplate.visible = false
		healthbar.visible = false
		add_to_group("myself")
		Game.player = self
		Game.emit_signal("entered_level")
	else:
		$LocalController.queue_free()
		$Camera2D.queue_free()
		if Game.mp_mode == Game.MPMode.SERVER:
			set_physics_process(false)
		else:
			visual.enable_smoothing()

func get_data():
	var data = {}
	data.id = int(name)
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	data.class_data = player_class.get_data()
	return data
	
func apply_damage(dam, direct = false, energy_damage = 0):
	if not direct:
		dam *= 1 - player_class.get_armor()
		if last_hit > OS.get_ticks_msec() - 400:
			if dam < last_hit_amount:
				return false
			else:
				dam -= last_hit_amount
		else:
			last_hit = OS.get_ticks_msec()
			last_hit_amount = dam
	if dam <= 0:
		return false
	var new_health = health - dam
	if energy_damage > 0:
		rpc("damage", new_health, energy_damage)
	else:
		rpc("damage", new_health)
	return true

func got_kill(enemy, killing_blow):
	player_class.got_kill(enemy, killing_blow)

func _physics_process(delta):
	if state == PlayerState.NORMAL:
		var before = position
		var v = move_and_slide(move_dir * current_speed)
		visual.move(position - before)
		if v != Vector2.ZERO:
			sprite.play("walk_" + facing)
		else:
			sprite.play("idle_" + facing)

remotesync func damage(new_health, energy_damage = 0):
	if new_health >= health: return
	if is_network_master():
		if energy_damage > 0:
			player_class.energy = clamp(player_class.energy - energy_damage, 0, 100)
		pass # show FCT
	health = new_health
	last_combat = last_hit
	if energy_damage > 0:
		player_class.energy = max(player_class.energy - energy_damage, 0)
	healthbar.value = float(health) / player_class.MAX_HEALTH * 100
	if new_health > 0:
		if not visual_anim.is_playing():
			visual_anim.play("hit")
	else:
		pass # DEAD!
		
remotesync func heal(new_health, show):
	if show and new_health > health and is_network_master():
		pass # show FCT
	health = new_health
	healthbar.value = health / player_class.MAX_HEALTH * 100

func increase_exhaustion(by):
	exhaustion = clamp(exhaustion + by, 0, 100)
	if not is_network_master():
		rpc_id(get_network_master(), "update_exhaustion", exhaustion)
		
master func update_exhaustion(exh):
	exhaustion = exh

remotesync func set_movement(x, y, pos):
	move_dir = Vector2(x, y).normalized()
	if x != 0 or y != 0:
		set_facing(move_dir)
	position = pos

func teleport(pos):
	if state != PlayerState.NORMAL: return
	Game.lock_player_input = true
	state = PlayerState.TELEPORTING
	$Tween.interpolate_property(self, "position", position, pos, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN)
	$Tween.start()
	yield(get_tree().create_timer(0.1), "timeout")
	position = pos
	state = PlayerState.NORMAL
	Game.lock_player_input = false
	rpc("update_position", pos)

puppet func update_position(pos, tp = false):
	if tp or Game.is_server():
		position = pos
	else:
		var d = position.distance_squared_to(pos)
		if d > 25:
			position = pos
		if d > 256:
			visual.teleport()
			
remotesync func update_health(val):
	health = val

func interact():
	if interact_with != null:
		interact_with.interact(self)

func pause_movement():
	state = PlayerState.ABILITY
	sprite.play("idle_" + facing)
	
func resume_movement():
	state = PlayerState.NORMAL
	sprite.play("idle_" + facing)

func set_facing(v, set_anim = false):
	facing_dir = v
	if abs(v.x) > abs(v.y):
		if v.x > 0:
			facing = "right"
		else:
			facing = "left"
	else:
		if v.y > 0:
			facing = "down"
		else:
			facing = "up"
	if set_anim:
		sprite.play("idle_" + facing)
	
func get_action_direction(from_node = null):
	if Game.using_controller:
		var v = Vector2(Input.get_joy_axis(Game.controller_index, JOY_AXIS_0), Input.get_joy_axis(Game.controller_index, JOY_AXIS_1))
		if v.length() > 0.5:
			return v.normalized()
		elif facing_dir != Vector2.ZERO:
			return facing_dir
		else:
			return Vector2.UP
	elif from_node != null:
		return (get_global_mouse_position() - from_node.global_position).normalized()
	else:
		return get_local_mouse_position().normalized()

func untarget():
	emit_signal("became_untargetable", self)

func delete():
	visual.queue_free()
	queue_free()
