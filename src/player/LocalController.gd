extends Node

const JOY_SNAP = PI / 8
const JOY_DEADZONE = 0.5

var move_h = 0
var move_v = 0
var sync_move = false

var tick = 0

func _physics_process(delta):
	if Game.mp_mode == Game.MPMode.SOLO: return
	tick += 1
	if tick >= 6:
		tick = 0
	var has_motion = (owner.move_dir != Vector2.ZERO and owner.current_speed > 0) or owner.player_class.is_moving()
	if has_motion or sync_move:
		if tick == 0 and get_tree().has_network_peer() and not owner.dead:
			owner.rpc_unreliable_id(1, "update_position", owner.position)
			if has_motion:
				sync_move = true
			else:
				sync_move = false

func _unhandled_input(event):
	if Game.lock_player_input or owner.dead: return
	
	# joystick
	
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_0 or event.axis == JOY_AXIS_1:
			var v = Vector2(Input.get_joy_axis(event.device, JOY_AXIS_0), Input.get_joy_axis(event.device, JOY_AXIS_1))
			var l = v.length()
			if l < JOY_DEADZONE:
				v = Vector2.ZERO
			else:
				var a = round(v.angle() / JOY_SNAP) * JOY_SNAP
				v = Vector2.RIGHT.rotated(a)
				if not Game.using_controller:
					Game.using_controller = true
					Game.controller_index = event.device
					Game.emit_signal("input_method_changed", "joy")
			if move_h != v.x or move_v != v.y:
				move_h = v.x
				move_v = v.y
				_apply_movement()
			#owner.player_class.aim(v)
	
	# keyboard vs controller
	
	if (event is InputEventKey or event is InputEventMouseButton) and Game.using_controller:
		Game.using_controller = false
		Game.emit_signal("input_method_changed", "key")
	if event is InputEventJoypadButton and not Game.using_controller:
		Game.using_controller = true
		Game.controller_index = event.device
		Game.emit_signal("input_method_changed", "joy")
	
	# movement
	
	if event.is_action_pressed("up"):
		move_v = -1
		_apply_movement()
	elif event.is_action_released("up"):
		if Input.is_action_pressed("down"):
			move_v = 1
		else:
			move_v = 0
		_apply_movement()
		
	elif event.is_action_pressed("down"):
		move_v = 1
		_apply_movement()
	elif event.is_action_released("down"):
		if Input.is_action_pressed("up"):
			move_v = -1
		else:
			move_v = 0
		_apply_movement()
		
	elif event.is_action_pressed("left"):
		move_h = -1
		_apply_movement()
	elif event.is_action_released("left"):
		if Input.is_action_pressed("right"):
			move_h = 1
		else:
			move_h = 0
		_apply_movement()
		
	elif event.is_action_pressed("right"):
		move_h = 1
		_apply_movement()
	elif event.is_action_released("right"):
		if Input.is_action_pressed("left"):
			move_h = -1
		else:
			move_h = 0
		_apply_movement()
		
	# actions
		
	elif event.is_action_pressed("interact"):
		owner.interact()
		
	elif event.is_action_pressed("attack1"):
		owner.player_class.attack1_press()
	elif event.is_action_released("attack1"):
		owner.player_class.attack1_release()
		
	elif event.is_action_pressed("attack2"):
		owner.player_class.attack2_press()
	elif event.is_action_released("attack2"):
		owner.player_class.attack2_release()
		
	elif event.is_action_pressed("ultimate"):
		owner.player_class.ultimate_press()
	elif event.is_action_released("ultimate"):
		owner.player_class.ultimate_release()
		
	elif event.is_action_pressed("movement"):
		owner.player_class.movement_press()
	elif event.is_action_released("movement"):
		owner.player_class.movement_release()
		
func _apply_movement():
	if Game.level.is_effect_active(Game.Effects.CONFUSION):
		move_h *= -1
		move_v *= -1
	if get_tree().has_network_peer() and not owner.dead:
		owner.rpc("set_movement", move_h, move_v, owner.position)
	else:
		owner.set_movement(move_h, move_v, owner.position)
