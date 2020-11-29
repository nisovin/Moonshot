extends Node2D
class_name EnemyType

var max_health = 50
var movement_speed = 30
var height = 30
var avoid_players = false
var custom_targeting = false
var custom_pathing = false
var immune_to_knockback = false
var immune_to_stun = false
var minimap_color = Color.red
var minimap_big = false
var death_sound = null

var target_range = 20 # tiles
var target_range_sq
var target_lost_range = 40 # tiles
var target_lost_range_sq
var target_locked_range = 0 # tiles
var target_locked_range_sq
var target_reconsider_time = 3000 # ms
var target_players_weight = 100
var target_keep_weight = 10
var target_shrine_weight = 10

var attack_melee = 5 # walk collision damage
var attack_damage = 5 # actual attack damage
var attack_range = 8 # pixels
var attack_range_min = 0 # pixels
var attack_range_max = 0 # pixels
var attack_cooldown = 1000

func init(node):
	init_sub(node)
	target_range *= Game.TILE_SIZE
	target_lost_range *= Game.TILE_SIZE
	target_locked_range *= Game.TILE_SIZE
	target_range_sq = target_range * target_range
	target_lost_range_sq = target_lost_range * target_lost_range
	target_locked_range_sq = target_locked_range * target_locked_range
	copy_up(node)
	
func init_sub(node):
	pass
	
func copy_up(node):
	node.sprite.frames = $AnimatedSprite.frames
	node.sprite.position = $AnimatedSprite.position
	node.sprite.scale = $AnimatedSprite.scale
	if node.sprite.frames.has_animation("idle_down"):
		node.sprite.play("idle_down")
	elif node.sprite.frames.has_animation("walk_down"):
		node.sprite.play("walk_down")
	else:
		node.sprite.play("default")
	node.hitbox_collision.shape = $Hitbox.shape
	node.hitbox_collision.position = $Hitbox.position
	var col = $Collision
	if col:
		node.collision.shape = $Collision.shape
		node.collision.position = $Collision.position
	else:
		node.collision.disabled = true
	$AnimatedSprite.queue_free()
	$Collision.queue_free()
	$Hitbox.queue_free()

func find_target(players, walls):
	pass
	
func get_velocity():
	pass

func calculate_target_priority(target, distance_sq):
	if distance_sq > target_range_sq:
		return 0
	var pct_dist = 1 - (distance_sq / float(target_range_sq))
	if target.is_in_group("players"):
		return pct_dist * target_players_weight
	elif target.is_in_group("walls"):
		return pct_dist * target_keep_weight * (1.5 if target.status == 1 else 1.0)
	elif target.is_in_group("shrines"):
		return pct_dist * target_shrine_weight
	else:
		return 0

func attack(entity, melee):
	#print("attack ", name, self, entity, melee)
	return entity.apply_damage(modify_damage(attack_melee, entity) if melee else modify_damage(attack_damage, entity))

func modify_damage(dam, target):
	if Game.level.is_effect_active(Game.Effects.MIDDAY):
		dam *= 1.5
	if Game.level.is_effect_active(Game.Effects.RAGE):
		dam *= 2.0
	return dam
