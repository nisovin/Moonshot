extends Area2D

signal hit

var velocity = Vector2.ZERO
var duration = 0
var mini = false

func init(pos, vel, m):
	global_position = pos + vel * 0.1
	velocity = vel
	rotation = vel.angle()
	mini = m
	if mini:
		$Sprite.scale = Vector2(0.5, 0.5)
		modulate = Color(1, 1, 1, 0.75)
		$CollisionShape2D.shape.radius = 4

func _physics_process(delta):
	position += velocity * delta
	duration += delta
	if duration > 2:
		queue_free()

func _on_Arrow_area_entered(area):
	if area.owner.is_in_group("enemies"):
		emit_signal("hit", area.owner, velocity, mini)
	queue_free()
	
func _on_Arrow_body_entered(body):
	queue_free()
