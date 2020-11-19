extends Node2D

const WALL_WEIGHT_4 = 150
const WALL_WEIGHT_3 = 100
const WALL_WEIGHT_2 = 50
const WALL_WEIGHT_1 = 25

export(NodePath) var ground_path
export(NodePath) var ground_effects_path
export(NodePath) var players_path
export(NodePath) var enemies_path
export(NodePath) var projectiles_path
export(NodePath) var smoothed_path
export(NodePath) var walls_path
export(NodePath) var shrine1_path
export(NodePath) var shrine2_path
export(NodePath) var player_spawns_path
export(NodePath) var enemy_spawns_path
export(NodePath) var firewall_path

onready var ground = $Ground
onready var objects = $Objects
onready var paths = $Paths
onready var des_walls = $Objects/Walls
onready var exclusions = $NavExclusions

var corner = Vector2.ZERO
var map_size = Vector2.ZERO

#var list = []
var astar := AStar2D.new()
var map_texture: Texture = null

func _ready():
	var rect1 = ground.get_used_rect()
	var rect2 = objects.get_used_rect()
	corner = Vector2(min(rect1.position.x, rect2.position.x), min(rect1.position.y, rect2.position.y))
	map_size = Vector2(max(rect1.size.x, rect2.size.x), max(rect1.size.y, rect2.size.y))
	
	var test = true
	
	# generate astar navigation
	if test or Game.is_host():
		
		var wall_ids = []
		for wall in des_walls.get_children():
			wall.connect("status_changed", self, "_on_wall_status_changed")
			for p in wall.points:
				var id = _get_vector_point_id(p)
				wall_ids.append(id)
				wall.ids.append(id)
				
		var exclude_polys = []
		for p in exclusions.get_children():
			var poly = PoolVector2Array()
			for point in p.polygon:
				poly.append(point + p.position)
			exclude_polys.append(poly)
		
		for y in map_size.y:
			for x in map_size.x:
				var id = _get_point_id(x, y)
				var v = Vector2(x, y)
				var t = v + corner
				var ground_cell = ground.get_cellv(t)
				var wall_cell = objects.get_cellv(t)
				var point = Vector2(t.x * Game.TILE_SIZE + Game.TILE_SIZE / 2, t.y * Game.TILE_SIZE + Game.TILE_SIZE / 2)
				var excluded = false
				for poly in exclude_polys:
					if Geometry.is_point_in_polygon(point, poly):
						excluded = true
						break
				if ground_cell >= 0 and wall_cell < 0 and not excluded:
					var is_wall = id in wall_ids
					astar.add_point(id, point, WALL_WEIGHT_4 if is_wall else 1)
					#list.append(point)
					
		for y in map_size.y - 1:
			for x in map_size.x - 1:
				var id = _get_point_id(x, y)
				if not astar.has_point(id):
					continue
				var id_right = _get_point_id(x + 1, y)
				var id_left = -1 if x == 0 else _get_point_id(x - 1, y)
				var id_down = _get_point_id(x, y + 1)
				var id_downleft = -1 if x == 0 else _get_point_id(x - 1, y + 1)
				var id_downright = _get_point_id(x + 1, y + 1)
				if astar.has_point(id_down):
					astar.connect_points(id, id_down)
				if astar.has_point(id_right):
					astar.connect_points(id, id_right)
				if astar.has_point(id_right) and astar.has_point(id_down) and astar.has_point(id_downright):
					astar.connect_points(id, id_downright)
				if astar.has_point(id_left) and astar.has_point(id_down) and astar.has_point(id_downleft):
					astar.connect_points(id, id_downleft)

	# generate map texture
	if Game.is_player():
		var map_image = Image.new()
		map_image.create(map_size.x, map_size.y, false, Image.FORMAT_RGB8)
		map_image.lock()
		for x in map_size.x:
			for y in map_size.y:
				var tile = Vector2(x, y) + corner
				var color = Color.black
				if objects.get_cellv(tile) >= 0:
					color = Color(.2, .2, .2)
				elif paths.get_cellv(tile) >= 0:
					color = Color.saddlebrown
				elif ground.get_cellv(tile) >= 0:
					color = Color.mediumseagreen
				map_image.set_pixel(x, y, color)
		map_image.lock()
		map_texture = ImageTexture.new()
		map_texture.create_from_image(map_image, 0)
				
	exclusions.queue_free()
				
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
				
func get_nav_path(from, to, smooth = true, get_cost = false):
	var id_from = _get_vector_point_id(from)
	if not astar.has_point(id_from):
		id_from = astar.get_closest_point(from)
	var id_to = _get_vector_point_id(to)
	if not astar.has_point(id_to):
		id_to = astar.get_closest_point(to)
	var path: Array = []
	var cost = 0
	if get_cost:
		var id_path = astar.get_id_path(id_from, id_to)
		for id in id_path:
			path.append(astar.get_point_position(id))
			cost += astar.get_point_weight_scale(id)
	else:
		path = Array(astar.get_point_path(id_from, id_to))
#	if false and smooth and path.size() > 3:
#		var space = get_world_2d().direct_space_state
#		var start = path.pop_front()
#		var col = null
#		while path.size() > 1:
#			col = space.intersect_ray(start, path[0], [], 1)
#			if col:
#				break
#			else:
#				path.pop_front()
	if get_cost:
		return [path, cost]
	else:
		return path

func _on_wall_status_changed(ids, status):
	var weight = 1.0
	if status == 4:
		weight = WALL_WEIGHT_4
	elif status == 3:
		weight = WALL_WEIGHT_3
	elif status == 2:
		weight = WALL_WEIGHT_2
	elif status == 1:
		weight = WALL_WEIGHT_1
	for id in ids:
		astar.set_point_weight_scale(id, weight)

func _get_vector_point_id(v):
	v.x = floor(v.x / Game.TILE_SIZE) - corner.x
	v.y = floor(v.y / Game.TILE_SIZE) - corner.y
	return _get_point_id(int(v.x), int(v.y))

func _get_point_id(x: int, y: int):
	return x + y * map_size.x
