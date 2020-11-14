extends Control

func _ready():
	$ServerList.hide()

func _on_Singleplayer_pressed():
	Game.start_solo()
	queue_free()

func _on_Multiplayer_pressed():
	$Menu.hide()
	Game.show_centered_message("Finding servers...")
	get_servers()
	
func _on_Fullscreen_pressed():
	OS.window_fullscreen = not OS.window_fullscreen

func _on_Quit_pressed():
	get_tree().quit()

func get_servers():
	$HTTPRequest.request("https://nisovin.com/gamejams/get_servers.php")

func _on_HTTPRequest_request_completed(result, response_code, headers, body: PoolByteArray):
	var response = body.get_string_from_utf8()
	var json_result = JSON.parse(response)
	if json_result.error == OK:
		var servers = json_result.result.servers
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
			while $ServerList/List.get_child_count() > 1:
				var c = $ServerList/List.get_child(1)
				$ServerList/List.remove_child(c)
				c.queue_free()
			var template = $ServerList/List.get_child(0)
			for s in servers:
				var entry = template.duplicate()
				entry.get_node("Name").text = s.name
				entry.get_node("Status").text = s.status
				entry.get_node("Players").text = str(s.players)
				entry.get_node("Join").connect("pressed", self, "_on_join_pressed", [s])
				$ServerList/List.add_child(entry)
			$ServerList.show()

func _on_join_pressed(server):
	Game.start_client(server.ip, int(server.port))
	queue_free()
