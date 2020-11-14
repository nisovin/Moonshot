extends Node

const MAX_ENEMY_POWER_PER_PLAYER = 15

const ENEMY_POWER = {
	Game.EnemyClass.GRUNT: 1,
	Game.EnemyClass.MAGE: 2
}

enum Directive { NONE, FOCUS_PLAYERS, FOCUS_KEEP, SWIFTNESS, ENRAGE }

onready var enemy_spawn_point = owner.get_node("EnemySpawn")

var max_enemies = 90
var per_player_power_limit = 1
var per_player_wave_size = 0.5
var next_enemy_id = 1

var frames_since_physics = 0
var next_ai = 0
var ai_tick_count = 0
var next_physics = 0
var physics_tick_count = 0
var last_loop_time = 0
var wall_list

func _ready():
	set_physics_process(false)

func start_server():
	$SpawnTimer.wait_time = 10
	$SpawnTimer.start()
	set_physics_process(true)
	wall_list = owner.walls_node.get_children()

func speed_up_spawning():
	var s = max($SpawnTimer.wait_time * 0.75, 1)
	per_player_wave_size = clamp(per_player_wave_size + 0.2, 0.5, 2.5)
	per_player_power_limit = clamp(per_player_power_limit + 1, 1, 6)
	$SpawnTimer.wait_time = s
	$SpawnTimer.start(s)
	
func pause_spawning(time):
	$SpawnTimer.paused = true
	yield(get_tree().create_timer(time), "timeout")
	$SpawnTimer.paused = false

remotesync func spawn_enemy(data):
	var enemy = R.Enemy.instance()
	enemy.name = str(data.id)
	enemy.position = data.position
	owner.enemies_node.add_child(enemy)
	enemy.load_data(data)

#func _process(delta):
#	frames_since_physics += 1

func _process(delta): # TEST ME
#	if frames_since_physics == 0:
#		print("WARNING: no process frames since last physics!")
#		return
#	frames_since_physics = 0
	# get players
	var player_list = owner.players_node.get_children()
	var player_count = player_list.size()
	var enemy_count = owner.enemies_node.get_child_count()
	
	# do physics ticks
#	if enemy_count > 0:
#		physics_tick_count += 1
#		var tick = Engine.get_physics_frames()
#		var start = OS.get_ticks_msec()
#		var done = 0
#		while done < enemy_count and OS.get_ticks_msec() < start + 5:
#			if next_physics >= enemy_count:
#				next_physics = 0
#				physics_tick_count = 0
#				print("NOTICE: Finished physics loop, ticks=", physics_tick_count, " enemies=", enemy_count)
#				return
#			var e = owner.enemies_node.get_child(next_physics)
#			e.physics_tick(delta * (tick - e.last_physics_tick))
#			next_physics += 1
#			done += 1
#		if done == enemy_count:
#			next_physics = 0
#			physics_tick_count = 0

	# stop enemies if no players
	if player_count == 0:
		for e in owner.enemies_node.get_children():
			e.set_movement(Vector2.ZERO, e.position)
		
	# targeted by recounts
	if next_ai == 0:
		if not check_start_loop(): return
		for p in owner.players_node.get_children():
			p.targeted_by_count = 0
		for w in owner.walls_node.get_children():
			w.targeted_by_count = 0
		for e in owner.enemies_node.get_children():
			if e.controller.target != null && "targeted_by_count" in e.controller.target:
				e.controller.target.targeted_by_count += 1
				
	# do ai ticks
	if enemy_count > 0:
		ai_tick_count += 1
		var start = OS.get_ticks_msec()
		var done = 0
		while done < enemy_count and OS.get_ticks_msec() < start + 10:
			if next_ai >= enemy_count:
				print("NOTICE: Finished ai loop, ticks=", ai_tick_count, " enemies=", enemy_count)
				next_ai = 0
				ai_tick_count = 0
				if not check_start_loop(): return
			owner.enemies_node.get_child(next_ai).controller.ai_tick(player_list, wall_list)
			next_ai += 1
			done += 1
		if next_ai == enemy_count:
			next_ai = 0
			ai_tick_count = 0
		#else:
		#	print("MAXED OUT AI TICK at=", next_ai, "/" , enemy_count , ", time=", OS.get_ticks_msec() - start)


func check_start_loop():
	if last_loop_time > OS.get_ticks_msec() - 250:
		return false
	else:
		last_loop_time = OS.get_ticks_msec()
		return true


func _on_SpawnTimer_timeout():
	var player_count = get_tree().get_nodes_in_group("players").size()
	if player_count == 0: return
	var max_enemy_power = clamp(player_count * per_player_power_limit, 5, 200)
	var wave_size = clamp(int(ceil(per_player_wave_size * player_count)), 3, 20)
	var count = 0
	var power = 0
	for e in owner.enemies_node.get_children():
		if not e.dead:
			count += 1
			power += ENEMY_POWER[e.type_id]
	for x in wave_size:
		if count < max_enemies and power < max_enemy_power:
			var type_id = Game.EnemyClass.GRUNT
			var pct = float(count) / MAX_ENEMIES
			if pct > 0.9 and power < max_enemy_power - 10:
				pass # high enemy count, make bigger enemies more likely
			type_id = Game.EnemyClass.MAGE if N.rng.randf() < 0.1 else Game.EnemyClass.GRUNT
			rpc("spawn_enemy", {"id": next_enemy_id, "type_id": type_id, "position": enemy_spawn_point.position + Vector2(N.rand_float(0, 16), N.rand_float(0, 16))})
			next_enemy_id += 1
			count += 1
			power += ENEMY_POWER[type_id]
