extends Node2D

enum WarriorState { NORMAL, SWINGING_SWORD, AIMING_RUSH, RUSHING }

const SERIALIZE_FIELDS = [ "state", "ultimate_duration" ]

const MAX_HEALTH = 150
const HEALTH_REGEN = 1
const ENERGY_REGEN = 10
const ENERGY_EXHAUSTION_MULT = 0.5
const NORMAL_ARMOR = 0.25

const ATTACK_SWING_TIME = 0.25
const ATTACK_SWING_ANGLE = PI * 0.8
const ATTACK_DOT_ARC = cos(ATTACK_SWING_ANGLE / 2)
const ATTACK_MOVE_SPEED = 25
const ATTACK_DAMAGE = 10
const ATTACK_KNOCKBACK_STR = 300
const ATTACK_KNOCKBACK_DUR = 0.1
const ATTACK_STUN_DUR = 0.5
const ATTACK_COST = 5
const ATTACK_COOLDOWN = 0.4

const AOE_DAMAGE_CLOSE = 40
const AOE_DAMAGE_FAR = 25
const AOE_CLOSE_RADIUS = 40
const AOE_STUN_DUR = 2.0
const AOE_COST = 15
const AOE_COOLDOWN = 10.0

const RUSH_MIN_DISTANCE = 50
const RUSH_MAX_DISTANCE = 170
const RUSH_CHARGE_TIME = 300
const RUSH_SPEED = 800
const RUSH_MAX_TIME = 750
const RUSH_DAMAGE = 10
const RUSH_KNOCKBACK_STR = 300
const RUSH_KNOCKBACK_DUR = 0.1
const RUSH_STUN_DUR = 0.3
const RUSH_COST = 50
const RUSH_COOLDOWN = 1.0

const ULTIMATE_ATTACK_MULT = 3
const ULTIMATE_ARMOR = 0.5
const ULTIMATE_ENERGY_MULT = 2
const ULTIMATE_CD_MULT = 2.0
const ULTIMATE_DURATION = 15
const ULTIMATE_KILL_EXTEND = 1
const ULTIMATE_MAX_DURATION = 30
const ULTIMATE_MODULATE = Color(0.6, 0.9, 1)
const ULTIMATE_SCALE = 1.4
const ULTIMATE_COOLDOWN = 120.0
const ULTIMATE_CD_REDUCE_KILL = 0.4
const ULTIMATE_CD_REDUCE_KILL_BLOW = 1.0

const ABILITIES = [
	{
		"name": "Crescent Cleave",
		"description": "Swing your moonblade, dealing " + str(ATTACK_DAMAGE) + " damage to all enemies in a cone in front of you, knocking them back and briefly stunning them.",
		"cost": str(ATTACK_COST) + " energy"
	},
	{
		"name": "Umbral Wave",
		"description": "Thrust your moonblade into the ground, sending a shockwave around you that deals damage and stuns enemies for " + str(AOE_STUN_DUR) + " seconds.",
		"cost": str(AOE_COST) + " energy",
		"cooldown": str(AOE_COOLDOWN) + " seconds"
	},
	{
		"name": "Astral Rush",
		"description": "Charge forward, dealing " + str(RUSH_DAMAGE) + " damage to enemies around you upon impact, and knocking them back.",
		"cost": str(RUSH_COST) + " energy",
		"cooldown": str(RUSH_COOLDOWN) + " seconds"
	},
	{
		"name": "Avatar of the Moon",
		"description": "Become an avatar of the Moon for " + str(ULTIMATE_DURATION) + " seconds. While an avatar, you deal double damage, take half damage, and restore cooldowns and energy faster. Duration extended by " + str(ULTIMATE_KILL_EXTEND) + "s for each killing blow, up to a total duration of " + str(ULTIMATE_MAX_DURATION) + " seconds.",
		"cooldown": str(ULTIMATE_COOLDOWN) + " seconds, reduced by kills"
	}
]

var state = WarriorState.NORMAL
var energy = 25

var attack_queued = false
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
var ultimate_total_duration = 0
var ultimate_cd = ULTIMATE_COOLDOWN

onready var attack1sword = $SwordSwing
onready var attack1tween = $SwordSwing/Tween
onready var attack1visual = $SwordSwing/Polygon2D
onready var attack1particles = $SwordSwing/Particles2D
onready var attack1area = $Attack1Area

onready var attack2area = $Attack2Area
onready var attack2particles = $Attack2Particles
onready var ultimate_tween = $UltimateTween

onready var rush_area = $RushArea
onready var rush_arrow = $RushArrow
onready var rush_particles = $RushParticles

func _ready():
	attack1visual.visible = false
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

func get_armor():
	if ultimate_duration > 0:
		return ULTIMATE_ARMOR
	else:
		return NORMAL_ARMOR

func got_kill(enemy, killing_blow):
	if killing_blow:
		ultimate_cd -= ULTIMATE_CD_REDUCE_KILL_BLOW
		if ultimate_duration > 0 and ultimate_total_duration < ULTIMATE_MAX_DURATION:
			ultimate_duration += ULTIMATE_KILL_EXTEND
			ultimate_total_duration += ULTIMATE_KILL_EXTEND
	else:
		ultimate_cd -= ULTIMATE_CD_REDUCE_KILL

func calculate_damage(dam):
	if ultimate_duration > 0:
		dam *= ULTIMATE_ATTACK_MULT
	if Game.level.time_of_day == "midnight":
		dam *= 2
	return dam

# ATTACK ONE - SWORD ATTACK

func attack1_press():
	if attack_cd > 0 and (state == WarriorState.NORMAL or state == WarriorState.SWINGING_SWORD):
		attack_queued = true
		return
	if state != WarriorState.NORMAL: return
	if energy < ATTACK_COST: return
	attack_queued = false
	attack_cd = ATTACK_COOLDOWN
	energy -= ATTACK_COST
	rpc("attack1", owner.position, owner.get_action_direction())
	
func attack1_release():
	pass

remotesync func attack1(pos, dir):
	owner.position = pos
	attack_move_dir = dir
	owner.set_facing(attack_move_dir)
		
	# pause
	owner.pause_movement()
	state = WarriorState.SWINGING_SWORD
	
	# anim
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
	attack1visual.visible = true
	attack1sword.scale.y = -attack_swing_dir
	attack1sword.z_index = 1 if owner.facing == "down" else 0
	attack1tween.interpolate_property(attack1sword, "rotation", start_angle, end_angle, ATTACK_SWING_TIME)
	attack1tween.start()
	attack1particles.emitting = true
	Audio.play("warrior_attack1_swing", 0.6 if is_network_master() else 0.2)
	
	# hit enemies
	var dam = calculate_damage(ATTACK_DAMAGE)
	for enemy in N.get_overlapping_hitboxes(attack1area, "enemies"):
		if owner.position.direction_to(enemy.position).dot(attack_move_dir) > ATTACK_DOT_ARC:
			var knockback = owner.position.direction_to(enemy.position) * ATTACK_KNOCKBACK_STR
			if enemy.is_network_master():
				owner.last_combat = OS.get_ticks_msec()
				enemy.hit({"damage": dam, "knockback": knockback, "knockback_dur": ATTACK_KNOCKBACK_DUR, "stun": ATTACK_STUN_DUR})
			elif is_network_master():
				enemy.local_hit(knockback, ATTACK_KNOCKBACK_DUR)
		
	# end anim
	yield(get_tree().create_timer(ATTACK_SWING_TIME), "timeout")
	attack1visual.visible = false
	attack1particles.emitting = false
	
	# unpause
	owner.resume_movement()
	state = WarriorState.NORMAL
	
# ATTACK TWO - AOE
	
func attack2_press():
	if state != WarriorState.NORMAL: return
	if aoe_cd > 0: return
	if energy < AOE_COST: return
	aoe_cd = AOE_COOLDOWN
	energy -= AOE_COST
	rpc("attack2", owner.position)
	
func attack2_release():
	pass

remotesync func attack2(pos):
	owner.position = pos
	
	# anim
	attack2particles.emitting = true
	Audio.play("warrior_attack2", 0.6 if is_network_master() else 0.3)
	
	# hit enemies
	for enemy in N.get_overlapping_bodies(attack2area, "enemies"):
		if enemy.is_network_master():
			var dist = enemy.position.distance_squared_to(owner.position)
			var dam = calculate_damage(AOE_DAMAGE_CLOSE if dist < AOE_CLOSE_RADIUS * AOE_CLOSE_RADIUS else AOE_DAMAGE_FAR)
			owner.last_combat = OS.get_ticks_msec()
			enemy.hit({"damage": dam, "stun": AOE_STUN_DUR, "stun_break": false})
		else:
			enemy.local_hit(Vector2.ZERO, AOE_STUN_DUR)

# CHARGE

func movement_press():
	if state != WarriorState.NORMAL: return
	if rush_cd > 0: return
	if energy < RUSH_COST: return
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
	energy -= RUSH_COST
	rush_cd = RUSH_COOLDOWN
	rush_arrow.visible = false
	rpc("start_rush", owner.position, Vector2.RIGHT.rotated(rush_arrow.rotation), get_rush_distance())

func update_rush_arrow():
	rush_arrow.scale.x = get_rush_distance() / RUSH_MIN_DISTANCE
	var v = owner.get_action_direction()
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
	rush_start_time = OS.get_ticks_msec()
	rush_start_position = start_pos
	rush_direction = rush_dir
	rush_max_distance = max_dist
	rush_particles.emitting = true
	state = WarriorState.RUSHING
	Audio.play("warrior_movement", 0.7 if is_network_master() else 0.4)

remotesync func end_rush(end_pos, collided):
	owner.position = end_pos
	state = WarriorState.NORMAL
	owner.resume_movement()
	rush_particles.emitting = false
	
	if not collided: return
	
	var dam = calculate_damage(RUSH_DAMAGE)
	for enemy in N.get_overlapping_hitboxes(rush_area, "enemies"):
		var knockback = owner.position.direction_to(enemy.position) * RUSH_KNOCKBACK_STR
		if enemy.is_network_master():
			owner.last_combat = OS.get_ticks_msec()
			enemy.hit({"damage": dam, "knockback": knockback, "knockback_dur": RUSH_KNOCKBACK_DUR, "stun": RUSH_STUN_DUR})
		elif is_network_master():
			enemy.local_hit(knockback, RUSH_KNOCKBACK_DUR)
				

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
	ultimate_total_duration = ultimate_duration
	ultimate_tween.interpolate_property(owner.visual, "scale", Vector2.ONE, Vector2(ULTIMATE_SCALE, ULTIMATE_SCALE), 0.5)
	ultimate_tween.interpolate_property(owner.sprite, "modulate", Color.white, ULTIMATE_MODULATE, 0.5)
	ultimate_tween.start()
	Audio.play("warrior_ultimate")

remotesync func end_ultimate():
	ultimate_duration = 0
	ultimate_tween.interpolate_property(owner.visual, "scale", Vector2(ULTIMATE_SCALE, ULTIMATE_SCALE), Vector2.ONE, 0.5)
	ultimate_tween.interpolate_property(owner.sprite, "modulate", ULTIMATE_MODULATE, Color.white, 0.5)
	ultimate_tween.start()


func _process(delta):
	if state == WarriorState.AIMING_RUSH:
		update_rush_arrow()

func _physics_process(delta):
	if attack_cd > 0:
		attack_cd -= delta
		if attack_cd <= 0 and state == WarriorState.NORMAL and (attack_queued or Input.is_action_pressed("attack1")):
			attack1_press()
			
	var regen = ENERGY_REGEN
	if Game.level.time_of_day == "midnight":
		regen *= 2
	regen *= ((100 - owner.exhaustion * ENERGY_EXHAUSTION_MULT) / 100.0)
	if ultimate_duration > 0:
		ultimate_duration -= delta
		if ultimate_duration < 0 and is_network_master():
			rpc("end_ultimate")
		if aoe_cd > 0: aoe_cd -= delta * ULTIMATE_CD_MULT
		if rush_cd > 0: rush_cd -= delta * ULTIMATE_CD_MULT
		regen *= ULTIMATE_ENERGY_MULT
	else:
		if aoe_cd > 0: aoe_cd -= delta
		if rush_cd > 0: rush_cd -= delta
		if ultimate_cd > 0: ultimate_cd -= delta
	energy = min(energy + regen * delta, 100)
	
	if state == WarriorState.RUSHING:
		var col = owner.move_and_collide(rush_direction * RUSH_SPEED * delta)
		if is_network_master():
			if col or OS.get_ticks_msec() > rush_start_time + RUSH_MAX_TIME or owner.position.distance_squared_to(rush_start_position) > rush_max_distance * rush_max_distance:
				rpc("end_rush", owner.position, col != null)
	elif state == WarriorState.SWINGING_SWORD:
		owner.move_and_collide(attack_move_dir * ATTACK_MOVE_SPEED * delta)
	else:
		if owner.is_network_master():
			var v = owner.get_action_direction()
			if v != Vector2.ZERO:
				attack1area.rotation = v.angle()
	
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
