extends Node

signal input_method_changed
signal entered_level

const PORT = 20514
const MAX_PLAYERS = 100
const VERSION = 1
const TILE_SIZE = 16

const Player = preload("res://player/Player.tscn")
const Enemy = preload("res://enemies/Enemy.tscn")

enum MPMode { SOLO, CLIENT, SERVER, HOST, REMOTE }

enum PlayerClass { WARRIOR, ARCHER, MAGE }

var mp_mode = MPMode.SOLO
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
	Engine.iterations_per_second = 30
	Engine.target_fps = 30
	
	level = preload("res://main/Level.tscn").instance()
	add_child(level)
	
	multiplayer_controller.level = level
	multiplayer_controller.init_server()
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	
	level.start_server()
	
func is_server():
	return mp_mode == MPMode.SERVER
	
func start_menu():
	add_child(load("res://main/MainMenu.tscn").instance())
	
func start_client():
	mp_mode = MPMode.CLIENT
	level = preload("res://main/Level.tscn").instance()
	add_child(level)
	level.visible = false
	
	multiplayer_controller.level = level
	multiplayer_controller.init_client()
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("minecraft.nisovin.com", PORT)
	get_tree().network_peer = peer
	
func join_game(clss):
	pass

func start_solo():
	mp_mode = MPMode.SOLO
	#Engine.iterations_per_second = 30
	
	level = preload("res://main/Level.tscn").instance()
	add_child(level)
	
	multiplayer_controller.queue_free()
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, 1)
	get_tree().network_peer = peer
	get_tree().refuse_new_network_connections = true

	level.add_player_from_data({"class_id": Game.PlayerClass.WARRIOR, "id": get_tree().get_network_unique_id()})

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

func parse_command(cmd_player, command: String):
	if not is_server(): return null
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
	if not cmd_player.authed:
		return null
	if cmd == "cap":
		if param.is_valid_integer():
			var cap = int(param)
			multiplayer_controller.max_players = cap
			return "Player cap set to " + str(cap)
	if cmd == "ban":
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
