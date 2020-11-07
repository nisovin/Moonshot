extends AnimatedSprite

export(NodePath) var follow_path

var follow = null
var pos_offset = Vector2.ZERO
var prev_pos = Vector2.ZERO

func _ready():
	if follow == null:
		follow = get_parent()
	pos_offset = global_position - follow.global_position
	prev_pos = global_position
	set_as_toplevel(true)

func _process(delta):
	var target_pos = follow.global_position + pos_offset
	global_position = lerp(prev_pos, target_pos, Engine.get_physics_interpolation_fraction())

func _physics_process(delta):
	prev_pos = global_position
