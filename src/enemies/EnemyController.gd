extends Node

const TARGET_RANGE = 50 * 16
const REAQUIRE_RANGE = 10 * 16
const REAQUIRE_TIME = 5000 #milliseconds
const SPEED = 25

var target
var target_time = 0
var health = 70
var knockback_direction = 0
var knockback_duration = 0
var stun_duration = 0
var stun_can_break = true
var dead = false

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
		health -= data.damage
		if health <= 0:
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
				
	if target != null:
		var target_direction = owner.position.direction_to(target.position)
		var separation_direction = Vector2.ZERO
		var neighbors = owner.neighbors.get_overlapping_bodies()
		if neighbors.size() > 1:
			for enemy in neighbors:
				if enemy != self:
					var dist = enemy.position.distance_squared_to(owner.position)
					var mult = 1 - (dist / (50 * 50))
					separation_direction += enemy.position.direction_to(owner.position) * mult
			separation_direction /= neighbors.size()

		var direction = target_direction + separation_direction * 1.5
		var v = direction.normalized() * SPEED
		if not v.is_equal_approx(owner.velocity):
			owner.rpc("set_movement", v, owner.position)
	elif owner.velocity != Vector2.ZERO:
		owner.rpc("set_movement", Vector2.ZERO, owner.position)
			
func remove_target(t):
	if target == t:
		target.disconnect("became_untargetable", self, "remove_target")
		target = null
