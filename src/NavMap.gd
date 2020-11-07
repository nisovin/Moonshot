tool
extends Node2D

var right_click = false
var middle_click = false
var from_node = null

func _ready():
	set_process_input(true)

func _process(delta):
	if not visible: return
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		if not right_click:
			right_click = true
			if from_node == null:
				from_node = get_closest_point()
				print("from ", from_node)
			else:
				var to_node = get_closest_point()
				print("to ", to_node)
				if from_node != to_node:
					if from_node.has_connection(to_node.name):
						from_node.remove_connection(to_node.name)
						to_node.remove_connection(from_node.name)
					else:
						from_node.add_connection(to_node.name)
						to_node.add_connection(from_node.name)
				from_node = null
	else:
		right_click = false
		
	if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
		if not middle_click:
			middle_click = true
			var n = Position2D.new()
			n.set_script(load("res://NavPoint.gd"))
			add_child(n)
			n.owner = owner
			n.position = get_global_mouse_position()
	else:
		middle_click = false
		
	update()

func get_closest_point():
	var mouse = get_global_mouse_position()
	var closest_point = null
	var closest_dist = 100
	for p in get_children():
		var d = mouse.distance_squared_to(p.position)
		if d < closest_dist:
			closest_dist = d
			closest_point = p
	return closest_point

func _draw():
	for point in get_children():
		for n in point.connections:
			var other = get_node(n)
			if other:
				draw_line(point.position, other.position, Color.blue, 2, true)
				
