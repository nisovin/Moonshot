extends Node2D

enum GameState { PREGAME, STAGE1, STAGE2, GAMEOVER }

var chat_history = []

onready var gui = $GUI
onready var map = $Map
onready var player_spawn = $PlayerSpawn
onready var firewall = $Map/Firewall
onready var daynight_anim = $DayNightCycle/AnimationPlayer
onready var players_node = $Map/Objects/Entities/Players
onready var enemies_node = $Map/Objects/Entities/Enemies
onready var projectiles_node = $Map/Objects/Entities/Projectiles
onready var ground_effects_node = $Map/Ground/GroundEffects
onready var walls_node = $Map/Objects/Walls
onready var shrines_node = $Map/Ground/Shrines
onready var enemy_manager = $EnemyManager

var state = GameState.PREGAME
var countdown = 0
var time_started = 0
var base_exhaustion = 0
var time_of_day = "start"
var current_shrine = null

func start_server():
	$GameTick.start()
	player_spawn.position = $Map/PlayerSpawns/Pregame.position

remotesync func start_game():
	print("Game started")
	state = GameState.STAGE1
	time_started = OS.get_ticks_msec()
	daynight_anim.play("daynight")
	#daynight_anim.playback_speed = 2.0
	player_spawn.position = $Map/PlayerSpawns/Stage1.position
	current_shrine = shrines_node.get_child(0)
	if Game.is_host():
		enemy_manager.start_server()
	add_system_message("The enemy forces have arrived!")

func time_event(event):
	print("Time: ", event)
	time_of_day = event
	if Game.is_host():
		if event == "dawn":
			$ExhaustionTick.start()
			$FirewallTick.start()
			enemy_manager.speed_up_spawning()
		elif event == "night":
			$ExhaustionTick.stop()
			enemy_manager.speed_up_spawning()
		elif event == "midnight":
			enemy_manager.pause_spawning(20)
	if Game.is_player():
		Audio.music_time_update(event)
		for shrine in shrines_node.get_children():
			shrine.set_time(event)

func game_tick():
	if state == GameState.PREGAME:
		if countdown > 0:
			countdown -= 1
			if countdown <= 0:
				rpc("start_game")
				countdown = 0
		else:
			var players = players_node.get_child_count()
			if players >= 1:
				countdown = 15
				rpc("add_system_message", "The enemy forces will arrive in 15 seconds!")
	if state == GameState.STAGE1 and current_shrine.health <= 0:
		rpc("add_system_message", "The moonshrine has fallen!")
		state = GameState.STAGE2
		# current_shrine = shrines_node.get_child(1)

remotesync func move_firewall(y):
	$Tween.interpolate_property(firewall, "position:y", firewall.position.y, y, $FirewallTick.wait_time * .9)
	$Tween.start()
	
func add_new_player(data):
	data.global_position = $PlayerSpawn.global_position
	add_player_from_data(data)
	rpc("add_new_player_remote", data)
	rpc("add_system_message", data.player_name + " has joined the game")

puppet func add_new_player_remote(data):
	if players_node.get_node_or_null(str(data.id)) == null:
		add_player_from_data(data)

func add_player_from_data(data):
	var player = R.Player.instance()
	player.name = str(data.id)
	players_node.add_child(player)
	player.load_data(data)
	player.set_network_master(int(data.id))

func add_enemy_from_data(data):
	var enemy = R.Enemy.instance()
	enemy.name = str(data.id)
	enemies_node.add_child(enemy)
	enemy.load_data(data)

func remove_player(id):
	var p = players_node.get_node_or_null(str(id))
	if p != null:
		if is_network_master():
			rpc("add_system_message", p.player_name + " has left the game")
		p.untarget()
		p.delete()

func get_game_state():
	var game_state = {}
	game_state.state = state
	game_state.time = 0 if state == GameState.PREGAME else daynight_anim.current_animation_position
	game_state.player_spawn = player_spawn.position
	game_state.firewall = firewall.position.y
	game_state.players = []
	game_state.enemies = []
	game_state.walls = {}
	for p in players_node.get_children():
		game_state.players.append(p.get_data())
	for e in enemies_node.get_children():
		game_state.enemies.append(e.get_data())
	for w in walls_node.get_children():
		game_state.walls[w.name] = w.status
	return game_state

func load_game_state(game_state):
	state = game_state.state
	if state == GameState.STAGE1 or state == GameState.STAGE2:
		daynight_anim.play("daynight")
		daynight_anim.seek(game_state.time)
	player_spawn.position = game_state.player_spawn
	firewall.position.y = game_state.firewall
	for p in game_state.players:
		add_player_from_data(p)
	for e in game_state.enemies:
		add_enemy_from_data(e)
	for w in game_state.walls:
		var n = walls_node.get_node(w)
		if n:
			n.update_status(game_state.walls[w])

func get_nav_path(from, to, smooth = true, get_cost = false):
	return map.get_nav_path(from, to, smooth, get_cost)

func get_player_by_id(id):
	return players_node.get_node_or_null(str(id))

func get_enemy_by_id(id):
	return enemies_node.get_node_or_null(str(id))

master func send_chat(message: String):
	var id = get_tree().get_rpc_sender_id()
	var p = get_player_by_id(id)
	if p != null:
		if message.begins_with("/"):
			var ret = Game.parse_command(p, message)
			if ret != null and ret != "":
				rpc_id(id, "add_system_message", ret)
		else:
			message = Game.chat_regex.sub(message, "")
			chat_history.append({"p": p.player_name, "m": message})
			rpc("add_chat", p.player_name, message)

remotesync func add_chat(player_name, message):
	if not Game.is_server():
		gui.add_chat(player_name, message)

remotesync func add_system_message(message):
	if not Game.is_server():
		gui.add_system_message(message)

func _on_HealTick_timeout():
	if Game.is_host():
		for p in players_node.get_children():
			if not p.dead and p.health < p.player_class.MAX_HEALTH and p.last_combat < OS.get_ticks_msec() - 5000 and p.last_heal_tick < OS.get_ticks_msec() - 500:
				var heal = p.player_class.HEALTH_REGEN * 0.5
				if p.exhaustion > 50:
					var e = p.exhaustion - 50
					heal *= (50 - e * 0.75) / 50.0
				p.rpc("heal", min(p.health + heal, p.player_class.MAX_HEALTH), false)
				p.last_heal_tick = OS.get_ticks_msec()

func _on_ExhaustionTick_timeout():
	if Game.is_host() and players_node.get_child_count() > 0:
		base_exhaustion = clamp(base_exhaustion + 1, 0, 100)
		for p in players_node.get_children():
			if not p.dead:
				p.increase_exhaustion(1)

func _on_FirewallTick_timeout():
	if Game.is_host() and players_node.get_child_count() > 0 and (time_of_day == "dawn" or time_of_day == "day" or time_of_day == "midday" or time_of_day == "afternoon"):
		var amt = 16
		if state == GameState.STAGE1 and firewall.position.y > shrines_node.get_child(0).position.y - 128:
			amt = 0
		elif state == GameState.STAGE2 and firewall.position.y < shrines_node.get_child(0).position.y:
			amt *= 4
		if amt > 0:
			rpc("move_firewall", firewall.position.y + amt)
