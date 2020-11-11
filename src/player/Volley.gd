extends Area2D

func init(pos, radius):
	var tween = $Tween
	var circle = $Circle
	position = pos
	circle.radius = radius
	$CollisionShape2D.shape.radius = radius
	$Particles2D.process_material.emission_sphere_radius = radius - 2
	$Particles2D.emitting = true
	tween.interpolate_property(circle, "scale", Vector2(.1, .1), Vector2(1, 1), 0.2)
	tween.interpolate_property(circle, "modulate", Color.transparent, Color.white, 0.2)
	tween.start()
	yield(get_tree().create_timer(0.7), "timeout")
	tween.interpolate_property(circle, "scale", Vector2(1, 1), Vector2(.1, .1), 0.2)
	tween.interpolate_property(circle, "modulate", Color.white, Color.transparent, 0.2)
	tween.start()
	yield(get_tree().create_timer(0.2), "timeout")
	queue_free()
