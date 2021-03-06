extends EnemyType

const FIREBALL_SPEED = 150

var enemy_node

func init_sub(node):
	enemy_node = node
	max_health = 50
	movement_speed = 60
	height = 35
	avoid_players = true

	target_range = 40
	target_lost_range = 60
	target_players_weight = 100
	target_keep_weight = 1
	target_shrine_weight = 5

	attack_melee = 0
	attack_damage = 12
	attack_range = 8 * Game.TILE_SIZE
	attack_range_min = 6 * Game.TILE_SIZE
	attack_range_max = 10 * Game.TILE_SIZE
	attack_cooldown = 6000
	
	death_sound = "mage_die"
	
func attack(entity, melee):
	var vel = enemy_node.position.direction_to(entity.position) * FIREBALL_SPEED
	rpc("launch_fireball", enemy_node.position, vel)

remotesync func launch_fireball(pos, vel):
	var fireball = R.Fireball.instance()
	Game.level.projectiles_node.add_child(fireball)
	fireball.init(pos, vel)
	if is_network_master():
		fireball.connect("impact", self, "_on_impact")
	Audio.play_at_position(pos, "mage_fireball", Audio.ENEMIES)
	
func _on_impact(entity):
	entity.apply_damage(modify_damage(attack_damage, entity))
