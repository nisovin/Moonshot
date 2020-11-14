extends EnemyType

const FIREBALL_SPEED = 150

var enemy_node

func init_sub(node):
	enemy_node = node
	max_health = 40
	movement_speed = 50
	avoid_players = true

	target_players_weight = 100
	target_keep_weight = 1
	target_shrine_weight = 1

	attack_melee = 0
	attack_damage = 12
	attack_range = 6 * Game.TILE_SIZE
	attack_range_min = 3 * Game.TILE_SIZE
	attack_range_max = 10 * Game.TILE_SIZE
	attack_cooldown = 6000
	
	node.get_node("Visual/AnimatedSprite").modulate = Color.orange

func attack(entity, melee):
	var vel = enemy_node.position.direction_to(entity.position) * FIREBALL_SPEED
	rpc("launch_fireball", enemy_node.position, vel)

remotesync func launch_fireball(pos, vel):
	var fireball = R.Fireball.instance()
	Game.level.projectiles_node.add_child(fireball)
	fireball.init(pos, vel)
	if is_network_master():
		fireball.connect("impact", self, "_on_impact")
	
func _on_impact(entity):
	entity.apply_damage(attack_damage)
