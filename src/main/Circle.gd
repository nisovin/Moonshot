extends Node2D

export(Color) var color = Color.white
export(float) var radius = 10

func _draw():
	draw_circle(Vector2.ZERO, radius, color)
