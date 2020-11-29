extends EnemyType

const FIREBALL_SPEED = 100

func init_sub(node):
	minimap_color = Color.orange
	minimap_big = true
	
	max_health = 150
	movement_speed = 30
	height = 50
	avoid_players = true

	target_range = 40
	target_lost_range = 60
	target_players_weight = 1
	target_keep_weight = 0
	target_shrine_weight = 1

	attack_melee = 0
	attack_damage = 5
	attack_range = 150
	attack_range_min = 0
	attack_range_max = 200
	attack_cooldown = 750

func attack(entity, melee):
	var players = N.get_overlapping_bodies($TargetBox)
	var vels = []
	if players.size() > 3:
		players.shuffle()
		players.resize(3)
	for player in players:
		vels.append(global_position.direction_to(player.position) * FIREBALL_SPEED)
	if vels.size() > 0:
		rpc("launch_fireballs", global_position, vels)

remotesync func launch_fireballs(pos, vels):
	for vel in vels:
		var fireball = R.Fireball.instance()
		Game.level.projectiles_node.add_child(fireball)
		fireball.init(pos, vel)
		if is_network_master():
			fireball.connect("impact", self, "_on_impact")
	Audio.play_at_position(pos, "mage_fireball", Audio.ENEMIES)

func _on_impact(entity):
	entity.apply_damage(modify_damage(attack_damage, entity))
