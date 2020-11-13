extends Node
class_name EnemyType

var max_health = 50
var movement_speed = 30
var avoid_players = false

var target_range = 50 * Game.TILE_SIZE
var target_range_sq
var target_max_range = 60 * Game.TILE_SIZE
var target_max_range_sq
var target_locked_range = 0 * Game.TILE_SIZE
var target_locked_range_sq
var target_reconsider_time = 5000 # ms
var target_players_weight = 100
var target_keep_weight = 10
var target_shrine_weight = 10

var attack_melee = 5
var attack_damage = 5
var attack_range = 8
var attack_range_min = 0
var attack_range_max = 0
var attack_cooldown = 1000

func init(node):
	init_sub(node)
	target_range_sq = target_range * target_range
	target_max_range_sq = target_max_range * target_max_range
	target_locked_range_sq = target_locked_range * target_locked_range
	
func init_sub(node):
	pass

func calculate_target_priority(target, distance_sq):
	if distance_sq > target_range_sq:
		return 0
	var pct_dist = 1 - (distance_sq / float(target_range_sq))
	if target.is_in_group("players"):
		return pct_dist * target_players_weight
	elif target.is_in_group("walls"):
		return pct_dist * target_keep_weight
	elif target.is_in_group("shrines"):
		return pct_dist * target_shrine_weight
	else:
		return 0

func attack(entity, melee):
	return entity.apply_damage(attack_melee if melee else attack_damage)
