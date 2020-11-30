extends Node

var MultiplayerController
var Level
var FCT

var Player
var Enemy
var EnemyGrunt
var EnemyMage
var EnemyElite
var EnemyPhoenix
var EnemyBomber
var EnemySiege

var CrescentArrow
var Volley
var Moonshot

var Fireball
var Boulder

var MainMenu
var JoinGameMenu
var ChatEntry
var PlayerListEntry
var Sounds
var Icons

func load_resources(is_server):
	MultiplayerController = load("res://main/MultiplayerController.tscn")
	Level = load("res://main/Level.tscn")
	FCT = load("res://misc/FCT.tscn")
	Player = load("res://player/Player.tscn")
	Enemy = load("res://enemies/Enemy.tscn")
	EnemyGrunt = load("res://enemies/EnemyGrunt.tscn")
	EnemyMage = load("res://enemies/EnemyMage.tscn")
	EnemyElite = load("res://enemies/EnemyElite.tscn")
	EnemyPhoenix = load("res://enemies/EnemyPhoenix.tscn")
	EnemyBomber = load("res://enemies/EnemyBomber.tscn")
	EnemySiege = load("res://enemies/EnemySiege.tscn")
	
	CrescentArrow = load("res://player/Arrow.tscn")
	Volley = load("res://player/Volley.tscn")
	Moonshot = load("res://player/Moonshot.tscn")
	
	Fireball = load("res://enemies/Fireball.tscn")
	Boulder = load("res://enemies/Boulder.tscn")
	
	if not is_server:
		
		MainMenu = load("res://main/MainMenu.tscn")
		JoinGameMenu = load("res://gui/JoinGameMenu.tscn")
		ChatEntry = load("res://gui/ChatEntry.tscn")
		PlayerListEntry = load("res://gui/PlayerListEntry.tscn")
		
		Sounds = {
			"music_main": load("res://music/track_main.ogg"),
			"music_danger": load("res://music/track_choir.ogg"),
			"music_epic": load("res://music/track_strings.ogg"),
			"music_loss": load("res://music/left_behind.ogg"),
			"teleport": load("res://sfx/teleport.wav"),
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
				load("res://sfx/player_hit.wav")
			],
			"grunt_die": load("res://sfx/grunt_die.ogg"),
			"mage_fireball": load("res://sfx/mage_fireball.wav"),
			"mage_die": load("res://sfx/mage_die.ogg"),
			"siege_throw": load("res://sfx/siege_throw.wav"),
			"siege_impact": load("res://sfx/siege_impact.wav"),
			"bomber_spawn": load("res://sfx/bomber_spawn.ogg"),
			"bomber_ignite": load("res://sfx/bomber_ignite.wav"),
			"bomber_explode": load("res://sfx/explode.wav"),
			"wall_break": load("res://sfx/wall_break.wav"),
			"wall_destroyed": load("res://sfx/wall_destroyed.wav"),
			"gem_break": load("res://sfx/gem_break.ogg")
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
