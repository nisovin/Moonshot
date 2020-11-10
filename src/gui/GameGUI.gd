extends CanvasLayer

onready var chat_line = $Chat/ChatLine
onready var scroll = $Chat/ScrollContainer
onready var chat_container = $Chat/ScrollContainer/VBoxContainer
onready var chat_tween = $Chat/Tween

var chatting = false

func _ready():
	scroll.get_v_scrollbar().modulate = Color.transparent
	chat_line.modulate = Color.transparent

func open_chat():
	print("open")
	Game.lock_player_input = true
	chatting = true
	chat_tween.stop_all()
	chat_line.grab_focus()
	chat_line.modulate = Color.white
	chat_line.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.get_v_scrollbar().modulate = Color.white
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	for c in chat_container.get_children():
		c.modulate = Color.white

func close_chat():
	chat_line.release_focus()
	chat_line.modulate = Color.transparent
	chat_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.get_v_scrollbar().modulate = Color.transparent
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in chat_container.get_children():
		c.modulate = Color.transparent
	Game.lock_player_input = false
	chatting = false

func add_chat(player_name, message):
	var entry = preload("res://gui/ChatEntry.tscn").instance()
	entry.parse_bbcode("[color=#66cccc]" + player_name + "[/color] [color=#c0c0c0]>[/color] [color=#f0f0f0]" + message + "[/color]")
	chat_container.add_child(entry)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	scroll.scroll_vertical = chat_container.rect_size.y + 100
	if not chatting:
		chat_tween.interpolate_property(entry, "modulate", Color.white, Color.transparent, 2, Tween.TRANS_CUBIC, Tween.EASE_IN, 6)
		chat_tween.start()

func _unhandled_input(event):
	if event.is_action_pressed("chat") and not chatting:
		open_chat()
	elif event.is_action_pressed("ui_cancel") and chatting:
		close_chat()

func _on_ChatLine_text_entered(new_text):
	if new_text == "":
		close_chat()
		return
	chat_line.text = ""
	close_chat()
	yield(get_tree(), "idle_frame")
	owner.rpc("send_chat", new_text)

func _process(delta):
	if Game.player != null:
		var c = Game.player.player_class
		$Abilities/Attack2.value = 1 - c.get_attack2_cooldown()
		$Abilities/Attack2.tint_progress = Color.cyan if $Abilities/Attack2.value == 1 else Color.white
		$Abilities/Movement.value = 1 - c.get_movement_cooldown()
		$Abilities/Movement.tint_progress = Color.cyan if $Abilities/Movement.value == 1 else Color.white
		$Abilities/Ultimate.value = 1 - c.get_ultimate_cooldown()
		$Abilities/Ultimate.tint_progress = Color.cyan if $Abilities/Ultimate.value == 1 else Color.white
