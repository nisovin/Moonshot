extends EnemyType

func init_sub(node):
	max_health = 80
	movement_speed = 40
	height = 30
	
	target_range = 20
	target_players_weight = 75
	target_keep_weight = 25
	target_shrine_weight = 50
	
	attack_melee = 5
	attack_damage = 5
	attack_range = 10
	attack_range_min = 0
	attack_range_max = 14

	death_sound = "grunt_die"
