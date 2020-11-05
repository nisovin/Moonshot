extends Node2D

func _ready():
	$AnimationPlayer.play("daynight")

func time_event(event):
	print("time event ", event)

func add_player(player):
	$Players.add_child(player)

func add_player_from_data(data):
	var player = Game.Player.instance()
	player.name = str(data.id)
	$Players.add_child(player)
	player.load_data(data)
	player.set_network_master(int(data.id))

func remove_player(id):
	var p = $Players.get_node_or_null(str(id))
	if p != null:
		$Players.remove_child(p)

func get_game_state():
	var game_state = {}
	game_state.time = $AnimationPlayer.current_animation_position
	game_state.players = []
	for p in $Players.get_children():
		game_state.players.append(p.get_data())
	return game_state

remote func load_game_state(game_state):
	if "time" in game_state:
		$AnimationPlayer.play("daynight")
		$AnimationPlayer.seek(game_state.time)
	if "players" in game_state:
		for p in game_state.players:
			add_player_from_data(p)
