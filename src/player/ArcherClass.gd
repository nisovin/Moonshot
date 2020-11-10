extends Node2D

enum ArcherState { NORMAL, AIMING_ARROW, RELOADING, AIMING_VOLLEY, AIMING_ULTIMATE, EVADING }

const CrescentArrow = preload("res://player/Arrow.tscn")

const SERIALIZE_FIELDS = [ "state", "ultimate_duration" ]

const SHOOT_AIM_TIME = 0.4
const SHOOT_AIM_MIN = 0.3
const SHOOT_ARROW_COUNT = 5
const SHOOT_ARROW_SPREAD = deg2rad(35)
const SHOOT_ARROW_SPEED = 200
const SHOOT_CENTER_KNOCKBACK_STR = 300
const SHOOT_SIDE_KNOCKBACK_STR = 150
const SHOOT_KNOCKBACK_DUR = 0.1
const SHOOT_CENTER_DAMAGE = 40
const SHOOT_SIDE_DAMAGE = 10
const SHOOT_COOLDOWN = 0.6

const VOLLEY_COOLDOWN = 10

const SHADOW_COOLDOWN = 10

const ULTIMATE_COOLDOWN = 90

var state = ArcherState.NORMAL

var shoot_pressed = false
var shoot_aim_time = 0
var shoot_cd = 0

var volley_position = Vector2.ZERO
var volley_cd = 0

onready var arrow_spawn = $ArrowSpawnPoint

func get_data():
	var data = {}
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	return data

func load_data(data):
	if Game.mp_mode == Game.MPMode.SERVER:
		set_physics_process(false)
	if data != null:
		for field in SERIALIZE_FIELDS:
			if field in data:
				set(field, data[field])

func is_moving():
	return false

remotesync func start_aim(pos):
	owner.position = pos
	owner.pause_movement()
	
remotesync func stop_aim():
	owner.resume_movement()

func attack1_press():
	shoot_pressed = true
	if state != ArcherState.NORMAL: return
	rpc("shoot_aim", owner.position)
	
func attack1_release():
	shoot_pressed = false
	if state == ArcherState.AIMING_ARROW and shoot_aim_time >= SHOOT_AIM_MIN:
		rpc("shoot_fire", owner.position, owner.get_action_direction(arrow_spawn))
	else:
		rpc("shoot_end")

remotesync func shoot_aim(pos):
	state = ArcherState.AIMING_ARROW
	shoot_aim_time = 0
	start_aim(pos)

remotesync func shoot_fire(pos, dir):
	owner.position = pos
	if shoot_aim_time >= SHOOT_AIM_MIN:
		shoot_cd = SHOOT_COOLDOWN
		var vel = dir * SHOOT_ARROW_SPEED
		vel = vel.rotated(-SHOOT_ARROW_SPREAD / 2)
		for i in SHOOT_ARROW_COUNT:
			var arrow = CrescentArrow.instance()
			Game.level.projectiles_node.add_child(arrow)
			arrow.init(arrow_spawn.global_position, vel, i != SHOOT_ARROW_COUNT / 2)
			vel = vel.rotated(SHOOT_ARROW_SPREAD / (SHOOT_ARROW_COUNT - 1))
			arrow.connect("hit", self, "shoot_hit")
		if shoot_pressed:
			state = ArcherState.RELOADING
			return
	state = ArcherState.NORMAL
	shoot_end()

func shoot_hit(enemy, vel, mini):
	var dam = SHOOT_SIDE_DAMAGE if mini else SHOOT_CENTER_DAMAGE
	var knockback = SHOOT_SIDE_KNOCKBACK_STR if mini else SHOOT_CENTER_KNOCKBACK_STR
	enemy.hit({"damage": dam, "knockback": vel.normalized() * knockback, "knockback_dur": SHOOT_KNOCKBACK_DUR})

remotesync func shoot_end():
	state = ArcherState.NORMAL
	stop_aim()
	
func attack2_press():
	if state != ArcherState.NORMAL: return
	if volley_cd > 0: return
	if Game.using_controller:
		state = ArcherState.AIMING_VOLLEY
		volley_position = owner.position + owner.get_action_direction() * 70
		rpc("start_aim", owner.position)
	else:
		rpc("volley", get_global_mouse_position())
	
func attack2_release():
	if state == ArcherState.AIMING_VOLLEY:
		rpc("volley", volley_position)
	
remotesync func volley(pos):
	owner.resume_movement()
	
func movement_press():
	pass
	
func movement_release():
	pass
	
func ultimate_press():
	pass
	
func ultimate_release():
	pass

func _physics_process(delta):
	if state == ArcherState.AIMING_ARROW and is_network_master():
		shoot_aim_time += delta
		print(shoot_aim_time)
		if shoot_aim_time >= SHOOT_AIM_TIME:
			rpc("shoot_fire", owner.position, owner.get_action_direction(arrow_spawn))
			shoot_aim_time = 0
	if state == ArcherState.RELOADING and shoot_pressed:
		shoot_cd -= delta
		print(shoot_cd)
		if shoot_cd <= 0:
			rpc("shoot_aim", owner.position)

func get_attack1_cooldown():
	return 0
	
func get_attack2_cooldown():
	return 0
	
func get_movement_cooldown():
	return 0
	
func get_ultimate_cooldown():
	return 0
