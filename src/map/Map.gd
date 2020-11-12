extends Node2D

const TILE_SIZE = 16

onready var ground = $Ground
onready var objects = $Objects
onready var des_walls = $Objects/Walls

var corner = Vector2.ZERO
var map_size = Vector2.ZERO

var list = []
var astar := AStar2D.new()

func _ready():
	var rect1 = ground.get_used_rect()
	var rect2 = objects.get_used_rect()
	corner = Vector2(min(rect1.position.x, rect2.position.x), min(rect1.position.y, rect2.position.y))
	map_size = Vector2(max(rect1.size.x, rect2.size.x), max(rect1.size.y, rect2.size.y))
	
	var wall_ids = []
	for wall in des_walls.get_children():
		wall.connect("status_changed", self, "_on_wall_status_changed")
		for p in wall.points:
			var id = _get_vector_point_id(p)
			wall_ids.append(id)
			wall.ids.append(id)
	
	for x in map_size.x:
		for y in map_size.y:
			var id = _get_point_id(x, y)
			var v = Vector2(x, y)
			var t = v + corner
			var ground_cell = ground.get_cellv(t)
			var wall_cell = objects.get_cellv(t)
			if ground_cell >= 0 and wall_cell < 0:
				var point = Vector2(t.x * TILE_SIZE + TILE_SIZE / 2, t.y * TILE_SIZE + TILE_SIZE / 2)
				var is_wall = id in wall_ids
				astar.add_point(id, point, 25.0 if is_wall else 1.0)
				list.append(point)
				
	for x in map_size.x:
		for y in map_size.y:
			var id = _get_point_id(x, y)
			var id_down = _get_point_id(x, y + 1)
			var id_left = _get_point_id(x - 1, y)
			var id_right = _get_point_id(x + 1, y)
			var id_downleft = _get_point_id(x - 1, y + 1)
			var id_downright = _get_point_id(x + 1, y + 1)
			if astar.has_point(id_down):
				astar.connect_points(id, id_down)
			if astar.has_point(id_right):
				astar.connect_points(id, id_right)
			if astar.has_point(id_right) and astar.has_point(id_down) and astar.has_point(id_downright):
				astar.connect_points(id, id_downright)
			if astar.has_point(id_left) and astar.has_point(id_down) and astar.has_point(id_downleft):
				astar.connect_points(id, id_downleft)
				
func update_points_weight(points, weight):
	for p in points:
		var id = _get_vector_point_id(p)
		if astar.has_point(id):
			astar.set_point_weight_scale(id, weight)
			
func toggle_points(points, enabled):
	for p in points:
		var id = _get_vector_point_id(p)
		if astar.has_point(id):
			astar.set_point_disabled(id, not enabled)
				
func get_nav_path(from, to, get_cost = false):
	var id_from = _get_vector_point_id(from)
	if not astar.has_point(id_from):
		id_from = astar.get_closest_point(from)
	var id_to = _get_vector_point_id(to)
	if not astar.has_point(id_to):
		id_to = astar.get_closest_point(to)
	if get_cost:
		var path = astar.get_id_path(id_from, id_to)
		var points = []
		var cost = 0
		for id in path:
			points.append(astar.get_point_position(id))
			cost += astar.get_point_weight_scale(id)
		return [points, cost]
	else:
		return astar.get_point_path(id_from, id_to)

func _on_wall_status_changed(ids, status):
	var weight = 1.0
	if status == 3:
		weight = 25
	elif status == 2:
		weight = 15
	elif status == 1:
		weight = 5
	for id in ids:
		astar.set_point_weight_scale(id, weight)

func _get_vector_point_id(v):
	return _get_point_id(int(floor(v.x / TILE_SIZE)), int(floor(v.y / TILE_SIZE)))

func _get_point_id(x: int, y: int):
	return x * map_size.x + y
