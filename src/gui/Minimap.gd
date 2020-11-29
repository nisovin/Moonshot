extends TextureRect

const SCALE = 16

var ready = false
var tile_corner
var map_size

func _ready():
	yield(get_tree(), "idle_frame")
	print(Game.level.map.corner)
	
	tile_corner = Game.level.map.corner
	map_size = Game.level.map.map_size * Game.TILE_SIZE / SCALE
	
	var img = Image.new()
	img.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	img.lock()
	var objects = Game.level.map.objects
	for x in map_size.x:
		for y in map_size.y:
			var tile = Vector2(x, y) + tile_corner
			var color = Color.black
			if objects.get_cellv(tile) >= 0:
				img.set_pixel(x, y, Color(0, 0.25, 0.25))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0.75))
	img.unlock()
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	texture = tex
	
	ready = true

func _physics_process(delta):
	if not ready or Game.level == null: return
	update()
	
	var center_on = Game.level.player_spawn.position
	if Game.player != null:
		center_on = Game.player.position
	rect_position = -(center_on / SCALE) + tile_corner + (get_parent().rect_size / 2)
	
func _draw():
	if not ready or Game.level == null: return
	
	# draw firewall
	var firewall = get_tree().get_nodes_in_group("firewall")
	if firewall and firewall.size() > 0:
		var rel = get_relative_position(firewall[0].position)
		rel.x = 0
		draw_rect(Rect2(rel, Vector2(rect_size.x, 1)), Color(0.25, 0.15, 0))
	
	# draw shrines
	for s in get_tree().get_nodes_in_group("shrines"):
		var rel = get_relative_position(s.position)
		var c = Color.cyan if not s.dead else Color.darkred
		draw_circle(rel, 3, c)
	
	# draw enemies
	var big_ones = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead:
			var rel = get_relative_position(e.position)
			if e.minimap_big:
				big_ones.append([rel, e.minimap_color])
			else:
				draw_rect(Rect2(rel, Vector2.ONE), e.minimap_color)
	for p in big_ones:
		draw_rect(Rect2(p[0] + Vector2.UP, Vector2(1, 3)), p[1])
		draw_rect(Rect2(p[0] + Vector2.LEFT, Vector2(3, 1)), p[1])
		
	# draw walls
	for w in get_tree().get_nodes_in_group("walls"):
		if w.status > 0:
			var rel = get_relative_position(w.position - Vector2(48, 16))
			var c = w.status / 4.0
			draw_rect(Rect2(rel, Vector2(6, 1)), Color(c, c, c))
			
	# draw players
	for p in get_tree().get_nodes_in_group("players"):
		if p != Game.player and not p.dead:
			var rel = get_relative_position(p.position)
			draw_rect(Rect2(rel, Vector2.ONE), Color.cyan)
			
	# draw myself
	if Game.player != null:
		var rel = get_relative_position(Game.player.position)
		draw_rect(Rect2(rel, Vector2.ONE), Color.yellow)
	#draw_rect(Rect2(rect_size / 2, Vector2.ONE), Color.yellow)

	# draw border
	#draw_rect(Rect2(Vector2.ZERO, rect_size), Color.gray, false, 2)

func get_relative_position(pos):
	return (pos / SCALE) - tile_corner
#	var center = rect_size / 2
#	var rel = pos - Game.player.position
#	rel /= SCALE
#	rel.x = floor(rel.x) if rel.x < 0 else ceil(rel.x)
#	rel.y = floor(rel.y) if rel.y < 0 else ceil(rel.y)
#	return center + rel
