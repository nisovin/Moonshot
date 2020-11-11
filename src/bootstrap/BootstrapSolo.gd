extends Node

func _ready():
	Game.start_solo()
	queue_free()
	
func int_to_bin_array(num):
	var arr = []
	while num > 0:
		arr.push_back(num % 2)
		num /= 2
	return arr
