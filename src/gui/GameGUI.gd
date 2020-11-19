extends CanvasLayer

onready var control_tooltips = [
	{
		"control": $PlayerBars/Health,
		"corner": "BC",
		"name": "Health",
		"description": "If this reaches 0, you die. Regenerates slowly after being out of combat for 5 seconds."
	},
	{
		"control": $PlayerBars/Energy,
		"corner": "BC",
		"name": "Lunar Energy",
		"description": "Energy powers most of your abilities. Regenerates steadily over time."
	},
	{
		"control": $Exhaustion,
		"corner": "BL",
		"name": "Exhaustion",
		"description": "Exhaustion increases slowly over time, when you die, and in response to certain events. Exhaustion slows down your health and energy regeneration."
	},
	{
		"control": $Statuses/Midnight,
		"corner": "TL",
		"name": "Midnight",
		"description": "It is midnight, when you are most powerful. Your damage and energy regeneration are increased."
	},
	{
		"control": $Statuses/ShrineDeath,
		"corner": "TL",
		"name": "Energized",
		"description": "Just before the moon shrine was corrupted, it released a burst of lunar energy. Your health and energy regen are increased, your speed is increased, and your exhaustion is falling."
	},
	{
		"control": $Statuses/Midday,
		"corner": "TL",
		"name": "Zenith",
		"description": "It is midday, when the enemy is most powerful. Their damage is increased."
	},
	{
		"control": $Statuses/Rage,
		"corner": "TL",
		"name": "AAARRG!",
		"description": "The enemy is filled with fiery rage. Their damage is greatly increased, but they also take more damage."
	},
	{
		"control": $Statuses/Fatigue,
		"corner": "TL",
		"name": "Curse of Fatigue",
		"description": "The enemy has cursed you with fatigue. Your movement speed and energy regeneration are reduced."
	},
	{
		"control": $Statuses/Confusion,
		"corner": "TL",
		"name": "Curse of Confusion",
		"description": "The enemy has cursed you with confusion. The world has turned upside-down."
	},
	{
		"control": $Statuses/FocusKeep,
		"corner": "TL",
		"name": "Destroy The Walls!",
		"description": "The enemy is currently focused on tearing down the walls, and will try to ignore players."
	},
	{
		"control": $Statuses/FocusPlayers,
		"corner": "TL",
		"name": "Slay Them!",
		"description": "The enemy is currently focused on killing players. Their damage is increased."
	}
]

var ability_bindings = [
	["L-Click", "X"],
	["R-Click", "A"],
	["Shift", "B"],
	["R", "Y"]
]

onready var chat_line = $Chat/ChatLine
onready var scroll = $Chat/ScrollContainer
onready var chat_container = $Chat/ScrollContainer/VBoxContainer
onready var chat_tween = $Chat/Tween
onready var overlay = $Overlay
onready var player_list = $Overlay/Container/PlayerListContainer/PlayerList
onready var map_container = $Overlay/Container/MapContainer
onready var map = $Overlay/Container/MapContainer/Map
onready var healthbar_anim = $PlayerBars/Health/AnimationPlayer

var chatting = false
var showing_tooltip = null

func _ready():
	scroll.get_v_scrollbar().modulate = Color.transparent
	chat_line.modulate = Color.transparent
	Game.connect("entered_level", self, "_on_entered_level")
	$Abilities.hide()
	$PlayerBars.hide()
	$Exhaustion.hide()
	$Respawn.hide()
	yield(get_tree(), "idle_frame")
	map.texture = owner.map.map_texture

func open_overlay():
	overlay.show()
	map.update()
	for c in player_list.get_children():
		c.queue_free()
	for p in owner.players_node.get_children():
		var e = R.PlayerListEntry.instance()
		e.get_node("Label").text = p.player_name
		player_list.add_child(e)
	
func close_overlay():
	overlay.hide()

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
	var entry = R.ChatEntry.instance()
	entry.parse_bbcode(message)
	chat_container.add_child(entry)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	scroll.scroll_vertical = chat_container.rect_size.y + 100
	if not chatting:
		chat_tween.interpolate_property(entry, "modulate", Color.white, Color.transparent, 2, Tween.TRANS_CUBIC, Tween.EASE_IN, 4)
		chat_tween.start()

func _unhandled_input(event):
	if event.is_action_pressed("chat") and not chatting:
		open_chat()
	elif event.is_action_pressed("ui_cancel"):
		if $Menu.visible:
			_on_Resume_pressed()
		elif chatting:
			close_chat()
		elif overlay.visible:
			close_overlay()
		else:
			$Menu.show()
			Game.lock_player_input = true
	elif event.is_action_pressed("overlay"):
		if overlay.visible:
			close_overlay()
		else:
			open_overlay()

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
		$Abilities/Attack1.texture_under = R.Icons.archer_attack1
		$Abilities/Attack1.texture_progress = $Abilities/Attack1.texture_under
		$Abilities/Attack2.texture_under = R.Icons.archer_attack2
		$Abilities/Attack2.texture_progress = $Abilities/Attack2.texture_under
		$Abilities/Movement.texture_under = R.Icons.archer_movement
		$Abilities/Movement.texture_progress = $Abilities/Movement.texture_under
		$Abilities/Ultimate.texture_under = R.Icons.archer_ultimate
		$Abilities/Ultimate.texture_progress = $Abilities/Ultimate.texture_under
	$Abilities.show()
	$PlayerBars.show()

func show_respawn():
	$Respawn.show()

func _on_RespawnButton_pressed():
	$Respawn.hide()
	Game.level.rpc("respawn")
	
func _process(delta):
	if Game.player != null:
		update_ui()
		if overlay.visible:
			update_map()

func update_ui():
	var cls = Game.player.player_class
	var binding = 1 if Game.using_controller else 0
	var i = 0

	$Statuses/Midnight.visible = Game.level.is_effect_active(Game.Effects.MIDNIGHT)
	$Statuses/Midday.visible = Game.level.is_effect_active(Game.Effects.MIDDAY)
	$Statuses/ShrineDeath.visible = Game.level.is_effect_active(Game.Effects.SHRINEDEATH)
	$Statuses/Rage.visible = Game.level.is_effect_active(Game.Effects.RAGE)
	$Statuses/Fatigue.visible = Game.level.is_effect_active(Game.Effects.FATIGUE)
	$Statuses/Confusion.visible = Game.level.is_effect_active(Game.Effects.CONFUSION)
	$Statuses/FocusKeep.visible = Game.level.is_effect_active(Game.Effects.FOCUS_KEEP)
	
	var pct = float(Game.player.health) / cls.MAX_HEALTH * 100
	$PlayerBars/Health.value = pct
	$PlayerBars/Health/Label.text = str(ceil(Game.player.health))
	if pct < 50:
		if not healthbar_anim.is_playing():
			healthbar_anim.play("health_warning")
		var s = 0.5
		if pct < 10:
			s = 3
		elif pct < 20:
			s = 2
		if pct < 35:
			s = 1
		if s != healthbar_anim.playback_speed:
			healthbar_anim.playback_speed = s
	else:
		if healthbar_anim.is_playing():
			healthbar_anim.stop()
	
	$PlayerBars/Energy.value = cls.energy
	$PlayerBars/Energy/Label.text = str(floor(cls.energy))
	$Exhaustion.value = Game.player.exhaustion
	$Exhaustion/Label.text = str(ceil(Game.player.exhaustion))
	if $Exhaustion.value > 0:
		$Exhaustion.show()

	i = 0
	for a in $Abilities.get_children():
		a.value = 1 - cls.call("get_" + a.name.to_lower() + "_cooldown")
		a.tint_progress = Color.cyan if a.value == 1 else Color.white
		var p = a.get_local_mouse_position()
		var s = a.rect_size
		if p.x > 0 and p.x < s.x and p.y > 0 and p.y < s.y:
			show_tooltip("A" + str(i), cls.ABILITIES[i], " (" + ability_bindings[i][binding] + ")")
			return
		i += 1

	i = 0
	for t in control_tooltips:
		var p = t.control.get_local_mouse_position()
		var s = t.control.rect_size
		if t.control.visible and p.x > 0 and p.x < s.x and p.y > 0 and p.y < s.y:
			show_tooltip("C" + str(i), t)
			return
		i += 1

	hide_tooltip()

func update_map():
	map.update()
	var center = map_container.rect_size / 2
	var player_pos = map.player_pixel * 3 + Vector2.ONE
	map.rect_position = center - player_pos

func show_tooltip(id, data, title_suffix = ""):
	var corner = "BR" if not "corner" in data else data.corner
	if showing_tooltip != id:
		showing_tooltip = id
		$Tooltip.show()
		$Tooltip/VBoxContainer/Title.text = data.name + title_suffix
		var desc = data.description
		if data.has("cost"):
			desc += "\n[color=yellow]Cost:[/color] " + data.cost
		if data.has("cooldown"):
			desc += "\n[color=yellow]Cooldown:[/color] " + data.cooldown
		$Tooltip/VBoxContainer/Description.parse_bbcode(desc)
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		$Tooltip.rect_size.y = $Tooltip/VBoxContainer/Description.get_content_height() + $Tooltip/VBoxContainer/Title.rect_size.y + 15
	if corner == "BR":
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position() - $Tooltip.rect_size
	elif corner == "BL":
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position() - Vector2(0, $Tooltip.rect_size.y)
	elif corner == "BC":
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position() - Vector2($Tooltip.rect_size.x / 2, $Tooltip.rect_size.y)
	elif corner == "TR":
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position() - Vector2($Tooltip.rect_size.x, 0)
	else:
		$Tooltip.rect_position = $Tooltip.get_global_mouse_position()

func hide_tooltip():
	$Tooltip.hide()
	showing_tooltip = null

func _on_Resume_pressed():
	Game.lock_player_input = false
	$Menu.hide()

func _on_Disconnect_pressed():
	Game.lock_player_input = false
	Game.leave_game()

func _on_Quit_pressed():
	get_tree().quit()




