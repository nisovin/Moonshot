extends Node2D

onready var players_node = $Entities/Players
onready var enemies_node = $Entities/Enemies

var nav: AStar2D

func _ready():
	$AnimationPlayer.play("daynight")
	
	var nav_map = $NavMap
	nav = AStar2D.new()
	var points = {}
	for i in nav_map.get_child_count():
		var n = nav_map.get_child(i)
		nav.add_point(i, n.position, n.weight)
		points[n.name] = i
	for i in nav_map.get_child_count():
		var n = nav_map.get_child(i)
		for c in n.connections:
			var j = points[c]
			nav.connect_points(i, j, true)

func _unhandled_key_input(event):
	if event.scancode == KEY_F2 and event.pressed:
		var path = $Navigation2D.get_simple_path($EnemySpawn.position, $Position2D.position, true)
		$Line2D.points = path
		print(path)
	if event.scancode == KEY_F3 and event.pressed:
		$Navigation2D/Wall.enabled = !$Navigation2D/Wall.enabled
		

func start_server():
	$EnemyController.start_server(nav)

func time_event(event):
	print("time event ", event)

func add_new_player(data):
	print("ADD NEW PLAYER")
	add_player_from_data(data)
	rpc("add_new_player_remote", data)

puppet func add_new_player_remote(data):
	if players_node.get_node_or_null(str(data.id)) == null:
		add_player_from_data(data)

func add_player_from_data(data):
	var player = Game.Player.instance()
	player.name = str(data.id)
	players_node.add_child(player)
	player.load_data(data)
	player.set_network_master(int(data.id))

func add_enemy_from_data(data):
	var enemy = Game.Enemy.instance()
	enemy.name = str(enemy.id)
	enemies_node.add_child(enemy)
	enemy.load_data(data)

func remove_player(id):
	var p = players_node.get_node_or_null(str(id))
	if p != null:
		p.untarget()
		p.delete()

func get_game_state():
	var game_state = {}
	game_state.time = $AnimationPlayer.current_animation_position
	game_state.players = []
	game_state.enemies = []
	for p in players_node.get_children():
		game_state.players.append(p.get_data())
	for e in enemies_node.get_children():
		game_state.enemies.append(e.get_data())
	return game_state

func load_game_state(game_state):
	print(game_state)
	print(typeof(game_state) == TYPE_DICTIONARY)
	if "time" in game_state:
		print("time")
		$AnimationPlayer.play("daynight")
		$AnimationPlayer.seek(game_state.time)
	if game_state.has("players"):
		print("load players")
		for p in game_state.players:
			print(p)
			add_player_from_data(p)
	else:
		print("no players")
	if "enemies" in game_state:
		for e in game_state.enemies:
			add_enemy_from_data(e)

func get_player_by_id(id):
	return players_node.get_node_or_null(str(id))

func get_enemy_by_id(id):
	return enemies_node.get_node_or_null(str(id))
