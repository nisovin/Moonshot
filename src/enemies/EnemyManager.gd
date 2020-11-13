extends Node

const MAX_ENEMIES = 100
const MAX_ENEMY_POWER_PER_PLAYER = 15

enum Directive { NONE, FOCUS_PLAYERS, FOCUS_KEEP, SWIFTNESS, ENRAGE }

onready var enemy_spawn_point = owner.get_node("EnemySpawn")

var wave_size = 3
var next_enemy_id = 1

var next_ai = 0
var last_loop_time = 0

func _ready():
	set_physics_process(false)

func start_server():
	$SpawnTimer.wait_time = 10
	$SpawnTimer.start()
	set_physics_process(true)

func speed_up_spawning():
	var s = max($SpawnTimer.wait_time * 0.75, 1)
	wave_size += 3
	$SpawnTimer.wait_time = s
	$SpawnTimer.start(s)
	
func pause_spawning(time):
	$SpawnTimer.paused = true
	yield(get_tree().create_timer(time), "timeout")
	$SpawnTimer.paused = false

remotesync func spawn_enemy(data):
	var enemy = Game.Enemy.instance()
	enemy.name = str(data.id)
	enemy.position = data.position
	owner.enemies_node.add_child(enemy)
	enemy.load_data(data)

func _physics_process(delta):
	if next_ai == 0:
		if not check_start_loop(): return
		# recount player targeted counts
		for p in owner.players_node.get_children():
			p.targeted_by_count = 0
		for w in owner.walls_node.get_children():
			w.targeted_by_count = 0
		for e in owner.enemies_node.get_children():
			if e.controller.target != null && "targeted_by_count" in e.controller.target:
				e.controller.target.targeted_by_count += 1
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
	var max_enemy_power = get_tree().get_nodes_in_group("players").size() * MAX_ENEMY_POWER_PER_PLAYER
	var count = 0
	var power = 0
	for e in owner.enemies_node.get_children():
		if not e.dead:
			count += 1
			power += e.controller.type.power
	for x in wave_size:
		if count < MAX_ENEMIES and power < max_enemy_power:
			var type_id = Game.EnemyClass.SWARMER
			var pct = float(count) / MAX_ENEMIES
			if pct > 0.9 and power < max_enemy_power - 10:
				pass # high enemy count, make bigger enemies more likely
			type_id = Game.EnemyClass.MAGE if N.rng.randf() < 0.2 else Game.EnemyClass.SWARMER
			rpc("spawn_enemy", {"id": next_enemy_id, "type_id": type_id, "position": enemy_spawn_point.position + Vector2(N.rand_float(0, 16), N.rand_float(0, 16))})
			next_enemy_id += 1
			count += 1
			power += 1
