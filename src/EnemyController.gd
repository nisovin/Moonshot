extends Node

onready var enemy_spawn_point = owner.get_node("EnemySpawn")
onready var enemies_node = owner.get_node("Entities/Enemies")

var nav

var next_enemy_id = 1

var next_ai = 0

func start_server(nav):
	self.nav = nav
#	while true:
#		yield(get_tree().create_timer(2), "timeout")
#		if enemies_node.get_child_count() < 10:
#			rpc("spawn_enemy", {"id": next_enemy_id, "position": enemy_spawn_point.position})
#			next_enemy_id += 1

remotesync func spawn_enemy(data):
	var enemy = Game.Enemy.instance()
	enemy.name = str(data.id)
	enemy.position = data.position
	enemies_node.add_child(enemy)
	enemy.load_data(data)

func _physics_process(delta):
	var c = enemies_node.get_child_count()
	if c > 0:
		var start = OS.get_ticks_msec()
		var done = 0
		while done < c and OS.get_ticks_msec() < start + 15:
			if next_ai >= c:
				next_ai = 0
			enemies_node.get_child(next_ai).ai_tick()
			next_ai += 1
			done += 1
		if OS.get_ticks_msec() > start + 15:
			print("MAXED OUT AI TICK")
