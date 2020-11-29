extends EnemyType

func init_sub(node):
	minimap_color = Color.firebrick
	
	max_health = 160
	movement_speed = 50
	height = 30
	
	target_range = 20
	target_players_weight = 100
	target_keep_weight = 15
	target_shrine_weight = 25
	
	attack_melee = 15
	attack_damage = 15
	attack_range = 10
	attack_range_min = 0
	attack_range_max = 14

	death_sound = "grunt_die"
