extends Node2D

enum WarriorState { NORMAL, SWINGING_SWORD, AIMING_RUSH, RUSHING }

const SERIALIZE_FIELDS = [ "state", "ultimate_duration" ]

const ATTACK_SWING_TIME = 0.25
const ATTACK_SWING_ANGLE = PI * 0.8
const ATTACK_DOT_ARC = cos(ATTACK_SWING_ANGLE / 2)
const ATTACK_MOVE_SPEED = 25
const ATTACK_DAMAGE = 2
const ATTACK_KNOCKBACK_STR = 300
const ATTACK_KNOCKBACK_DUR = 0.1
const ATTACK_STUN_DUR = 0.5
const ATTACK_COOLDOWN = 0.25

const AOE_DAMAGE_CLOSE = 8
const AOE_DAMAGE_FAR = 3
const AOE_CLOSE_RADIUS = 40
const AOE_STUN_DUR = 1.5
const AOE_COOLDOWN = 10.0

const RUSH_MIN_DISTANCE = 50
const RUSH_MAX_DISTANCE = 140
const RUSH_CHARGE_TIME = 300
const RUSH_SPEED = 800
const RUSH_MAX_TIME = 750
const RUSH_DAMAGE = 1
const RUSH_KNOCKBACK_STR = 300
const RUSH_KNOCKBACK_DUR = 0.1
const RUSH_STUN_DUR = 0.3
const RUSH_COOLDOWN = 5.0

const ULTIMATE_ATTACK_MULT = 2
const ULTIMATE_DEFENSE_MULT = 0.5
const ULTIMATE_DURATION = 10
const ULTIMATE_COOLDOWN = 90.0

var state = WarriorState.NORMAL

var attack_swing_dir = 1
var attack_move_dir = Vector2.ZERO
var attack_cd = 0

var aoe_cd = 0

var rush_start_position = Vector2.ZERO
var rush_start_time = 0
var rush_direction = Vector2.ZERO
var rush_max_distance = 0
var rush_cd = 0

var ultimate_duration = 0
var ultimate_cd = 0

onready var attack1sword = $SwordSwing
onready var attack1tween = $SwordSwing/Tween
onready var attack1area = $Attack1Area

onready var attack2area = $Attack2Area
onready var attack2particles = $Attack2Particles
onready var ultimate_tween = $UltimateTween

onready var rush_area = $RushArea
onready var rush_arrow = $RushArrow

func _ready():
	attack1sword.visible = false
	rush_arrow.visible = false

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
	return state == WarriorState.RUSHING or state == WarriorState.SWINGING_SWORD

# ATTACK ONE - SWORD ATTACK

func attack1_press():
	if state != WarriorState.NORMAL: return
	if attack_cd > 0: return
	attack_cd = ATTACK_COOLDOWN
	rpc("attack1", owner.position, get_action_direction())
	
func attack1_release():
	pass

remotesync func attack1(pos, dir):
	owner.position = pos
	attack_move_dir = dir.normalized()
	owner.set_facing(attack_move_dir)
	var start_angle = 0
	var end_angle = 0
	if attack_swing_dir == 1:
		start_angle = dir.angle() - ATTACK_SWING_ANGLE / 2
		end_angle = start_angle + ATTACK_SWING_ANGLE
		attack_swing_dir = -1
	else:
		start_angle = dir.angle() + ATTACK_SWING_ANGLE / 2
		end_angle = start_angle - ATTACK_SWING_ANGLE
		attack_swing_dir = 1
		
	# pause
	owner.pause_movement()
	state = WarriorState.SWINGING_SWORD
	
	# anim
	attack1sword.visible = true
	attack1sword.z_index = 1 if owner.facing == "down" else 0
	attack1tween.interpolate_property(attack1sword, "rotation", start_angle, end_angle, ATTACK_SWING_TIME)
	attack1tween.start()
	
	# hit enemies
	for enemy in N.get_overlapping_bodies(attack1area, "enemies"):
		if owner.position.direction_to(enemy.position).dot(attack_move_dir) > ATTACK_DOT_ARC:
			var knockback = owner.position.direction_to(enemy.position) * ATTACK_KNOCKBACK_STR
			if enemy.is_network_master():
				var dam = ATTACK_DAMAGE
				if ultimate_duration > 0: dam *= ULTIMATE_ATTACK_MULT
				enemy.hit({"damage": dam, "knockback": knockback, "knockback_dur": ATTACK_KNOCKBACK_DUR, "stun": ATTACK_STUN_DUR})
			elif is_network_master():
				enemy.apply_local_knockback(knockback, ATTACK_KNOCKBACK_DUR)
		
	# end anim
	yield(get_tree().create_timer(ATTACK_SWING_TIME), "timeout")
	attack1sword.visible = false
	
	# unpause
	owner.resume_movement()
	state = WarriorState.NORMAL
	
# ATTACK TWO - AOE
	
func attack2_press():
	if state != WarriorState.NORMAL: return
	if aoe_cd > 0: return
	aoe_cd = AOE_COOLDOWN
	rpc("attack2", owner.position)
	
func attack2_release():
	pass

remotesync func attack2(pos):
	owner.position = pos
	
	# anim
	attack2particles.emitting = true
	
	# hit enemies
	for enemy in N.get_overlapping_bodies(attack2area, "enemies"):
		if enemy.is_network_master():
			var dist = enemy.position.distance_squared_to(owner.position)
			var dam = AOE_DAMAGE_CLOSE if dist < AOE_CLOSE_RADIUS * AOE_CLOSE_RADIUS else AOE_DAMAGE_FAR
			if ultimate_duration > 0:
				dam *= ULTIMATE_ATTACK_MULT
			enemy.hit({"damage": dam, "stun": AOE_STUN_DUR, "stun_break": false})
		else:
			enemy.apply_local_stun(AOE_STUN_DUR)

# ULTIMATE

func ultimate_press():
	if state != WarriorState.NORMAL: return
	if ultimate_cd > 0: return
	ultimate_cd = ULTIMATE_COOLDOWN
	rpc("ultimate")
	
func ultimate_release():
	pass
	
remotesync func ultimate():
	ultimate_duration = ULTIMATE_DURATION
	ultimate_tween.interpolate_property(owner.visual, "scale", Vector2.ONE, Vector2(1.4, 1.4), 0.5)
	ultimate_tween.interpolate_property(owner.sprite, "modulate", Color.white, Color(0.6, 0.9, 1), 0.5)
	ultimate_tween.start()

remotesync func end_ultimate():
	ultimate_duration = 0
	ultimate_tween.interpolate_property(owner.visual, "scale", Vector2(1.4, 1.4), Vector2.ONE, 0.5)
	ultimate_tween.interpolate_property(owner.sprite, "modulate", Color(0.6, 0.9, 1), Color.white, 0.5)
	ultimate_tween.start()

func movement_press():
	if state != WarriorState.NORMAL: return
	if rush_cd > 0: return
	state = WarriorState.AIMING_RUSH
	rush_start_time = OS.get_ticks_msec()
	rush_arrow.visible = true
	rush_arrow.scale.x = 1.0
	if owner.move_dir != Vector2.ZERO:
		rush_arrow.rotation = owner.move_dir.angle()
	else:
		rush_arrow.rotation = Vector2.UP.angle()
	update_rush_arrow()
	rpc("init_rush", owner.position)
	
func movement_release():
	if state != WarriorState.AIMING_RUSH: return
	if rush_cd > 0: return
	rush_cd = RUSH_COOLDOWN
	rush_arrow.visible = false
	rpc("start_rush", owner.position, Vector2.RIGHT.rotated(rush_arrow.rotation), get_rush_distance())

func update_rush_arrow():
	rush_arrow.scale.x = get_rush_distance() / RUSH_MIN_DISTANCE
	var v = get_action_direction()
	if v != Vector2.ZERO:
		rush_arrow.rotation = v.angle()
		owner.set_facing(v, true)

func get_rush_distance():
	var time = float(clamp(OS.get_ticks_msec() - rush_start_time, 0, RUSH_CHARGE_TIME))
	return RUSH_MIN_DISTANCE + ((RUSH_MAX_DISTANCE - RUSH_MIN_DISTANCE) * (time / RUSH_CHARGE_TIME))

remotesync func init_rush(pos):
	owner.position = pos
	owner.pause_movement()

remotesync func start_rush(start_pos, rush_dir, max_dist):
	owner.position = start_pos
	owner.set_facing(rush_dir, true)
	print("start_rush ", rush_dir)
	rush_start_time = OS.get_ticks_msec()
	rush_start_position = start_pos
	rush_direction = rush_dir
	rush_max_distance = max_dist
	state = WarriorState.RUSHING

remotesync func end_rush(end_pos, collided):
	print("end rush ", end_pos, collided)
	owner.position = end_pos
	state = WarriorState.NORMAL
	owner.resume_movement()
	
	if not collided: return
	
	for enemy in N.get_overlapping_bodies(rush_area, "enemies"):
		var knockback = owner.position.direction_to(enemy.position) * RUSH_KNOCKBACK_STR
		if enemy.is_network_master():
			var dam = RUSH_DAMAGE
			if ultimate_duration > 0:
				dam *= ULTIMATE_ATTACK_MULT
			enemy.hit({"damage": dam, "knockback": knockback, "knockback_dur": RUSH_KNOCKBACK_DUR, "stun": RUSH_STUN_DUR})
		elif is_network_master():
			enemy.apply_local_knockback(knockback, RUSH_KNOCKBACK_DUR)
				

func _process(delta):
	if state == WarriorState.AIMING_RUSH:
		update_rush_arrow()

func _physics_process(delta):
	if attack_cd > 0: attack_cd -= delta
	if aoe_cd > 0: aoe_cd -= delta
	if rush_cd > 0: rush_cd -= delta
	if ultimate_cd > 0: ultimate_cd -= delta
	if ultimate_duration > 0:
		ultimate_duration -= delta
		if ultimate_duration < 0 and is_network_master():
			rpc("end_ultimate")
	if state == WarriorState.RUSHING:
		print("rushing!")
		var col = owner.move_and_collide(rush_direction * RUSH_SPEED * delta)
		if is_network_master():
			if col or OS.get_ticks_msec() > rush_start_time + RUSH_MAX_TIME or owner.position.distance_squared_to(rush_start_position) > rush_max_distance * rush_max_distance:
				rpc("end_rush", owner.position, col != null)
	elif state == WarriorState.SWINGING_SWORD:
		owner.move_and_collide(attack_move_dir * ATTACK_MOVE_SPEED * delta)
	else:
		if owner.is_network_master():
			var v = get_action_direction()
			if v != Vector2.ZERO:
				attack1area.rotation = v.angle()
				
func get_action_direction():
	if Game.using_controller:
		var v = Vector2(Input.get_joy_axis(Game.controller_index, JOY_AXIS_0), Input.get_joy_axis(Game.controller_index, JOY_AXIS_1))
		if v.length() > 0.5:
			return v
		elif owner.facing_dir != Vector2.ZERO:
			return owner.facing_dir
		else:
			return Vector2.UP
	else:
		return owner.get_local_mouse_position()
	
func get_attack1_cooldown():
	if attack_cd <= 0: return 0
	return attack_cd / ATTACK_COOLDOWN
	
func get_attack2_cooldown():
	if aoe_cd <= 0: return 0
	return aoe_cd / AOE_COOLDOWN
	
func get_movement_cooldown():
	if rush_cd <= 0: return 0
	return rush_cd / RUSH_COOLDOWN
	
func get_ultimate_cooldown():
	if ultimate_cd <= 0: return 0
	return ultimate_cd / ULTIMATE_COOLDOWN
