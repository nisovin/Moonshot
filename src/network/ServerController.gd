extends Node

var level
var players = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")

func _on_player_connected(id):
	print("Player connected: ", id)
	var player = Game.Player.instance()
	player.name = str(id)
	player.init(Game.MPMode.SERVER)
	level.add_child(player)
	
func _on_player_disconnected(id):
	print("Player disconnected: ", id)
