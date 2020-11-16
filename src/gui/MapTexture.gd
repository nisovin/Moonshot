extends TextureRect

var player_pixel = Vector2.ZERO

func _draw():
	if Game.level == null: return
	var tile_corner = Game.level.map.corner
	for p in Game.level.players_node.get_children():
		if p != Game.player:
			var px = get_pixel_coord(tile_corner, p.position)
			draw_rect(Rect2(px, Vector2.ONE), Color.blue)
	for w in Game.level.walls_node.get_children():
		if w.status > 0:
			var px = get_pixel_coord(tile_corner, w.position) - Vector2(2, 1)
			var c = Color(1 - .2 * w.status, 1 - .2 * w.status, 1 - .2 * w.status)
			draw_rect(Rect2(px, Vector2(4, 1)), c)
	if Game.player != null:
		player_pixel = get_pixel_coord(tile_corner, Game.player.position)
		draw_rect(Rect2(player_pixel, Vector2.ONE), Color.white)
		
func get_pixel_coord(tile_corner, world_coord):
	return Vector2(int(floor(world_coord.x / Game.TILE_SIZE)), int(floor(world_coord.y / Game.TILE_SIZE))) - tile_corner
