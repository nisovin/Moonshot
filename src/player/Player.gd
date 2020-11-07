extends KinematicBody2D

enum PlayerState { LOADING, NORMAL, ABILITY, DEAD }

const SERIALIZE_FIELDS = [ "state", "move_dir", "current_speed", "facing", "facing_dir", "class_id", "global_position" ]

var state: int = PlayerState.NORMAL
var move_dir := Vector2.ZERO
var current_speed := 100
var facing := "down"
var facing_dir := Vector2.ZERO

var class_id: int = Game.PlayerClass.WARRIOR
var player_class = null

onready var sprite = $AnimatedSprite

func _ready():
	if player_class == null:
		player_class = $WarriorClass

func load_data(data):
	for field in SERIALIZE_FIELDS:
		if field in data:
			set(field, data[field])
	if "nameplate" in data:
		$AnimatedSprite/Nameplate.text = data.nameplate
			
	if class_id == Game.PlayerClass.WARRIOR:
		player_class = $WarriorClass
		$ArcherClass.queue_free()
	if "class_data" in data:
		player_class.load_data(data.class_data)
		
	if name == str(get_tree().get_network_unique_id()):
		$Camera2D.current = true
		$AnimatedSprite/Nameplate.visible = false
	else:
		$LocalController.queue_free()
		$Camera2D.queue_free()
		$CollisionShape2D.queue_free()
		if Game.mp_mode == Game.MPMode.SERVER:
			set_physics_process(false)

func get_data():
	var data = {}
	data.id = int(name)
	data.nameplate = $Nameplate.text
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	data.class_data = player_class.get_data()
	return data

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
	facing_dir = v
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
