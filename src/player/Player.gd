extends KinematicBody2D

signal became_untargetable

enum PlayerState { LOADING, NORMAL, ABILITY, DEAD }

const SERIALIZE_FIELDS = [ "player_name", "state", "move_dir", "current_speed", "facing", "facing_dir", "class_id", "global_position" ]

var player_name = "Player"
var state: int = PlayerState.NORMAL
var move_dir := Vector2.ZERO
var current_speed := 100
var facing := "down"
var facing_dir := Vector2.ZERO

var class_id: int = Game.PlayerClass.WARRIOR
var player_class = null

onready var visual = $Visual
onready var sprite = $Visual/AnimatedSprite
onready var nameplate = $Visual/Nameplate

func _ready():
	if player_class == null:
		player_class = $WarriorClass

func load_data(data):
	for field in SERIALIZE_FIELDS:
		if field in data:
			set(field, data[field])
	nameplate.text = player_name
			
	if class_id == Game.PlayerClass.WARRIOR:
		player_class = $WarriorClass
		$ArcherClass.queue_free()
	player_class.load_data(data.class_data if data.has("class_data") else null)
		
	if name == str(get_tree().get_network_unique_id()):
		$Camera2D.current = true
		nameplate.visible = false
		add_to_group("myself")
	else:
		$LocalController.queue_free()
		$Camera2D.queue_free()
		if Game.mp_mode == Game.MPMode.SERVER:
			set_physics_process(false)
		else:
			visual.enable_smoothing()

func get_data():
	var data = {}
	data.id = int(name)
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	data.class_data = player_class.get_data()
	return data

func _physics_process(delta):
	if state == PlayerState.NORMAL:
		var before = position
		var v = move_and_slide(move_dir * current_speed)
		visual.move(position - before)
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

remotesync func set_movement(x, y, pos):
	move_dir = Vector2(x, y).normalized()
	if x != 0 or y != 0:
		set_facing(move_dir)
	position = pos
		
func set_facing(v, set_anim = false):
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
	if set_anim:
		sprite.play("idle_" + facing)
	
puppet func update_position(pos):
	if Game.mp_mode == Game.MPMode.SERVER:
		position = pos
	else:
		var d = position.distance_squared_to(pos)
		if d > 25:
			position = pos
		if d > 256:
			visual.teleport()

func untarget():
	emit_signal("became_untargetable", self)

func delete():
	visual.queue_free()
	queue_free()
