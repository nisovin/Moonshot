extends EnemyType

const PROJECTILE_SPEED = 150

var player_damage = 15

func init_sub(node):
	max_health = 150
	movement_speed = 30
	height = 45
	avoid_players = true

	target_range = 40
	target_lost_range = 500
	target_players_weight = 0
	target_keep_weight = 10
	target_shrine_weight = 1

	attack_melee = 0
	attack_damage = 100
	attack_range = 12 * Game.TILE_SIZE
	attack_range_min = 10 * Game.TILE_SIZE
	attack_range_max = 15 * Game.TILE_SIZE
	attack_cooldown = 5000
	
	Audio.play("siege_spawn", Audio.MAP)

func attack(entity, melee):
	var vel = global_position.direction_to(entity.position) * PROJECTILE_SPEED
	rpc("launch_boulder", global_position, vel, entity.position)

remotesync func launch_boulder(pos, vel, target_pos):
	var boulder = R.Boulder.instance()
	Game.level.projectiles_node.add_child(boulder)
	boulder.init(pos, vel, target_pos)
	if is_network_master():
		boulder.connect("impact", self, "_on_impact")
	Audio.play_at_position(pos, "siege_throw", Audio.ENEMIES, 0.3)
	
func _on_impact(targets):
	for t in targets:
		if t.is_in_group("walls") or t.is_in_group("shrines"):
			t.apply_damage(modify_damage(attack_damage, t))
		elif t.is_in_group("players"):
			t.apply_damage(modify_damage(player_damage, t))
