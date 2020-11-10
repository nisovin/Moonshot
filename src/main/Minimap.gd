extends Control

const SCALE = 32

func _physics_process(delta):
	update()
	
func _draw():
	var myself = get_tree().get_nodes_in_group("myself")
	if myself.size() == 0: return
	myself = myself[0]
	
	var center = rect_size / 2
	
	# draw bg
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0, 0, 0, 0.5))
	
	# draw enemies
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead:
			var rel = e.position - myself.position
			rel /= SCALE
			rel.x = floor(rel.x) if rel.x < 0 else ceil(rel.x)
			rel.y = floor(rel.y) if rel.y < 0 else ceil(rel.y)
			draw_rect(Rect2(center + rel, Vector2.ONE), Color.red)
			
	# draw players
	for p in get_tree().get_nodes_in_group("players"):
		if p != myself and not p.dead:
			var rel = p.position - myself.position
			rel /= SCALE
			rel.x = floor(rel.x) if rel.x < 0 else ceil(rel.x)
			rel.y = floor(rel.y) if rel.y < 0 else ceil(rel.y)
			draw_rect(Rect2(center + rel, Vector2.ONE), Color.cyan)
			
	# draw myself
	draw_rect(Rect2(center, Vector2.ONE), Color.yellow)
