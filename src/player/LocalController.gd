extends Node

var move_h = 0
var move_v = 0
var sync_move = false

var tick = 0

func _physics_process(delta):
	tick += 1
	if tick > 5:
		tick = 0
	var has_motion = owner.move_dir != Vector2.ZERO and owner.current_speed > 0
	if has_motion or sync_move:
		if tick == 0 and get_tree().has_network_peer():
			owner.rpc_unreliable("update_position", owner.position)
			if has_motion:
				sync_move = true
			else:
				sync_move = false

func _unhandled_input(event):
	
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
		
	elif event.is_action_pressed("attack1"):
		owner.player_class.attack1_start()
	elif event.is_action_released("attack1"):
		owner.player_class.attack1_end()
		
	elif event.is_action_pressed("attack2"):
		owner.player_class.attack2_start()
	elif event.is_action_released("attack2"):
		owner.player_class.attack2_end()
		
	elif event.is_action_pressed("ultimate"):
		owner.player_class.ultimate_start()
	elif event.is_action_released("ultimate"):
		owner.player_class.ultimate_end()
		
	elif event.is_action_pressed("movement"):
		owner.player_class.movement_start()
	elif event.is_action_released("movement"):
		owner.player_class.movement_end()
		
func _apply_movement():
	print(move_h, ' ', move_v)
	if get_tree().has_network_peer():
		owner.rpc("set_movement", move_h, move_v)
	else:
		owner.set_movement(move_h, move_v)
