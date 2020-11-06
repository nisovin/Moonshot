extends Node

onready var enemy_spawn_point = owner.get_node("EnemySpawn")
onready var enemies_node = owner.get_node("Entities/Enemies")

var next_enemy_id = 1

func start_server():
	while true:
		yield(get_tree().create_timer(2), "timeout")
		if enemies_node.get_child_count() < 10:
			rpc("spawn_enemy", {"id": next_enemy_id, "position": enemy_spawn_point.position})
			next_enemy_id += 1

remotesync func spawn_enemy(data):
	var enemy = Game.Enemy.instance()
	enemy.name = str(data.id)
	enemy.position = data.position
	enemies_node.add_child(enemy)
	enemy.load_data(data)
