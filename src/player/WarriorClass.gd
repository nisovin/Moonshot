extends Node2D

enum WarriorState { NORMAL, AIMING_RUSH, RUSHING }

const RUSH_MIN_DISTANCE = 50
const RUSH_MAX_DISTANCE = 150
const RUSH_CHARGE_TIME = 400
const RUSH_SPEED = 800
const RUSH_MAX_TIME = 750

var state = WarriorState.NORMAL

var rush_start_position = Vector2.ZERO
var rush_start_time = 0
var rush_direction = Vector2.ZERO
var rush_max_distance = 0

onready var rush_arrow = $RushArrow
onready var attack1area = $Attack1Area
onready var attack2area = $Attack2Area

func _ready():
	rush_arrow.visible = false

func init(network_mode):
	if network_mode == Game.MPMode.SERVER:
		set_physics_process(false)

func is_moving():
	return state == WarriorState.RUSHING

func attack1_start():
	print("hi")
	var hit_list = []
	for body in attack1area.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			hit_list.append(owner.position, body.name)
	rpc("attack1", owner.position, get_action_direction(), hit_list)

remotesync func attack1(pos, dir, enemies_hit):
	print("attack", dir)
	owner.position = pos
	owner.set_facing(dir.normalized())
	for id in enemies_hit:
		pass
	
func attack1_end():
	pass
	
func attack2_start():
	pass
	
func attack2_end():
	pass
	
func ultimate_start():
	pass
	
func ultimate_end():
	pass
	
func movement_start():
	if state != WarriorState.NORMAL: return
	state = WarriorState.AIMING_RUSH
	rush_start_time = OS.get_ticks_msec()
	owner.pause_movement()
	rush_arrow.visible = true
	rush_arrow.scale.x = 1.0
	if owner.move_dir != Vector2.ZERO:
		rush_arrow.rotation = owner.move_dir.angle()
	else:
		rush_arrow.rotation = Vector2.UP.angle()
	update_rush_arrow()
	
func movement_end():
	if state != WarriorState.AIMING_RUSH: return
	rush_arrow.visible = false
	rpc("start_rush", owner.position, Vector2.RIGHT.rotated(rush_arrow.rotation), get_rush_distance())

func update_rush_arrow():
	rush_arrow.scale.x = get_rush_distance() / RUSH_MIN_DISTANCE
	var v = get_action_direction()
	if v != Vector2.ZERO:
		rush_arrow.rotation = v.angle()

func get_rush_distance():
	var time = float(clamp(OS.get_ticks_msec() - rush_start_time, 0, RUSH_CHARGE_TIME))
	return RUSH_MIN_DISTANCE + ((RUSH_MAX_DISTANCE - RUSH_MIN_DISTANCE) * (time / RUSH_CHARGE_TIME))

remotesync func start_rush(start_pos, rush_dir, max_dist):
	owner.position = start_pos
	rush_start_time = OS.get_ticks_msec()
	rush_start_position = start_pos
	rush_direction = rush_dir
	rush_max_distance = max_dist
	state = WarriorState.RUSHING

remotesync func end_rush(end_pos, collided):
	owner.position = end_pos
	state = WarriorState.NORMAL
	owner.resume_movement()

func _process(delta):
	if state == WarriorState.AIMING_RUSH:
		update_rush_arrow()

func _physics_process(delta):
	if state == WarriorState.RUSHING:
		var col = owner.move_and_collide(rush_direction * RUSH_SPEED * delta)
		if is_network_master():
			if col or OS.get_ticks_msec() > rush_start_time + RUSH_MAX_TIME or owner.position.distance_squared_to(rush_start_position) > rush_max_distance * rush_max_distance:
				rpc("end_rush", owner.position, col != null)
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
		else:
			return Vector2.ZERO
	else:
		return owner.get_local_mouse_position()
	
