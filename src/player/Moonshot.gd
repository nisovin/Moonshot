extends Area2D

signal hit

var velocity = Vector2.ZERO
var duration = 0

func init(pos, vel):
	global_position = pos + vel * 0.5
	velocity = vel
	rotation = vel.angle()
	if not Game.is_server():
		$Tween.interpolate_property($Sprite, "scale", Vector2(0.5, 0.5), Vector2.ONE, 0.5)
		$Tween.start()
		$AudioStreamPlayer.volume_db = linear2db(0)
		$AudioStreamPlayer.play()

func _physics_process(delta):
	position += velocity * delta
	duration += delta
	if duration > 20:
		queue_free()
	if not Game.is_server() and Game.player != null:
		var dist = Game.player.position.distance_to(position)
		if dist < 800:
			$AudioStreamPlayer.volume_db = linear2db(1 - (dist / 800))
		else:
			$AudioStreamPlayer.volume_db = linear2db(0)

func _on_Moonshot_area_entered(area):
	if area.owner.is_in_group("enemies"):
		emit_signal("hit", area.owner, velocity)
