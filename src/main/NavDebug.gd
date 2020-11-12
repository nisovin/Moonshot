extends Node2D

func _draw():
	var astar = get_parent().astar
	for id in astar.get_points():
		var v = astar.get_point_position(id)
		for c in astar.get_point_connections(id):
			var p = astar.get_point_position(c)
			draw_line(v, p, Color.yellow, 1)
	for id in astar.get_points():
		var v = astar.get_point_position(id)
		var w = astar.get_point_weight_scale(id)
		draw_circle(v, 3, Color.red if w > 2 else Color.blue)
