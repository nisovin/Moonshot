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
	level.add_player(player)
	player.init(Game.MPMode.SERVER, Game.PlayerClass.WARRIOR)
	player.set_network_master(id)
	
func _on_player_disconnected(id):
	print("Player disconnected: ", id)
	level.remove_player(id)
