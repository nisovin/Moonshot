extends CanvasLayer

const STATUS_TOOLTIPS = [
	{ "name": "Midnight", "description": "It is midnight, when you are most powerful. Your damage and energy regeneration are increased." },
	{ "name": "Energized", "description": "Just before the moon shrine was corrupted, it released a burst of lunar energy. Your health regen, energy regen, and cooldown recovery are increased." },
	{ "name": "Zenith", "description": "It is midday, when the enemy is most powerful. Their damage is increased." },
	{ "name": "AAARRG!", "description": "The enemy is filled with fiery rage. Their damage is greatly increased, but they also take more damage." },
	{ "name": "Hurry Up!", "description": "The enemy has been energized, greatly increasing their movement speed." },
	{ "name": "Destroy The Walls!", "description": "The enemy is currently focused on tearing down the walls, and will try to ignore players." },
	{ "name": "Slay Them!", "description": "The enemy is currently focused on killing players. Their damage is increased." }
]

onready var chat_line = $Chat/ChatLine
onready var scroll = $Chat/ScrollContainer
onready var chat_container = $Chat/ScrollContainer/VBoxContainer
onready var chat_tween = $Chat/Tween

var chatting = false
var showing_tooltip = null

func _ready():
	scroll.get_v_scrollbar().modulate = Color.transparent
	chat_line.modulate = Color.transparent
	Game.connect("entered_level", self, "_on_entered_level")
	$Abilities.hide()

func open_chat():
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
	_add_to_chat("[color=#66cccc]" + player_name + "[/color] [color=#c0c0c0]>[/color] [color=#f0f0f0]" + message + "[/color]")
		
func add_system_message(message):
	_add_to_chat("[color=yellow]" + message + "[/color]")
	
func _add_to_chat(message):
	var entry = preload("res://gui/ChatEntry.tscn").instance()
	entry.parse_bbcode(message)
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

func _on_entered_level():
	if Game.player.class_id == Game.PlayerClass.ARCHER:
		$Abilities/Attack1.texture_under = load("res://gui/archer_attack1.png")
		$Abilities/Attack1.texture_progress = $Abilities/Attack1.texture_under
		$Abilities/Attack2.texture_under = load("res://gui/archer_attack2.png")
		$Abilities/Attack2.texture_progress = $Abilities/Attack2.texture_under
		$Abilities/Movement.texture_under = load("res://gui/archer_movement.png")
		$Abilities/Movement.texture_progress = $Abilities/Movement.texture_under
		$Abilities/Ultimate.texture_under = load("res://gui/archer_ultimate.png")
		$Abilities/Ultimate.texture_progress = $Abilities/Ultimate.texture_under
	$Abilities.show()

func _process(delta):
	if Game.player != null:
		update_ui()

func update_ui():
	var c = Game.player.player_class
	var i = 0
	
	$PlayerBars/Energy.value = c.energy
	$PlayerBars/Energy/Label.text = str(floor(c.energy))
	
	i = 0
	for a in $Abilities.get_children():
		a.value = 1 - c.call("get_" + a.name.to_lower() + "_cooldown")
		a.tint_progress = Color.cyan if a.value == 1 else Color.white
		var p = a.get_local_mouse_position()
		var s = a.rect_size
		if p.x > 0 and p.x < s.x and p.y > 0 and p.y < s.y:
			show_tooltip("A" + str(i), c.ABILITIES[i])
			return
		i += 1
		
	i = 0
	for a in $Statuses.get_children():
		var p = a.get_local_mouse_position()
		var s = a.rect_size
		if a.visible and p.x > 0 and p.x < s.x and p.y > 0 and p.y < s.y:
			show_tooltip("S" + str(i), STATUS_TOOLTIPS[i], "TL")
			return
		i += 1
		
	hide_tooltip()

func show_tooltip(id, data, corner = "BR"):
	if showing_tooltip != id:
		showing_tooltip = id
		$Tooltip.show()
		$Tooltip/VBoxContainer/AbilityName.text = data.name
		var desc = data.description
		if data.has("cost"):
			desc += "\n[color=yellow]Cost:[/color] " + data.cost
		if data.has("cooldown"):
			desc += "\n[color=yellow]Cooldown:[/color] " + data.cooldown
		$Tooltip/VBoxContainer/RichTextLabel.parse_bbcode(desc)
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		$Tooltip.rect_size.y = $Tooltip/VBoxContainer/RichTextLabel.get_content_height() + 30
	if corner == "BR":
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position() - $Tooltip.rect_size
	else:
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position()
	
func hide_tooltip():
	$Tooltip.hide()
	showing_tooltip = null
