extends Node

const MAX_ENEMIES_ON_PLAYER = 6
const MAX_ENEMIES_ON_WALL = 6

var type
var target
var target_position
var target_direction
var target_time = 0
var target_last_tile_pos = Vector2.ZERO
var path_to_target = []
var next_path_point = Vector2.ZERO

var next_attack = 0

var knockback_direction = 0
var knockback_duration = 0
var stun_duration = 0
var stun_can_break = true
var dead = false

onready var space_state: Physics2DDirectSpaceState = get_parent().get_world_2d().direct_space_state

func init(type_id):
	match type_id:
		Game.EnemyClass.GRUNT:
			type = R.EnemyGrunt.instance()
		Game.EnemyClass.MAGE:
			type = R.EnemyMage.instance()
		Game.EnemyClass.ELITE:
			type = R.EnemyElite.instance()
		Game.EnemyClass.PHOENIX:
			type = R.EnemyPhoenix.instance()
		Game.EnemyClass.BOMBER:
			type = R.EnemyBomber.instance()
		Game.EnemyClass.SIEGE:
			type = R.EnemySiege.instance()
		_:
			assert(false)
			owner.queue_free()
			return
	#type.name = "EnemyClass"
	owner.add_child(type)
	type.init(owner)

func collide(collision):
	if not dead and type.attack_melee > 0 and next_attack < OS.get_ticks_msec() and stun_duration <= 0 and knockback_duration <= 0:
		var body = collision.collider
		if body.is_in_group("players") or body.is_in_group("walls"):
			attack(body, true)

func hit(data):
	if dead: return false
	var set_stun = false
	if "knockback" in data and not type.immune_to_knockback:
		knockback_direction = data.knockback
		knockback_duration = data.knockback_dur
		if stun_duration < knockback_duration:
			stun_duration = knockback_duration
	if "stun" in data and stun_duration < data.stun and data.stun > 0 and not type.immune_to_stun:
		stun_duration = data.stun * type.stun_time_multiplier
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
		var dam = data.damage
		if Game.level.is_effect_active(Game.Effects.RAGE):
			dam *= 1.25
		if owner.position.y < Game.level.firewall.position.y:
			dam *= 0.25
		owner.health -= dam
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

func ai_tick(players, walls):
	if dead or stun_duration > 0 or knockback_duration > 0: return
	
	var attacked = try_to_attack()
	if attacked: return
	
	if type.custom_targeting:
		type.find_target(players, walls)
	else:
		find_target(players, walls)
	
	if target != null:
		var v = Vector2.ZERO
		if type.custom_pathing:
			v = type.get_velocity()
		else:
			calculate_path_to_target()
			v = calculate_desired_velocity()
		if not v.is_equal_approx(owner.velocity):
			owner.rpc("set_movement", v, owner.position)
	elif owner.velocity != Vector2.ZERO:
		owner.rpc("set_movement", Vector2.ZERO, owner.position)
		
func try_to_attack():
	if target != null and next_attack < OS.get_ticks_msec():
		var pos = target.position
		if "target_position" in target: pos = target.target_position
		var dist_sq = owner.position.distance_squared_to(pos)
		if dist_sq > type.attack_range_min * type.attack_range_min and dist_sq < type.attack_range_max * type.attack_range_max:
			return attack(target, false)
	return false
	
func attack(entity, melee):
	next_attack = OS.get_ticks_msec() + type.attack_cooldown
	return type.attack(entity, melee)
		
func find_target(players, walls):
	var reconsider = false
	if target != null:
		if target.is_in_group("shrines"):
			if target.health <= 0:
				remove_target(target)
			elif OS.get_ticks_msec() > target_time + type.target_reconsider_time:
				reconsider = true
		elif target.is_in_group("walls"):
			if target.status == 0:
				remove_target(target)
			elif OS.get_ticks_msec() > target_time + type.target_reconsider_time:
				reconsider = true
		else:
			var d = target.position.distance_squared_to(owner.position)
			if d > type.target_lost_range_sq:
				remove_target(target)
			elif OS.get_ticks_msec() > target_time + type.target_reconsider_time and d > type.target_locked_range_sq:
				reconsider = true
	if target == null or reconsider:
		var best_target = target
		var best_priority = 0 if target == null else type.calculate_target_priority(target, target.position.distance_squared_to(owner.position)) * 1.5
		for p in players:
			if p.dead or not p.targetable or p == target or p.targeted_by_count >= MAX_ENEMIES_ON_PLAYER: continue
			var d = p.position.distance_squared_to(owner.position)
			var prio = type.calculate_target_priority(p, d)
			if Game.level.is_effect_active(Game.Effects.FOCUS_KEEP):
				prio *= 0.1
			if prio > best_priority:
				best_priority = prio
				best_target = p
		for w in walls:
			if w.status == 0 or w == target or w.targeted_by_count >= MAX_ENEMIES_ON_WALL: continue
			var d = w.target_position.distance_squared_to(owner.position)
			var prio = type.calculate_target_priority(w, d)
			if prio > best_priority:
				best_priority = prio
				best_target = w
		var s = Game.level.current_shrine
		if s != null:
			var d = s.position.distance_squared_to(owner.position)
			var prio = type.calculate_target_priority(s, d)
			if prio > best_priority:
				best_priority = prio
				best_target = s
		if target == null and best_target == null and s != null:
			best_target = s
		if best_target != null:
			target_time = OS.get_ticks_msec()
			if target != best_target:
				#print("Targeting ", best_target.name, " previous=", "x" if target == null else target.name, " who=", owner.name, "/", owner.type_id)
				if target != null:
					remove_target(target)
				target = best_target
				target.connect("became_untargetable", self, "remove_target")
				target.targeted_by_count += 1

func calculate_path_to_target():
	# get target and distance
	target_position = target.position
	if "target_position" in target:
		target_position = target.target_position
	var dist_to_target = owner.position.distance_to(target_position)
	target_direction = (target_position - owner.position) / dist_to_target
	
	# adjust for attack range TODO: is this wrong? mages act weird
	if dist_to_target > type.attack_range_max:
		target_position -= target_direction * type.attack_range
		dist_to_target -= type.attack_range
	elif dist_to_target < type.attack_range_min:
		target_position -= target_direction * type.attack_range
		dist_to_target = type.attack_range - dist_to_target
		target_direction *= -1
	else: # within range
		target_position = owner.position
		target_direction = Vector2.ZERO
		path_to_target = []
		return
		
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
			#assert(false)
			next_point = target_position
		else:
			next_point = path_to_target[0]
			if owner.position.distance_squared_to(next_point) < 10 * 10:
				path_to_target.pop_front()
				if path_to_target.size() == 0:
					next_point = target_position
				else:
					next_point = path_to_target[0]
		#owner.get_node("Line2D").points = path_to_target
		#owner.get_node("Line2D").set_as_toplevel(true)
	target_direction = owner.position.direction_to(next_point)

func calculate_desired_velocity():
	var separation_direction = Vector2.ZERO
	var avoid_direction = Vector2.ZERO
	var neighbors = N.get_overlapping_bodies(owner.neighbors, "", Game.Layer.ENEMIES + (Game.Layer.PLAYERS if type.avoid_players else 0))
	if neighbors.size() > 1:
		var neighbor
		var dir
		var e_count = 0
		var p_count = 0
		for i in neighbors.size():
			if i > 15: break
			neighbor = neighbors[i]
			if neighbor != owner:
				var dist = neighbor.position.distance_to(owner.position)
				if dist == 0:
					dir = Vector2.DOWN
				elif dist < 8:
					dir = (owner.position - neighbor.position) / dist * 15
				elif dist < 16:
					dir = (owner.position - neighbor.position) / dist * 5
				else:
					var mult = 1 - (dist / 50)
					dir = (owner.position - neighbor.position) / dist * mult
				if neighbor.is_in_group("enemies"):
					separation_direction += dir
					e_count += 1
				elif type.avoid_players and neighbor.is_in_group("players"):
					avoid_direction += dir
					p_count += 1
		
		if e_count > 0:
			separation_direction /= e_count
		if p_count > 0:
			avoid_direction /= p_count

	var direction = target_direction + separation_direction + avoid_direction * 2
	return direction.normalized() * type.movement_speed
		
func remove_target(t):
	if target == t:
		target.disconnect("became_untargetable", self, "remove_target")
		target = null
