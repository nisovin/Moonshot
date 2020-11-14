extends Node

var Level

var Player
var Enemy

var CrescentArrow
var Volley
var Moonshot

var Fireball

var MainMenu
var JoinGameMenu
var ChatEntry
var PlayerListEntry
var Sounds
var Icons

func load_resources(is_server):
	Level = load("res://main/Level.tscn")
	Player = load("res://player/Player.tscn")
	Enemy = load("res://enemies/Enemy.tscn")
	
	CrescentArrow = load("res://player/Arrow.tscn")
	Volley = load("res://player/Volley.tscn")
	Moonshot = load("res://player/Moonshot.tscn")
	
	Fireball = load("res://enemies/Fireball.tscn")
	
	if not is_server:
		
		MainMenu = load("res://main/MainMenu.tscn")
		JoinGameMenu = load("res://gui/JoinGameMenu.tscn")
		ChatEntry = load("res://gui/ChatEntry.tscn")
		PlayerListEntry = load("res://gui/PlayerListEntry.tscn")
		
		Sounds = {
			"music_main": load("res://music/track_main.ogg"),
			"music_day": load("res://music/track_choir.ogg"),
			"music_night": load("res://music/track_strings.ogg"),
			"warrior_attack1_swing": [
				load("res://sfx/warrior_attack1_1.wav"),
				load("res://sfx/warrior_attack1_2.wav"),
				load("res://sfx/warrior_attack1_3.wav")
			],
			"warrior_attack2": load("res://sfx/warrior_attack2.wav"),
			"warrior_movement": load("res://sfx/warrior_movement.wav"),
			"warrior_ultimate": load("res://sfx/warrior_ultimate.wav"),
			"archer_attack1_draw": load("res://sfx/archer_attack1_draw.wav"),
			"archer_attack1_fire": load("res://sfx/archer_attack1_fire.wav"),
			"archer_attack2": load("res://sfx/archer_attack2.wav"),
			"archer_movement": load("res://sfx/archer_movement.wav"),
			"archer_ultimate_loop": load("res://sfx/archer_ultimate_loop.ogg"),
			"enemy_hit": [
				load("res://sfx/enemy_hit_3.ogg"),
				load("res://sfx/enemy_hit_4.ogg")
			],
			"hit": [
				load("res://sfx/hit1.ogg"),
				load("res://sfx/hit2.ogg"),
				load("res://sfx/hit3.ogg"),
				load("res://sfx/hit4.ogg"),
				load("res://sfx/hit5.ogg")
			]
		}
		
		Icons = {
			"warrior_attack1": load("res://gui/icons/warrior_attack1.png"),
			"warrior_attack2": load("res://gui/icons/warrior_attack2.png"),
			"warrior_movement": load("res://gui/icons/warrior_movement.png"),
			"warrior_ultimate": load("res://gui/icons/warrior_ultimate.png"),
			"archer_attack1": load("res://gui/icons/archer_attack1.png"),
			"archer_attack2": load("res://gui/icons/archer_attack2.png"),
			"archer_movement": load("res://gui/icons/archer_movement.png"),
			"archer_ultimate": load("res://gui/icons/archer_ultimate.png")
		}
