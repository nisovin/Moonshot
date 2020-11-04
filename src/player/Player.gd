extends KinematicBody2D

enum PlayerState { LOADING, NORMAL, ABILITY, DEAD }

var state = PlayerState.NORMAL
var move_dir = Vector2.ZERO
var current_speed = 100
var facing = "down"

var player_class = null

onready var sprite = $AnimatedSprite

func _ready():
	if player_class == null:
		player_class = $WarriorClass

func init(network_mode, selected_class):
	if network_mode == Game.MPMode.REMOTE:
		# remote player
		$LocalController.queue_free()
		$Camera2D.queue_free()
		$CollisionShape2D.queue_free()
	elif network_mode == Game.MPMode.SERVER:
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
		
	if selected_class == Game.PlayerClass.WARRIOR:
		player_class = $WarriorClass
		$ArcherClass.queue_free()
		
	player_class.init(network_mode)

func _physics_process(delta):
	if state == PlayerState.NORMAL:
		var v = move_and_slide(move_dir * current_speed)
		if state == PlayerState.NORMAL:
			if v != Vector2.ZERO:
				sprite.play("walk_" + facing)
			else:
				sprite.play("idle_" + facing)

func pause_movement():
	state = PlayerState.ABILITY
	sprite.play("idle_" + facing)
	
func resume_movement():
	state = PlayerState.NORMAL
	sprite.play("idle_" + facing)

remotesync func set_movement(x, y):
	move_dir = Vector2(x, y).normalized()
	if x != 0 or y != 0:
		set_facing(move_dir)
		
func set_facing(v):
	if abs(v.x) >= abs(v.y):
		if v.x > 0:
			facing = "right"
		else:
			facing = "left"
	else:
		if v.y > 0:
			facing = "down"
		else:
			facing = "up"
	
		

puppet func update_position(pos):
	if Game.mp_mode == Game.MPMode.SERVER or move_dir == Vector2.ZERO or position.distance_squared_to(pos) > 25:
		position = pos
