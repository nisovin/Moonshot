extends Area2D

signal impact

var velocity = Vector2.ZERO
var duration = 0

func init(pos, vel):
	position = pos + Vector2(0, -8)
	velocity = vel
	rotation = vel.angle()

func _physics_process(delta):
	position += velocity * delta
	duration += delta
	if duration > 5:
		queue_free()

func _on_Fireball_area_entered(area):
	print(area)
	if area.owner.is_in_group("players"):
		emit_signal("impact", area.owner)
	queue_free()

func _on_Fireball_body_entered(body):
	print(body)
	if body.is_in_group("players") or body.is_in_group("walls"):
		emit_signal("impact", body)
	queue_free()
