extends Node

var level

var players_by_id = {}
var used_player_names = []

func init_server():
	get_tree().connect("network_peer_connected", self, "_on_server_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_server_player_disconnected")
	

func init_client():
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	get_tree().connect("connection_failed", self, "_on_failed_to_connect")
	get_tree().connect("network_peer_disconnected", self, "_on_client_player_disconnected")
	
	Game.show_centered_message("Connecting to server...")

# SERVER-SIDE

func _on_server_player_connected(id):
	print("Player connected: id=", id)
	
	var data = {}
	data.version = Game.VERSION
	data.game_state = level.get_game_state()
	rpc_id(id, "load_game_state", data)
	
func _on_server_player_disconnected(id):
	print("Player disconnected: id=", id)
	level.remove_player(id)

remote func player_join(class_id, player_name: String):
	var id = get_tree().get_rpc_sender_id()
	player_name = Game.player_name_regex.sub(player_name, "")
	if not Game.check_name(player_name):
		rpc_id(id, "invalid_name")
	else:
		print("Player joined: id=", id, " name=" , player_name, " class=", class_id)
		level.add_new_player({"id": id, "class_id": class_id, "player_name": player_name})


# CLIENT-SIDE

func _on_connected_to_server():
	print("CONNECTED")
	Game.show_centered_message("Waiting for game state...")

remote func load_game_state(data):
	print("RECEIVED GAME STATE")
	if data.version != Game.VERSION:
		Game.show_centered_message("Game version mismatch: client=" + str(Game.VERSION) + "; server=" + str(data.version))
		get_tree().network_peer = null
		return
	Game.hide_centered_message()
	level.load_game_state(data.game_state)
	level.visible = true
	show_join_menu()
	
func show_join_menu():
	var menu = load("res://gui/JoinGameMenu.tscn").instance()
	Game.add_child(menu)
	menu.connect("option_selected", self, "_on_join_option_selected")

func _on_join_option_selected(option, player_name):
	print(option)
	if option == -1:
		level.queue_free()
		Game.start_menu()
	else:
		rpc_id(1, "player_join", option, player_name)
	
func _on_disconnected_from_server():
	print("DISCONNECT")
	level.queue_free()
	Game.show_centered_message("Disconnected")
	yield(get_tree().create_timer(5), "timeout")
	Game.hide_centered_message()
	Game.start_menu()
	
func _on_failed_to_connect():
	Game.show_centered_message("Failed to connect :(")
	yield(get_tree().create_timer(5), "timeout")
	Game.hide_centered_message()
	level.queue_free()
	Game.start_menu()

remote func invalid_name():
	print("INVALID NAME")
	Game.show_centered_message("Invalid name or name already in use")
	yield(get_tree().create_timer(2), "timeout")
	Game.hide_centered_message()
	show_join_menu()

func _on_client_player_disconnected(id):
	level.remove_player(id)
