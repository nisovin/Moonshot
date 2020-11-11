extends Node2D

enum ArcherState { NORMAL, AIMING_ARROW, RELOADING, AIMING_VOLLEY, AIMING_ULTIMATE, SHADOWED }

const CrescentArrow = preload("res://player/Arrow.tscn")
const Volley = preload("res://player/Volley.tscn")
const Moonshot = preload("res://player/Moonshot.tscn")

const SERIALIZE_FIELDS = [ "state", "ultimate_duration" ]

const ARCHER_REGEN = 1

const SHOOT_AIM_TIME = 0.4
const SHOOT_ARROW_COUNT = 5
const SHOOT_ARROW_SPREAD = deg2rad(35)
const SHOOT_ARROW_SPEED = 200
const SHOOT_CENTER_KNOCKBACK_STR = 300
const SHOOT_SIDE_KNOCKBACK_STR = 150
const SHOOT_KNOCKBACK_DUR = 0.1
const SHOOT_CENTER_DAMAGE = 40
const SHOOT_SIDE_DAMAGE = 10
const SHOOT_COST = 5
const SHOOT_COOLDOWN = 0.5

const VOLLEY_RADIUS = 64
const VOLLEY_DAMAGE_DELAY = 0.3
const VOLLEY_DAMAGE = 25
const VOLLEY_STUN_DUR = 0.2
const VOLLEY_COST = 5
const VOLLEY_COOLDOWN = 10

const SHADOW_DURATION_MIN = 2
const SHADOW_SPEED_MULT = 2.5
const SHADOW_MODULATE = Color(0.36, 0.36, 0.5, 0.6)
const SHADOW_COST = 20
const SHADOW_COST_PER_SECOND = 10
const SHADOW_COOLDOWN = 5

const ULTIMATE_ARROW_SPEED = 150
const ULTIMATE_DAMAGE = 80
const ULTIMATE_COOLDOWN = 90
const ULTIMATE_CD_REDUCE_KILL_BLOW = 1

const ABILITIES = [
	{
		"name": "Waxing Crescent",
		"description": "Draw your lunar longbow, firing " + str(SHOOT_ARROW_COUNT) + " arrows. Primary arrow deals " + str(SHOOT_CENTER_DAMAGE) + " damage, and other arrows deal " + str(SHOOT_SIDE_DAMAGE) + " damage.",
		"cost": str(SHOOT_COST) + " energy"
	},
	{
		"name": "Falling Stars",
		"description": "Launch a volley of arrows at a targeted location, dealing " + str(VOLLEY_DAMAGE) + " to enemies in the area.",
		"cost": str(VOLLEY_COST) + " energy",
		"cooldown": str(VOLLEY_COOLDOWN) + " seconds"
	},
	{
		"name": "Lunar Shadow",
		"description": "Become a shadow. While a shadow, you are invisible to enemies and are able to walk through them, and you move twice as fast. You cannot use abilities as a shadow.",
		"cost": str(SHADOW_COST) + " energy, plus " + str(SHADOW_COST_PER_SECOND) + " per second",
		"cooldown": str(SHADOW_COOLDOWN) + " seconds"
	},
	{
		"name": "Moonshot",
		"description": "Fire a massive moon arrow in a straight line, piercing through all enemies and dealing " + str(ULTIMATE_DAMAGE) + " damage.",
		"cooldown": str(ULTIMATE_COOLDOWN) + " seconds, reduced by killing blows"
	}
]

var state = ArcherState.NORMAL

var shoot_aim_time = 0
var shoot_cd = 0

var volley_position = Vector2.ZERO
var volley_cd = 0

var shadow_started = 0
var shadow_cd = 0
var shadow_lingering = false

var ultimate_cd = ULTIMATE_COOLDOWN

onready var arrow_spawn = $ArrowSpawnPoint
onready var shadow_tween = $ShadowTween
onready var ult_marker = $UltimateMarker

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
	var side_marker = arrow_spawn.get_node("SideArrowMarker")
	for i in SHOOT_ARROW_COUNT - 2:
		arrow_spawn.add_child(side_marker.duplicate())
	var a = -SHOOT_ARROW_SPREAD / 2
	for i in SHOOT_ARROW_COUNT - 1:
		var marker = arrow_spawn.get_child(i + 1)
		marker.rotation = a
		a += SHOOT_ARROW_SPREAD / (SHOOT_ARROW_COUNT - 1)
		if i == SHOOT_ARROW_COUNT / 2 - 1:
			a += SHOOT_ARROW_SPREAD / (SHOOT_ARROW_COUNT - 1)
	arrow_spawn.visible = false
	ult_marker.visible = false
		
func is_moving():
	return false

func got_kill(enemy, killing_blow):
	print("KILL", killing_blow)
	if killing_blow and ultimate_cd > 0:
		ultimate_cd -= ULTIMATE_CD_REDUCE_KILL_BLOW
		print(ultimate_cd)
		
func attack1_press():
	if state == ArcherState.AIMING_ULTIMATE:
		rpc("ultimate_launch", owner.position, owner.get_action_direction())
		return
	if state != ArcherState.NORMAL: return
	rpc("shoot_aim", owner.position)
	arrow_spawn.visible = true
	for m in arrow_spawn.get_children():
		m.modulate = Color.white
		m.scale = Vector2(0.2, 1)
	
func attack1_release():
	if state != ArcherState.AIMING_ARROW: return
	arrow_spawn.visible = false
	if shoot_aim_time >= SHOOT_AIM_TIME:
		rpc("shoot_fire", owner.position, owner.get_action_direction(arrow_spawn))
	else:
		rpc("shoot_end")

remotesync func shoot_aim(pos):
	state = ArcherState.AIMING_ARROW
	shoot_aim_time = 0
	owner.position = pos
	owner.pause_movement()

remotesync func shoot_fire(pos, dir):
	owner.position = pos
	shoot_cd = SHOOT_COOLDOWN
	var vel = dir * SHOOT_ARROW_SPEED
	vel = vel.rotated(-SHOOT_ARROW_SPREAD / 2)
	for i in SHOOT_ARROW_COUNT:
		var arrow = CrescentArrow.instance()
		Game.level.projectiles_node.add_child(arrow)
		arrow.init(arrow_spawn.global_position, vel, i != SHOOT_ARROW_COUNT / 2)
		vel = vel.rotated(SHOOT_ARROW_SPREAD / (SHOOT_ARROW_COUNT - 1))
		arrow.connect("hit", self, "shoot_hit")
		shoot_end()

func shoot_hit(enemy, vel, mini):
	var knockback = SHOOT_SIDE_KNOCKBACK_STR if mini else SHOOT_CENTER_KNOCKBACK_STR
	if enemy.is_network_master():
		var dam = SHOOT_SIDE_DAMAGE if mini else SHOOT_CENTER_DAMAGE
		enemy.hit({"damage": dam, "knockback": vel.normalized() * knockback, "knockback_dur": SHOOT_KNOCKBACK_DUR})
	else:
		enemy.local_hit(vel.normalized() * knockback, SHOOT_KNOCKBACK_DUR)

remotesync func shoot_end():
	state = ArcherState.NORMAL
	owner.resume_movement()
	
func attack2_press():
	if state == ArcherState.AIMING_ULTIMATE:
		ultimate_cancel()
		return
	if state == ArcherState.AIMING_ARROW:
		state = ArcherState.NORMAL
		arrow_spawn.visible = false
		return
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
	volley_cd = VOLLEY_COOLDOWN
	owner.resume_movement()
	var volley = Volley.instance()
	Game.level.ground_effects_node.add_child(volley)
	volley.init(pos, VOLLEY_RADIUS)
	yield(get_tree().create_timer(VOLLEY_DAMAGE_DELAY), "timeout")
	for enemy in volley.get_overlapping_bodies():
		if enemy.is_in_group("enemies"):
			if enemy.is_network_master():
				enemy.hit({"damage": VOLLEY_DAMAGE, "stun": VOLLEY_STUN_DUR})
			else:
				enemy.local_hit()
	
func movement_press():
	if state != ArcherState.NORMAL: return
	if shadow_cd > 0 or shadow_lingering: return
	rpc("start_shadow", owner.position)
	
func movement_release():
	if state != ArcherState.SHADOWED: return
	if shadow_lingering: return
	var shadow_end = shadow_started + SHADOW_DURATION_MIN * 1000
	if OS.get_ticks_msec() < shadow_end:
		shadow_lingering = true
		yield(get_tree().create_timer((shadow_end - OS.get_ticks_msec()) / 1000), "timeout")
	rpc("stop_shadow", owner.position)

remotesync func start_shadow(pos):
	state = ArcherState.SHADOWED
	shadow_cd = SHADOW_COOLDOWN
	shadow_started = OS.get_ticks_msec()
	owner.position = pos
	owner.current_speed = owner.NORMAL_SPEED * SHADOW_SPEED_MULT
	owner.collision.disabled = true
	owner.targetable = false
	owner.untarget()
	shadow_tween.stop_all()
	shadow_tween.interpolate_property(owner.sprite, "modulate", Color.white, SHADOW_MODULATE, 0.2)
	shadow_tween.start()
	
remotesync func stop_shadow(pos):
	state = ArcherState.NORMAL
	shadow_cd = SHADOW_COOLDOWN
	shadow_lingering = false
	owner.position = pos
	owner.current_speed = owner.NORMAL_SPEED
	owner.collision.disabled = false
	owner.targetable = true
	shadow_tween.stop_all()
	shadow_tween.interpolate_property(owner.sprite, "modulate", SHADOW_MODULATE, Color.white, 0.2)
	shadow_tween.start()

func ultimate_press():
	if state == ArcherState.AIMING_ULTIMATE:
		rpc("ultimate_launch", owner.position, owner.get_action_direction())
		return
	if state != ArcherState.NORMAL: return
	if ultimate_cd > 0: return
	state = ArcherState.AIMING_ULTIMATE
	ult_marker.visible = true
	
func ultimate_release():
	pass
	
func ultimate_cancel():
	state = ArcherState.NORMAL
	ult_marker.visible = false

remotesync func ultimate_launch(pos, dir):
	state = ArcherState.NORMAL
	ultimate_cd = ULTIMATE_COOLDOWN
	owner.position = pos
	ult_marker.visible = false
	var vel = dir * ULTIMATE_ARROW_SPEED
	var arrow = Moonshot.instance()
	Game.level.projectiles_node.add_child(arrow)
	arrow.init(owner.position, vel)
	arrow.connect("hit", self, "ultimate_hit")

func ultimate_hit(enemy, vel):
	if enemy.is_network_master():
		enemy.hit({"damage": ULTIMATE_DAMAGE})
	else:
		enemy.local_hit(null)

func _physics_process(delta):
	if state == ArcherState.AIMING_ARROW and is_network_master():
		shoot_aim_time += delta
		var dir = owner.get_action_direction(arrow_spawn)
		arrow_spawn.rotation = dir.angle()
		owner.set_facing(dir, true)
		var scale = 0.2 + min(shoot_aim_time / SHOOT_AIM_TIME * 1.6, 1.6)
		for m in arrow_spawn.get_children():
			m.scale.x = scale
			if shoot_aim_time >= SHOOT_AIM_TIME:
				m.modulate = Color.cyan
			else:
				m.modulate = Color.white
	elif state == ArcherState.AIMING_ULTIMATE and is_network_master():
		var dir = owner.get_action_direction()
		ult_marker.rotation = dir.angle()
		owner.set_facing(dir, true)
	if shoot_cd > 0: shoot_cd -= delta
	if volley_cd > 0: volley_cd -= delta
	if shadow_cd > 0 and state != ArcherState.SHADOWED: shadow_cd -= delta
	if ultimate_cd > 0: ultimate_cd -= delta

func get_attack1_cooldown():
	if shoot_cd <= 0: return 0
	return shoot_cd / SHOOT_COOLDOWN
	
func get_attack2_cooldown():
	if volley_cd <= 0: return 0
	return volley_cd / VOLLEY_COOLDOWN
	
func get_movement_cooldown():
	if shadow_cd <= 0: return 0
	return shadow_cd / SHADOW_COOLDOWN
	
func get_ultimate_cooldown():
	if ultimate_cd <= 0: return 0
	return ultimate_cd / ULTIMATE_COOLDOWN
