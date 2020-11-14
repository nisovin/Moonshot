extends Node

signal input_method_changed
signal entered_level

const MAX_PLAYERS = 100
const VERSION = 1
const TILE_SIZE = 16

enum MPMode { NONE, SOLO, CLIENT, SERVER, HOST, REMOTE }

enum PlayerClass { WARRIOR, ARCHER, PRIEST }
enum EnemyClass { GRUNT, MAGE }

var mp_mode = MPMode.NONE
var using_controller = false
var controller_index = 0
var level = null
var lock_player_input = false
var player = null
var saved_player_name = ""

var player_name_regex = RegEx.new()
var chat_regex = RegEx.new()

onready var centered_message = $CanvasLayer/CenteredMessage/Label
onready var multiplayer_controller = $MultiplayerController

func _ready():
	centered_message.visible = false
	player_name_regex.compile("[^A-Za-z0-9_ ]")
	chat_regex.compile("[^A-Za-z0-9_\\-()!.?@#$%&*+=:;'\" ]")
	load_persistent()

func _unhandled_key_input(event):
	if event.scancode == KEY_F11 and event.pressed:
		OS.window_fullscreen = not OS.window_fullscreen

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

func start_server():
	mp_mode = MPMode.SERVER
	R.load_resources(true)
	Engine.iterations_per_second = 30
	Engine.target_fps = 30
	
	level = R.Level.instance()
	add_child(level)
	
	multiplayer_controller.level = level
	multiplayer_controller.init_server()
	
	
	level.start_server()
	
func is_server():
	return mp_mode == MPMode.SERVER

func is_host():
	return mp_mode == MPMode.SERVER or mp_mode == MPMode.HOST or mp_mode == MPMode.SOLO

func is_player():
	return mp_mode == MPMode.CLIENT or mp_mode == MPMode.HOST or mp_mode == MPMode.SOLO

func start_menu():
	R.load_resources(false)
	add_child(R.MainMenu.instance())
	
func start_client(ip, port):
	mp_mode = MPMode.CLIENT
	level = R.Level.instance()
	add_child(level)
	level.visible = false
	
	multiplayer_controller.level = level
	multiplayer_controller.init_client(ip, port)

	Audio.start_music()

func leave_game():
	get_tree().network_peer = null
	level.queue_free()
	start_menu()

func join_game(clss):
	pass

func start_solo():
	mp_mode = MPMode.SOLO
	#Engine.iterations_per_second = 30
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(20514, 1)
	get_tree().network_peer = peer
	get_tree().refuse_new_network_connections = true
	
	level = R.Level.instance()
	add_child(level)
	
	multiplayer_controller.queue_free()

	level.add_new_player({"class_id": Game.PlayerClass.WARRIOR, "id": get_tree().get_network_unique_id(), "player_name": "Player"})

	level.start_server()
	Audio.start_music()

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
	elif cmd == "maxenemies":
		if param.is_valid_integer():
			var cap = int(param)
			level.enemy_manager.max_enemies = cap
			return "Max enemies set to " + str(cap)
	elif cmd == "ban":
		var banned = multiplayer_controller.ban(param)
		if banned:
			return "Banned: name=" + param + ", id=" + str(banned[0]) + ", ip=" + banned[1] + ", uuid=" + banned[2]
		else:
			return "Unable to find player: " + param
	return null

func check_name(player_name: String):
	var p := player_name.to_lower()
	for n in RESERVED_NAMES:
		if p == n:
			return false
	p = p.replace(" ", "").replace("_", "")
	for n in BAD_WORDS:
		if p.find(n) >= 0:
			return false
	return true
	
const RESERVED_NAMES = [ "server" ]
const BAD_WORDS = [ "" ]


