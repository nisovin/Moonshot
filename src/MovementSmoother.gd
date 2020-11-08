extends Node2D

export(NodePath) var follow_path

var enabled = false
var follow = null
var discrep = Vector2.ZERO
var w = 0

func _ready():
	set_process(false)
	set_physics_process(false)

func enable_smoothing():
	if follow == null:
		follow = get_parent()
	var sprite_parent = follow.get_node_or_null("../../Smoothed")
	print(sprite_parent)
	if sprite_parent != null:
		get_parent().remove_child(self)
		sprite_parent.add_child(self)
		set_process(true)
		set_physics_process(true)
		enabled = true

func move(v):
	if enabled:
		global_position += v

func teleport():
	if follow != null:
		global_position = follow.global_position
		discrep = Vector2.ZERO

func _process(delta):
	var target_pos = follow.global_position
	var new_discrep = target_pos - global_position
	if new_discrep.is_equal_approx(Vector2.ZERO):
		discrep = Vector2.ZERO
		w = 0
	elif new_discrep.is_equal_approx(discrep):
		w += delta * 10
		if w > 1:
			global_position = target_pos
			discrep = Vector2.ZERO
			w = 0
		else:
			global_position = lerp(global_position, target_pos, w)
	else:
		w = delta * 10
		global_position = lerp(global_position, target_pos, w)
