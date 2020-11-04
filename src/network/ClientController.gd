extends Node

var level

func _ready():
	get_tree().connect("connected_to_server", self, "_on_connected")
	get_tree().connect("server_disconnected", self, "_on_disconnected")
	get_tree().connect("connection_failed", self, "_on_failed")
	#get_tree().connect("network_peer_connected", self, "_on_player_connected")
	#get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")

func _on_connected():
	var player = Game.Player.instance()
	player.name = str(get_tree().get_network_unique_id())
	level.add_player(player)
	player.init(Game.MPMode.CLIENT, Game.PlayerClass.WARRIOR)
	player.set_network_master(get_tree().get_network_unique_id())
	
func _on_disconnected():
	pass
	
func _on_failed():
	pass
	
