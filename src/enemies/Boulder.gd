extends Node2D

signal impact

var velocity = Vector2.ZERO
var vel_len
var target_position
var max_height
var distance_total = 0.0
var distance_traveled = 0.0

func init(pos, vel, target_pos):
	position = pos + Vector2(0, -8)
	velocity = vel
	vel_len = vel.length()
	target_position = target_pos
	distance_total = position.distance_to(target_position)
	max_height = distance_total / 3

func _physics_process(delta):
	position += velocity * delta
	distance_traveled += vel_len * delta
	$AnimatedSprite.position.y = sin(distance_traveled / distance_total * PI) * -max_height
	if distance_total - distance_traveled < 5:
		var bodies = N.get_overlapping_bodies($Area2D)
		var areas = N.get_overlapping_hitboxes($Area2D, "shrines")
		for a in areas:
			bodies.append(a)
		emit_signal("impact", bodies)
		Audio.play_at_position(position, "siege_impact", Audio.ENEMIES)
		queue_free()
