extends Node

enum Directive { NONE, FOCUS_PLAYERS, FOCUS_KEEP, SWIFTNESS, ENRAGE }

onready var enemy_spawn_point = owner.get_node("EnemySpawn")

var next_enemy_id = 1

var next_ai = 0
var last_loop_time = 0

func _ready():
	set_physics_process(false)

func start_server():
	$SpawnTimer.wait_time = 0.1
	$SpawnTimer.start()
	set_physics_process(true)

remotesync func spawn_enemy(data):
	var enemy = Game.Enemy.instance()
	enemy.name = str(data.id)
	enemy.position = data.position
	owner.enemies_node.add_child(enemy)
	enemy.load_data(data)

func _physics_process(delta):
	if next_ai == 0:
		if not check_start_loop(): return
	var c = owner.enemies_node.get_child_count()
	if c > 0:
		var start = OS.get_ticks_msec()
		var done = 0
		while done < c and OS.get_ticks_msec() < start + 10:
			if next_ai >= c:
				next_ai = 0
				print("finished loop ", c)
				if not check_start_loop(): return
			owner.enemies_node.get_child(next_ai).ai_tick()
			next_ai += 1
			done += 1
		if next_ai == c:
			next_ai = 0
		else:
			print("MAXED OUT AI TICK ", next_ai, " ", OS.get_ticks_msec() - start)

func check_start_loop():
	if last_loop_time > OS.get_ticks_msec() - 250:
		return false
	else:
		last_loop_time = OS.get_ticks_msec()
		return true


func _on_SpawnTimer_timeout():
	var max_enemies = get_tree().get_nodes_in_group("players").size() * 50
	if owner.enemies_node.get_child_count() < max_enemies:
		rpc("spawn_enemy", {"id": next_enemy_id, "position": enemy_spawn_point.position + Vector2(N.rand_float(0, 16), N.rand_float(0, 16))})
		next_enemy_id += 1
