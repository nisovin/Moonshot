extends Node

const MAX_ENEMY_POWER_PER_PLAYER = 15

const ENEMY_POWER = {
	Game.EnemyClass.GRUNT: 1,
	Game.EnemyClass.MAGE: 2,
	Game.EnemyClass.ELITE: 3,
	Game.EnemyClass.PHOENIX: 5,
	Game.EnemyClass.BOMBER: 5,
	Game.EnemyClass.SIEGE: 5
}

enum Directive { NONE, FOCUS_PLAYERS, FOCUS_KEEP, SWIFTNESS, ENRAGE }

var max_enemies = 80
var per_player_power_limit = 2
var per_player_wave_size = 0.5
var next_enemy_id = 1

var frames_since_physics = 0
var next_ai = 0
var ai_tick_count = 0
var next_physics = 0
var physics_tick_count = 0
var last_loop_time = 0
var wall_list = []
var wall_down_percents = {}
var sped_up = 0
var last_tick = 0

func _ready():
	set_process(false)
	set_physics_process(false)

func start_server():
	$SpawnTimer.wait_time = 5
	$SpawnTimer.start()
	set_process(true)
	set_physics_process(true)
	wall_list = owner.walls_node.get_children()
	for w in wall_list:
		if not w.section in wall_down_percents:
			wall_down_percents[w.section] = [0,0]
		wall_down_percents[w.section][1] += 1

func speed_up_spawning():
	sped_up += 1
	var s = max($SpawnTimer.wait_time * 0.75, 1)
	per_player_wave_size = clamp(per_player_wave_size + 0.2, 0.5, 2.5)
	per_player_power_limit = clamp(per_player_power_limit + 1, 1, MAX_ENEMY_POWER_PER_PLAYER)
	$SpawnTimer.wait_time = s
	$SpawnTimer.start(s)
	return sped_up
	
func pause_spawning():
	$SpawnTimer.stop()

func unpause_spawning():
	_on_SpawnTimer_timeout()
	$SpawnTimer.start()

func spawn(data):
	rpc("spawn_enemy", data)

remotesync func spawn_enemy(data):
	var enemy = R.Enemy.instance()
	enemy.name = str(data.id)
	enemy.position = data.position
	owner.enemies_node.add_child(enemy)
	enemy.load_data(data)

#func _process(delta):
#	frames_since_physics += 1

func _process(delta): # TEST ME
	
	# check lag
	var tick_time = OS.get_ticks_msec() - last_tick
	if tick_time > (1000.0/15.0):
		print("lag?", tick_time)
	last_tick = OS.get_ticks_msec()
	
	# TODO: auto-kill enemies when it gets laggy
	
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
		
	# recounts
	if next_ai == 0:
		if not check_start_loop(): return
		for p in player_list:
			p.targeted_by_count = 0
		for w in wall_down_percents:
			wall_down_percents[w][0] = 0
		for w in wall_list:
			w.targeted_by_count = 0
			if w.status == 0:
				wall_down_percents[w.section][0] += 1.0 / wall_down_percents[w.section][1]
		for e in owner.enemies_node.get_children():
			if e.controller.target != null && "targeted_by_count" in e.controller.target:
				e.controller.target.targeted_by_count += 1
	
	var target_wall_list = []
	for w in wall_list:
		if wall_down_percents[w.section][0] < 0.5:
			target_wall_list.append(w)
		
	
	# check cost to shrine
	#var path_to_shrine = owner.get_nav_path(owner.firewall.position, owner.current_shrine.position, false, true)
	#print(path_to_shrine[1])
	#print(wall_down_percents)
	# TODO: use wall status to remove some wall targets
	
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
			owner.enemies_node.get_child(next_ai).controller.ai_tick(player_list, target_wall_list)
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

func spawn_special_wave(type_id, count, spread = true):
	var spawn_points = owner.get_enemy_spawn_points()
	if spawn_points == null or spawn_points.size() == 0: return
	var spawn_point = N.rand_array(spawn_points)
	for i in count:
		var loc = spawn_point.global_position + Vector2(N.rand_float(0, 16), N.rand_float(0, 16))
		spawn({"id": next_enemy_id, "type_id": type_id, "position": loc})
		next_enemy_id += 1
		if spread:
			spawn_point = N.rand_array(spawn_points)
		

func _on_SpawnTimer_timeout():
	var player_count = get_tree().get_nodes_in_group("players").size()
	if player_count == 0: return
	
	# get spawn points
	var spawn_points = owner.get_enemy_spawn_points()
	if spawn_points == null or spawn_points.size() == 0: return
	var spawn_point = null
	
	# get current enemy counts and power
	var max_enemy_power = 4 + clamp(player_count * per_player_power_limit, 1, 200)
	var count = 0
	var power = 0
	for e in owner.enemies_node.get_children():
		if not e.dead:
			count += 1
			power += ENEMY_POWER[e.type_id]
			
	# spawn enemies
	var wave_size = 3 + clamp(int(ceil(per_player_wave_size * player_count)), 0, 20)
	for x in wave_size:
		if count < max_enemies and power < max_enemy_power:
			if spawn_point == null or x % 4 == 0:
				spawn_point = N.rand_array(spawn_points)
			var loc = spawn_point.global_position + Vector2(N.rand_float(0, 16), N.rand_float(0, 16))
			var need_bigger_enemies = float(count) / max_enemies > 0.5 and power < max_enemy_power - 10
			var options = {}
			options[Game.EnemyClass.GRUNT] = 100 if not need_bigger_enemies else 50
			options[Game.EnemyClass.MAGE] = 15
			if sped_up > 1:
				options[Game.EnemyClass.ELITE] = 20 if not need_bigger_enemies else 50
				options[Game.EnemyClass.PHOENIX] = 4 if not need_bigger_enemies else 10
				options[Game.EnemyClass.SIEGE] = 4 if not need_bigger_enemies else 20
			if sped_up > 5:
				options[Game.EnemyClass.BOMBER] = 4
				options[Game.EnemyClass.SIEGE] = 10 if not need_bigger_enemies else 30
			#options = {Game.EnemyClass.BOMBER: 1, Game.EnemyClass.SIEGE: 1}
			var type_id = N.rand_weighted(options)
			spawn({"id": next_enemy_id, "type_id": type_id, "position": loc})
			next_enemy_id += 1
			count += 1
			power += ENEMY_POWER[type_id]
			if ENEMY_POWER[type_id] >= 5:
				spawn_point = null
