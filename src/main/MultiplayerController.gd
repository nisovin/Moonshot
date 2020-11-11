extends Node

var level

var players_by_id = {}

var auth_password = ""
var banned_ips = []
var banned_uuids = []

var name_to_id = {}
var id_to_uuid = {}

var max_players = 20
var dc_error = null

func init_server():
	get_tree().connect("network_peer_connected", self, "_on_server_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_server_player_disconnected")
	
	var file = File.new()
	if file.file_exists("auth_password.txt"):
		file.open("auth_password.txt", File.READ)
		auth_password = file.get_as_text().strip_edges()
		file.close()
	if file.file_exists("banned_ips.txt"):
		file.open("banned_ips.txt", File.READ)
		while not file.eof_reached():
			var l = file.get_line().strip_edges()
			if l != "":
				banned_ips.append(l)
		file.close()
	if file.file_exists("banned_uuids.txt"):
		file.open("banned_uuids.txt", File.READ)
		while not file.eof_reached():
			var l = file.get_line().strip_edges()
			if l != "":
				banned_uuids.append(l)
		file.close()

func init_client():
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	get_tree().connect("connection_failed", self, "_on_failed_to_connect")
	get_tree().connect("network_peer_disconnected", self, "_on_client_player_disconnected")
	
	Game.show_centered_message("Connecting to server...")

# SERVER-SIDE

func _on_server_player_connected(id):
	print("Player connected: id=", id)
	
	var c = get_tree().multiplayer.get_network_connected_peers().size()
	if c > max_players:
		rpc_id(id, "disconnect_error", "Server is full")
		get_tree().network_peer.disconnect_peer(id, false)
		print("Server is full - " + max_players)
		return
	
	var ip = get_tree().network_peer.get_peer_address(id)
	if banned_ips.find(ip) >= 0:
		get_tree().network_peer.disconnect_peer(id, true)
		print("Banned IP kicked: " + ip)
		return
	
	var data = {}
	data.version = Game.VERSION
	data.game_state = level.get_game_state()
	rpc_id(id, "load_game_state", data)
	
func _on_server_player_disconnected(id):
	print("Player disconnected: id=", id)
	level.remove_player(id)

remote func player_join(class_id, player_name: String, player_uuid: String):
	var id = get_tree().get_rpc_sender_id()
	player_name = Game.player_name_regex.sub(player_name, "").strip_edges()
	
	# check ban
	if player_uuid in banned_uuids:
		get_tree().network_peer.disconnect_peer(id, true)
		print("Banned UUID kicked: " + player_uuid)
		return
	
	# check existing name
	if player_name.to_lower() in name_to_id:
		var curr_id = name_to_id[player_name.to_lower()]
		var uuid = id_to_uuid[curr_id]
		if uuid != player_uuid or curr_id in get_tree().multiplayer.get_network_connected_peers():
			rpc_id(id, "invalid_name")
			return
	
	# check invalid name
	if not Game.check_name(player_name):
		rpc_id(id, "invalid_name")
		return
	
	print("Player joined: id=", id, " name=" , player_name, " class=", class_id, " uuid=", player_uuid)
	level.add_new_player({"id": id, "class_id": class_id, "player_name": player_name, "uuid": player_uuid})
	name_to_id[player_name.to_lower()] = id
	id_to_uuid[id] = player_uuid

func ban(player_name):
	player_name = player_name.to_lower()
	var id = -1
	var ip = ""
	var uuid = ""
	if player_name in name_to_id:
		id = name_to_id[player_name]
		ip = get_tree().network_peer.get_peer_address(id)
		if ip != null and ip != "":
			banned_ips.append(ip)
		else:
			ip = ""
		if id in id_to_uuid:
			uuid = id_to_uuid[id]
			banned_uuids.append(uuid)
	save_ban_files()
	if id > 0 and (ip != "" or uuid != ""):
		print("Banned: name=" + player_name + " id=" + str(id) + " ip=" + ip + " uuid=" + uuid)
		return [id, ip, uuid]
	else:
		return false

func save_ban_files():
	var file = File.new()
	file.open("banned_ips.txt", File.WRITE)
	for ip in banned_ips:
		file.store_line(ip)
	file.close()
	file.open("banned_uuids.txt", File.WRITE)
	for uuid in banned_uuids:
		file.store_line(uuid)
	file.close()

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
		rpc_id(1, "player_join", option, player_name, OS.get_unique_id())

remote func disconnect_error(err):
	dc_error = err

func _on_disconnected_from_server():
	print("DISCONNECT")
	level.queue_free()
	Game.show_centered_message(dc_error if dc_error != null else "Disconnected")
	dc_error = null
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
