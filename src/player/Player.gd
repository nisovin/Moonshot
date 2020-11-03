extends KinematicBody2D

var move_dir = Vector2.ZERO
var current_speed = 100

var player_class

func init(network_mode, selected_class):
	if network_mode == Game.MPMode.REMOTE:
		# remote player
		$LocalController.queue_free()
		$Camera2D.queue_free()
		$CollisionShape2D.queue_free()
	elif network_mode == Game.MPMode.SERVER:
		# server
		set_physics_process(false)
		print("OK")
		$RemoteController.queue_free()
		$LocalController.queue_free()
		$Camera2D.queue_free()
		$CollisionShape2D.queue_free()
	else:
		# local player
		$RemoteController.queue_free()
		$Camera2D.current = true
		
	if selected_class == Game.PlayerClass.WARRIOR:
		player_class = $WarriorClass
		$ArcherClass.queue_free()

func _physics_process(delta):
	move_and_slide(move_dir * current_speed)
	print(move_dir)

remotesync func set_movement(x, y):
	print("movement ", move_dir)
	move_dir = Vector2(x, y).normalized()

puppet func update_position(pos):
	if Game.mp_mode == Game.MPMode.SERVER or move_dir == Vector2.ZERO or position.distance_squared_to(pos) > 25:
		position = pos

remotesync func sword_attack():
	pass
