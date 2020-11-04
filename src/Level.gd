extends Node2D

func add_player(player):
	$Players.add_child(player)

func remove_player(id):
	var p = $Players.get_node_or_null(str(id))
	if p != null:
		$Players.remove_child(p)
