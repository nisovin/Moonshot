extends Control

const SCALE = 16

func _physics_process(delta):
	update()
	
func _draw():
	if Game.player == null: return
	
	
	# draw bg
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0, 0, 0, 0.75))
	
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
			if e.max_health >= 150:
				big_ones.append(rel)
			else:
				draw_rect(Rect2(rel, Vector2.ONE), Color.red)
	for p in big_ones:
		draw_rect(Rect2(p + Vector2.UP, Vector2(1, 3)), Color.orange)
		draw_rect(Rect2(p + Vector2.LEFT, Vector2(3, 1)), Color.orange)
		
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
			draw_rect(Rect2(rel, Vector2.ONE), Color.lightcyan)
			
	# draw myself
	draw_rect(Rect2(rect_size / 2, Vector2.ONE), Color.yellow)

	# draw border
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color.gray, false, 2)

func get_relative_position(pos):
	var center = rect_size / 2
	var rel = pos - Game.player.position
	rel /= SCALE
	rel.x = floor(rel.x) if rel.x < 0 else ceil(rel.x)
	rel.y = floor(rel.y) if rel.y < 0 else ceil(rel.y)
	return center + rel
