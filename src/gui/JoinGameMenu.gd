extends Control

signal option_selected

onready var name_field = $CenterContainer/VBoxContainer/NameField

func _ready():
	name_field.text = Game.saved_player_name
	name_field.grab_focus()
	name_field.caret_position = name_field.text.length()

func choose(c):
	name_field.text = name_field.text.strip_edges()
	if c != -1 and name_field.text == "":
		name_field.modulate = Color(1, 0.5, 0.5)
		name_field.grab_focus()
		yield(get_tree().create_timer(1), "timeout")
		name_field.modulate = Color.white
		return
	if name_field.text != Game.saved_player_name:
		Game.saved_player_name = name_field.text
		Game.save_persistent()
	emit_signal("option_selected", c, name_field.text)
	queue_free()

func _on_Warrior_pressed():
	choose(Game.PlayerClass.WARRIOR)

func _on_Archer_pressed():
	choose(Game.PlayerClass.ARCHER)

func _on_Priest_pressed():
	choose(Game.PlayerClass.PRIEST)

func _on_Disconnect_pressed():
	choose(-1)

func _on_NameField_text_changed(new_text):
	if new_text == " " or new_text == "_":
		name_field.text = ""
		return
	var rep_text = Game.player_name_regex.sub(new_text, "", true)
	if rep_text.count(" ") > 1:
		rep_text = rep_text.strip_edges()
	if rep_text != new_text:
		name_field.text = rep_text
		name_field.caret_position = name_field.text.length()
