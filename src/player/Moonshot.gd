extends Area2D

signal hit

var velocity = Vector2.ZERO
var duration = 0

func init(pos, vel):
	global_position = pos + vel * 0.5
	velocity = vel
	rotation = vel.angle()
	$Tween.interpolate_property($Sprite, "scale", Vector2(0.5, 0.5), Vector2.ONE, 0.5)
	$Tween.start()

func _physics_process(delta):
	position += velocity * delta
	duration += delta
	if duration > 20:
		queue_free()

func _on_Moonshot_body_entered(body):
	if body.is_in_group("enemies"):
		emit_signal("hit", body, velocity)
