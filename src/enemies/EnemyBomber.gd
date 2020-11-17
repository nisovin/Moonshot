extends EnemyType

const BLAST_TIME = 1.5

var enemy_node
var exploded = false

func init_sub(node):
	enemy_node = node
	max_health = 500
	movement_speed = 15
	height = 50
	avoid_players = false
	immune_to_knockback = true
	immune_to_stun = true

	target_range = 160
	target_lost_range = 60
	target_players_weight = 0
	target_keep_weight = 100
	target_shrine_weight = 1

	attack_melee = 10
	attack_damage = 75
	attack_range = 32
	attack_range_min = 0
	attack_range_max = 32
	attack_cooldown = 1000

func attack(entity, melee):
	if exploded: return
	if melee and entity.is_in_group("players"):
		entity.apply_damage(attack_melee)
		return
	exploded = true
	enemy_node.controller.stun_can_break = false
	enemy_node.controller.stun_duration = 500
	rpc("show_blast")
	yield(get_tree().create_timer(BLAST_TIME), "timeout")
	var targets = N.get_overlapping_bodies($TargetBox)
	for target in targets:
		if target.is_in_group("walls"):
			target.apply_damage(attack_damage * 10)
		elif target.is_in_group("players"):
			target.apply_damage(attack_damage)
	enemy_node.rpc("die")

remotesync func show_blast():
	enemy_node.set_movement(Vector2.ZERO, enemy_node.position, 10)
	$BlastRadius.show()
	$Tween.interpolate_property(enemy_node.visual, "modulate", Color.white, Color.red, BLAST_TIME)
	$Tween.start()
