extends Node

var level
var players = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")

func _on_player_connected(id):
	print("Player connected: ", id)
	
	var data = {}
	data.version = Game.VERSION
	data.game_state = level.get_game_state()
	level.rpc_id(id, "load_game_state", data)
	
func _on_player_disconnected(id):
	print("Player disconnected: ", id)
	level.remove_player(id)
