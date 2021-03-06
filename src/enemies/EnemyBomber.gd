extends EnemyType

const BLAST_TIME = 1.5
const MAX_MELEE_ATTACKS = 5

var enemy_node
var exploded = false

var attack_damage_to_walls = 750
var attack_damage_to_shrines = 300

var melee_attacks = 0

func init_sub(node):
	enemy_node = node
	
	minimap_color = Color.magenta
	minimap_big = true
	
	max_health = 500
	movement_speed = 20
	height = 50
	avoid_players = false
	immune_to_knockback = true
	immune_to_stun = true

	target_range = 160
	target_lost_range = 60
	target_players_weight = 0
	target_keep_weight = 100
	target_shrine_weight = 1

	attack_melee = 30
	attack_damage = 100
	attack_range = 32
	attack_range_min = 0
	attack_range_max = 32
	attack_cooldown = 1000

	Audio.play("bomber_spawn", Audio.MAP)

func attack(entity, melee):
	if exploded: return
	if melee and entity.is_in_group("players"):
		entity.apply_damage(attack_melee)
		melee_attacks += 1
		if melee_attacks < MAX_MELEE_ATTACKS:
			return
	exploded = true
	enemy_node.controller.stun_can_break = false
	enemy_node.controller.stun_duration = 500
	rpc("show_blast")
	yield(get_tree().create_timer(BLAST_TIME), "timeout")
	if enemy_node.dead: return
	var targets = N.get_overlapping_bodies_and_areas($TargetBox)
	for target in targets:
		if target.is_in_group("walls"):
			target.apply_damage(attack_damage_to_walls)
		elif target.is_in_group("shrines"):
			target.apply_damage(attack_damage_to_shrines)
		elif target.is_in_group("players"):
			target.apply_damage(modify_damage(attack_damage, target))
	enemy_node.rpc("die")

remotesync func show_blast():
	enemy_node.set_movement(Vector2.ZERO, enemy_node.position, 10)
	$BlastRadius.color.a = 0.25
	$BlastRadius.update()
	$Tween.interpolate_property(enemy_node.visual, "modulate", Color.white, Color.red, BLAST_TIME)
	$Tween.start()
	Audio.play_at_position(enemy_node.position, "bomber_ignite", Audio.ENEMIES)
	yield(get_tree().create_timer(BLAST_TIME), "timeout")
	if enemy_node.dead: return
	Audio.play("bomber_explode", Audio.ENEMIES)
	$BlastRadius.hide()
	$ExplodeParticles.emitting = true
