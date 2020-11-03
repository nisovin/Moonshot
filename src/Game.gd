extends Node

const PORT = 20500
const MAX_PLAYERS = 20

const Player = preload("res://player/Player.tscn")

enum MPMode { SOLO, CLIENT, SERVER, REMOTE }

var mp_mode = MPMode.SOLO

func start_server():
	mp_mode = MPMode.SERVER
	Engine.iterations_per_second = 20
	
	var level = preload("res://Level.tscn").instance()
	add_child(level)
	
	var ctrl = Node2D.new()
	ctrl.name = "ServerController"
	ctrl.set_script(load("res://network/ServerController.gd"))
	add_child(ctrl)
	ctrl.level = level
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	
func start_client():
	mp_mode = MPMode.CLIENT
	var level = preload("res://Level.tscn").instance()
	add_child(level)
	
	var ctrl = Node2D.new()
	ctrl.name = "ClientController"
	ctrl.set_script(load("res://network/ClientController.gd"))
	add_child(ctrl)
	ctrl.level = level
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", PORT)
	get_tree().network_peer = peer

func start_solo():
	mp_mode = MPMode.SOLO
	var level = preload("res://Level.tscn").instance()
	add_child(level)
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, 0)
	get_tree().network_peer = peer
	get_tree().refuse_new_network_connections = true
