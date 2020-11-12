extends Node

const TARGET_RANGE = 50 * 16
const REAQUIRE_RANGE = 10 * 16
const REAQUIRE_TIME = 5000 #milliseconds
const SPEED = 35

var target
#var target_position
#var target_direction
var target_time = 0
var target_last_tile_pos = Vector2.ZERO
var path_to_target = []
var knockback_direction = 0
var knockback_duration = 0
var stun_duration = 0
var stun_can_break = true
var dead = false

onready var space_state: Physics2DDirectSpaceState = get_parent().get_world_2d().direct_space_state

func collide(collision):
	pass

func hit(data):
	if dead: return false
	var set_stun = false
	if "knockback" in data:
		knockback_direction = data.knockback
		knockback_duration = data.knockback_dur
		if stun_duration < knockback_duration:
			stun_duration = knockback_duration
	if "stun" in data and stun_duration < data.stun and data.stun > 0:
		stun_duration = data.stun
		if "stun_break" in data:
			stun_can_break = data.stun_break
		else:
			stun_can_break = true
		set_stun = true
	if knockback_duration > 0:
		owner.rpc("set_movement", knockback_direction, owner.position, knockback_duration)
	elif stun_duration > 0:
		owner.rpc("set_movement", Vector2.ZERO, owner.position)
	if "damage" in data:
		owner.health -= data.damage
		if owner.health <= 0:
			dead = true
			owner.rpc("die")
			return false
		if stun_duration > 0 and stun_can_break and not set_stun:
			stun_duration = 0
	return true

func _physics_process(delta):
	if knockback_duration > 0:
		knockback_duration -= delta
		if knockback_duration <= 0:
			owner.rpc("set_movement", Vector2.ZERO, owner.position)
	if stun_duration > 0:
		stun_duration -= delta

func ai_tick():
	if dead or stun_duration > 0 or knockback_duration > 0: return
	find_target()
	
	if target != null:
		var dist_to_target = owner.position.distance_to(target.position)
		var target_position = target.position
		if "target_position" in target:
			target_position = target.target_position
		var target_direction = (target.position - owner.position) / dist_to_target
		if dist_to_target > 16:
			target_position = target.position - target_direction * 16
			dist_to_target -= 16
		if dist_to_target < 4: # already close enough
			target_position = owner.position
			target_direction = Vector2.ZERO
		else:
			# get next nav point
			var next_point = null
			if dist_to_target < 128:
				var col = space_state.intersect_ray(owner.position, target_position, [], 1)
				if not col:
					next_point = target_position
			if next_point == null:
				var target_tile_pos = Game.get_tile_pos(target_position)
				if path_to_target.size() == 0 or target_tile_pos != target_last_tile_pos:
					path_to_target = Game.level.get_nav_path(owner.position, target_position)
					target_last_tile_pos = target_tile_pos
				if path_to_target.size() == 0:
					assert(false)
					next_point = target_position
				else:
					next_point = path_to_target[0]
					if owner.position.distance_squared_to(next_point) < 10 * 10:
						path_to_target.pop_front()
						if path_to_target.size() == 0:
							next_point = target_position
						else:
							next_point = path_to_target[0]
				owner.get_node("Line2D").points = path_to_target
				owner.get_node("Line2D").set_as_toplevel(true)
			target_direction = owner.position.direction_to(next_point)
		var separation_direction = Vector2.ZERO
		var neighbors = N.get_overlapping_bodies(owner.neighbors, "enemies")
		if neighbors.size() > 1:
			var enemy
			for i in neighbors.size():
				if i > 15: break
				enemy = neighbors[i]
				if enemy != self:
					var dist = enemy.position.distance_to(owner.position)
					if dist == 0:
						separation_direction = Vector2.DOWN
					elif dist < 16:
						separation_direction += (owner.position - enemy.position) / dist * 5
					else:
						var mult = 1 - (dist / 50)
						separation_direction += (owner.position - enemy.position) / dist * mult
			separation_direction /= min(neighbors.size(), 15)

		var direction = target_direction + separation_direction
		var v = direction.normalized() * SPEED
		if not v.is_equal_approx(owner.velocity):
			owner.rpc("set_movement", v, owner.position)
		if not target.is_invulnerable() and owner.position.distance_squared_to(target.position) < 20 * 20:
			var dam = owner.calculate_damage(5, target)
			target.rpc("damage", target.health - dam)
	elif owner.velocity != Vector2.ZERO:
		owner.rpc("set_movement", Vector2.ZERO, owner.position)
		

		
func find_target():
	if target != null:
		var d = target.position.distance_squared_to(owner.position)
		if d > TARGET_RANGE * TARGET_RANGE or (OS.get_ticks_msec() > target_time + REAQUIRE_TIME and d > REAQUIRE_RANGE * REAQUIRE_RANGE):
			remove_target(target)
	if target == null:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			var closest_player = null
			var closest_dist = TARGET_RANGE * TARGET_RANGE
			for p in players:
				if not p.targetable: continue
				var d = p.position.distance_squared_to(owner.position)
				if d < closest_dist:
					closest_dist = d
					closest_player = p
			if closest_player != null:
				target = closest_player
				target.connect("became_untargetable", self, "remove_target")
				target_time = OS.get_ticks_msec()

func calculate_path_to_target():
	pass

		
func remove_target(t):
	if target == t:
		target.disconnect("became_untargetable", self, "remove_target")
		target = null
