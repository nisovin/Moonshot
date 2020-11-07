extends KinematicBody2D

var target = null

var direction = Vector2.ZERO

var knockback_strength = Vector2.ZERO
var knockback_duration = 0
var knockback_stun_duration = 0

func _ready():
	pass

func load_data(data):
	pass

func knockback(strength, dur, stun):
	knockback_strength = strength
	knockback_duration = dur
	knockback_stun_duration = stun

func _physics_process(delta):
	if knockback_duration > 0:
		knockback_duration -= delta
		move_and_collide(knockback_strength * delta)
		return
	elif knockback_stun_duration > 0:
		knockback_stun_duration -= delta
		return
	ai_tick()
	if target != null:
		var target_direction = position.direction_to(target.position)
		var separation_direction = Vector2.ZERO
		var alignment_direction = Vector2.ZERO
		var enemies = $Neighbors.get_overlapping_bodies()
		if enemies.size() > 1:
			for enemy in enemies:
				if enemy != self:
					#if enemy.target == target:
					#	alignment_direction += enemy.direction
					separation_direction += enemy.position.direction_to(position)
			separation_direction /= enemies.size()
			#alignment_direction /= enemies.size()
		
		direction = target_direction + separation_direction * 0.7 + alignment_direction * 0.5
		direction = direction.normalized()
		
		move_and_slide(direction * 30)
	
func ai_tick():
	if target == null:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			target = players[0]
	
