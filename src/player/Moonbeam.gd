extends Area2D

signal tick

func init(pos, radius, interval, duration):
	var tween = $Tween
	var circle = $Circle
	position = pos
	$CollisionShape2D.shape.radius = radius
	$Particles2D.process_material.emission_sphere_radius = radius - 2
	$Particles2D.amount = PI * radius * radius / (8*8)
	if is_network_master():
		$Timer.wait_time = interval
		$Timer.start()
	if not Game.is_server():
		circle.radius = radius
		tween.interpolate_property(circle, "scale", Vector2(.1, .1), Vector2(1, 1), 0.5)
		tween.interpolate_property(circle, "modulate", Color.transparent, Color.white, 0.5)
		tween.start()
	yield(get_tree().create_timer(0.5), "timeout")
	if not Game.is_server():
		$Particles2D.emitting = true
	yield(get_tree().create_timer(duration), "timeout")
	if not Game.is_server():
		$Particles2D.emitting = false
		tween.interpolate_property(circle, "scale", Vector2(1, 1), Vector2(.1, .1), 0.5)
		tween.interpolate_property(circle, "modulate", Color.white, Color.transparent, 0.5)
		tween.start()
	yield(get_tree().create_timer(1.5), "timeout")
	queue_free()


func _on_Timer_timeout():
	var players = []
	var enemies = []
	for b in get_overlapping_bodies():
		if b.is_in_group("players"):
			players.append(b)
		elif b.is_in_group("enemies"):
			enemies.append(b)
	emit_signal("tick", players, enemies)
