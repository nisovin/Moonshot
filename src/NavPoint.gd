tool
extends Position2D

export(float) var weight = 1.0
export(Array, String) var connections = []

func add_connection(c):
	if connections.empty():
		connections = []
	if not c in connections:
		connections.append(c)
		
func has_connection(c):
	return c in connections
	
func remove_connection(c):
	connections.erase(c)

func _draw():
	draw_circle(Vector2.ZERO, 3, Color.red)
