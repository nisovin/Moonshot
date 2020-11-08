extends Control



func _on_Singleplayer_pressed():
	Game.start_solo()
	queue_free()

func _on_Multiplayer_pressed():
	Game.start_client()
	queue_free()

func _on_Quit_pressed():
	get_tree().quit()
