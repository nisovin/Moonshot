extends KinematicBody2D

var move_dir = Vector2.ZERO
var current_speed = 100

func init(mode):
	if mode == Game.MPMode.REMOTE:
		# remote player
		$LocalController.queue_free()
		$Camera2D.queue_free()
		$CollisionShape2D.queue_free()
	elif mode == Game.MPMode.SERVER:
		# server
		set_physics_process(false)
		$RemoteController.queue_free()
		$LocalController.queue_free()
		$Camera2D.queue_free()
		$CollisionShape2D.queue_free()
	else:
		# local player
		$RemoteController.queue_free()
		$Camera2D.current = true

func _physics_process(delta):
	move_and_slide(move_dir * current_speed)

remotesync func set_movement(x, y):
	move_dir = Vector2(x, y).normalized()

remote func update_position(pos):
	position = pos

remotesync func sword_attack():
	pass
