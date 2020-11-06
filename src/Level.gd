extends Node2D

onready var players_node = $Entities/Players
onready var enemies_node = $Entities/Enemies

func _ready():
	$AnimationPlayer.play("daynight")

func start_server():
	$EnemyController.start_server()

func time_event(event):
	print("time event ", event)

master func enter_game(data):
	add_player_from_data(data)
	rpc("add_new_player", data)

puppet func add_new_player(data):
	if data.id != get_tree().get_network_unique_id():
		if players_node.get_node_or_null(str(data.id)) == null:
			add_player_from_data(data)

func add_player_from_data(data):
	var player = Game.Player.instance()
	player.name = str(data.id)
	players_node.add_child(player)
	player.load_data(data)
	player.set_network_master(int(data.id))

func remove_player(id):
	var p = players_node.get_node_or_null(str(id))
	if p != null:
		players_node.remove_child(p)

func get_game_state():
	var game_state = {}
	game_state.time = $AnimationPlayer.current_animation_position
	game_state.players = []
	for p in players_node.get_children():
		game_state.players.append(p.get_data())
	return game_state

remote func load_game_state(game_state):
	if game_state.version != Game.VERSION:
		get_tree().network_peer = null
		return
	if "time" in game_state:
		$AnimationPlayer.play("daynight")
		$AnimationPlayer.seek(game_state.time)
	if "players" in game_state:
		for p in game_state.players:
			add_player_from_data(p)

func get_enemy_by_id(id):
	return enemies_node.get_node_or_null(str(id))
