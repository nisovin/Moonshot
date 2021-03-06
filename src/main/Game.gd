extends Node

signal input_method_changed
signal entered_level

const MAX_PLAYERS = 40
const PLAYERS_TO_START = 1
const START_COUNTDOWN = 30
const VERSION = "0.1.16"
const TILE_SIZE = 16

enum MPMode { NONE, SOLO, CLIENT, SERVER, HOST, REMOTE }

enum Layer { WALLS = 1, PLAYERS = 2, ENEMIES = 4, PLAYER_HITBOX = 8, ENEMY_HITBOX = 16, TEMP_WALLS = 32, SHRINES = 64, PLAYER_INVIS = 128 }
enum PlayerClass { WARRIOR, ARCHER, PRIEST }
enum EnemyClass { GRUNT, MAGE, ELITE, PHOENIX, BOMBER, SIEGE }
enum Effects { MIDNIGHT, MIDDAY, SHRINEDEATH, RAGE, FATIGUE, FEAR, FOCUS_KEEP, CONFUSION }

var mp_mode = MPMode.NONE
var using_controller = false
var controller_index = 0
var level = null
var lock_player_input = false
var player = null
var saved_player_name = ""

var player_name_regex = RegEx.new()
var chat_regex = RegEx.new()

var multiplayer_controller = null

onready var centered_message = $CanvasLayer/CenteredMessage/Label

func _ready():
	centered_message.visible = false
	player_name_regex.compile("[^A-Za-z0-9_ ]")
	chat_regex.compile("[^A-Za-z0-9_\\-()!.?@#$%&*+=:;'\"<> ]")
	load_persistent()

func _unhandled_key_input(event):
	if event.scancode == KEY_F11 and event.pressed:
		OS.window_fullscreen = not OS.window_fullscreen
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
func is_server():
	return mp_mode == MPMode.SERVER

func is_host():
	return mp_mode == MPMode.SERVER or mp_mode == MPMode.HOST or mp_mode == MPMode.SOLO

func is_player():
	return mp_mode == MPMode.CLIENT or mp_mode == MPMode.HOST or mp_mode == MPMode.SOLO

func is_solo():
	return mp_mode == MPMode.SOLO

func is_client():
	return mp_mode == MPMode.CLIENT
	
func load_persistent():
	var file = File.new()
	if file.file_exists("user://moon.sav"):
		if file.open("user://moon.sav", File.READ) == OK:
			var data = file.get_var()
			file.close()
			if data.has("saved_player_name"):
				saved_player_name = data.saved_player_name
				
func save_persistent():
	var file = File.new()
	if file.open("user://moon.sav", File.WRITE) == OK:
		var data = {
			"saved_player_name": saved_player_name
		}
		file.store_var(data)
		file.close()

func create_mp_controller():
	if multiplayer_controller != null:
		remove_child(multiplayer_controller)
		multiplayer_controller.queue_free()
	multiplayer_controller = R.MultiplayerController.instance()
	add_child(multiplayer_controller)

func start_server():
	mp_mode = MPMode.SERVER
	R.load_resources(true)
	Engine.iterations_per_second = 30
	Engine.target_fps = 30
	
	level = R.Level.instance()
	add_child(level)
	
	create_mp_controller()
	multiplayer_controller.init_server()
	
	level.start_server()

func restart_server():
	print("Restarting server")
	if is_solo():
		leave_game()
	else:
		free_level()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		level = R.Level.instance()
		add_child(level)
		multiplayer_controller.restart_server()
		level.start_server()

func start_menu():
	R.load_resources(false)
	add_child(R.MainMenu.instance())
	
func start_client(ip, port):
	mp_mode = MPMode.CLIENT
	level = R.Level.instance()
	add_child(level)
	level.visible = false
	
	create_mp_controller()
	multiplayer_controller.init_client(ip, port)
#
#func restart_client():
#	free_level()
#	yield(get_tree(), "idle_frame")
#	yield(get_tree(), "idle_frame")
#	level = R.Level.instance()
#	add_child(level)
#	level.visible = false
	
func leave_game():
	get_tree().network_peer = null
	free_level()
	start_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_solo():
	mp_mode = MPMode.SOLO
	#Engine.iterations_per_second = 30
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(20514, 1)
	get_tree().network_peer = peer
	get_tree().refuse_new_network_connections = true
	
	level = R.Level.instance()
	add_child(level)
	
	var menu = R.JoinGameMenu.instance()
	add_child(menu)
	menu.connect("option_selected", self, "_on_solo_join")
	
	#level.add_new_player({"class_id": Game.PlayerClass.WARRIOR, "id": get_tree().get_network_unique_id(), "player_name": "Player"})

	#level.start_server()

func _on_solo_join(option, player_name):
	if option == -1:
		leave_game()
	else:
		level.add_new_player({"class_id": option, "id": "1", "player_name": player_name})
		level.start_server()
	

func show_centered_message(text):
	centered_message.text = text
	centered_message.visible = true
	
func hide_centered_message():
	centered_message.visible = false

func get_player_by_id(id):
	return level.get_player_by_id(id)

func get_enemy_by_id(id):
	return level.get_enemy_by_id(id)

func get_tile_pos(v):
	return Vector2(int(floor(v.x / TILE_SIZE)), int(floor(v.y / TILE_SIZE)))

func free_level():
	if level != null and not level.is_queued_for_deletion():
		level.queue_free()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		level = null
		player = null

func parse_command(cmd_player, command: String):
	if not is_host(): return null
	var parts = command.substr(1).split(" ", false, 1)
	var cmd = parts[0].to_lower()
	var param = "" if parts.size() == 1 else parts[1]
	if cmd == "auth":
		if param != "" and param == multiplayer_controller.auth_password:
			cmd_player.authed = true
			print("Player authed: " + cmd_player.player_name)
			return "Authenticated"
		else:
			return null
	if not cmd_player.authed and is_server():
		return null
	if cmd == "cap":
		if param.is_valid_integer():
			var cap = int(param)
			multiplayer_controller.max_players = cap
			return "Player cap set to " + str(cap)
	elif cmd == "startgame":
		level.rpc("start_game")
	elif cmd == "wait":
		var ok = level.wait()
		if ok:
			return "Waiting for /startgame"
	elif cmd == "maxenemies":
		if param.is_valid_integer():
			var cap = int(param)
			level.enemy_manager.max_enemies = cap
			return "Max enemies set to " + str(cap)
	elif cmd == "speedup":
		var lvl = level.enemy_manager.speed_up_spawning()
		return "Spawning at level " + str(lvl)
	elif cmd == "event":
		var type = level.start_event(param)
		if param == "":
			return "Started event " + type
	elif cmd == "ban":
		var banned = multiplayer_controller.ban(param)
		if banned:
			return "Banned: name=" + param + ", id=" + str(banned[0]) + ", ip=" + banned[1] + ", uuid=" + banned[2]
		else:
			return "Unable to find player: " + param
	elif cmd == "kick":
		var kicked = multiplayer_controller.kick(param)
		if kicked:
			return "Kicked: name=" + param + ", id=" + str(kicked)
		else:
			return "Unable to find player: " + param
	elif cmd == "destroyshrine":
		if level.current_shrine != null:
			level.current_shrine.apply_damage(5000)
			return "Dealt 5000 damage to current shrine"
	elif cmd == "killenemies":
		for e in level.enemies_node.get_children():
			e.hit({"damage": 1000})
	return null


