extends Node2D

signal status_changed

var status = 3
var points = []
var ids = []

onready var target = $Target.global_position

func _ready():
	points.append(global_position + Vector2(-24, -8))
	points.append(global_position + Vector2(-8, -8))
	points.append(global_position + Vector2(8, -8))
	points.append(global_position + Vector2(24, -8))
