extends Control

var join = false

func _ready():
	$ServerList.hide()
	get_servers()

func _on_Singleplayer_pressed():
	$Click.play()
	Game.start_solo()
	queue_free()

func _on_Multiplayer_pressed():
	$Click.play()
	$Menu.hide()
	Game.show_centered_message("Finding servers...")
	join = true
	get_servers()

func get_servers():
	$HTTPRequest.request("https://nisovin.com/gamejams/get_servers.php")

func _on_HTTPRequest_request_completed(result, response_code, headers, body: PoolByteArray):
	var response = body.get_string_from_utf8()
	var json_result = JSON.parse(response)
	if json_result.error == OK:
		var servers = json_result.result.servers
		if servers.size() == 0:
			$Menu/VBoxContainer/MPStatus.text = "Offline :("
		else:
			var p = 0
			for server in servers:
				p += int(server.players)
			$Menu/VBoxContainer/MPStatus.text = str(p) + " players in-game"
		if join:
			if servers.size() == 0:
				Game.show_centered_message("No servers are available :(")
				yield(get_tree().create_timer(3), "timeout")
				Game.hide_centered_message()
				$Menu.show()
			elif servers.size() == 1:
				var server = servers[0]
				Game.start_client(server.ip, int(server.port))
				queue_free()
			else:
				Game.hide_centered_message()
				var list = $ServerList/PanelContainer/VBox/List
				while list.get_child_count() > 2:
					var c = list.get_child(2)
					list.remove_child(c)
					c.queue_free()
				var template = list.get_child(0)
				template.get_node("Join").hide()
				for s in servers:
					var entry = template.duplicate()
					entry.get_node("Name").text = s.name
					entry.get_node("Status").text = s.status
					entry.get_node("Players").text = str(s.players)
					entry.get_node("Join").connect("pressed", self, "_on_join_pressed", [s])
					entry.get_node("Join").show()
					list.add_child(entry)
				$ServerList.show()

func _on_join_pressed(server):
	$Click.play()
	Game.start_client(server.ip, int(server.port))
	queue_free()

func _on_CancelButton_pressed():
	$Click.play()
	$ServerList.hide()
	$Menu.show()

func _on_button_over():
	$Rollover.play()

func _on_Fullscreen_pressed():
	$Click.play()
	OS.window_fullscreen = not OS.window_fullscreen

func _on_Settings_pressed():
	$Click.play()
	Settings.show_settings()

func _on_Credits_pressed():
	$Click.play()
	$Credits.show()

func _on_CloseCredits_pressed():
	$Click.play()
	$Credits.hide()

func _on_Quit_pressed():
	$Click.play()
	get_tree().quit()

