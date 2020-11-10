extends Node

signal input_method_changed

const PORT = 20514
const MAX_PLAYERS = 20
const VERSION = 1

const Player = preload("res://player/Player.tscn")
const Enemy = preload("res://enemies/Enemy.tscn")

enum MPMode { SOLO, CLIENT, SERVER, HOST, REMOTE }

enum PlayerClass { WARRIOR, ARCHER, MAGE }

var mp_mode = MPMode.SOLO
var using_controller = false
var controller_index = 0
var level
var lock_player_input = false
var auth_password = ""
var player = null

var player_name_regex = RegEx.new()
var chat_regex = RegEx.new()

onready var centered_message = $CanvasLayer/CenteredMessage/Label
onready var multiplayer_controller = $MultiplayerController

func _ready():
	centered_message.visible = false
	player_name_regex.compile("[^A-Za-z0-9_ ]")
	chat_regex.compile("[^A-Za-z0-9_\\-()!.?@#$%&*+=:;'\" ]")
	var file = File.new()
	if file.file_exists("auth_password.txt"):
		file.open("auth_password.txt", File.READ)
		auth_password = file.get_as_text().strip_edges()
		file.close()
	print("PASS:", auth_password)

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
	
const RESERVED_NAMES = [ "server", "nisovin", "tonyarawaka", "marzhae", "aeldae" ]
const BAD_WORDS = [ "" ]
