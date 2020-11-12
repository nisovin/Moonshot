extends Node

const SFX_CHANNELS = 30

const SOUNDS = {
	"warrior_attack1_swing": [
		preload("res://sfx/warrior_attack1_1.wav"),
		preload("res://sfx/warrior_attack1_2.wav"),
		preload("res://sfx/warrior_attack1_3.wav")
	],
	"warrior_attack2": preload("res://sfx/warrior_attack2.wav"),
	"warrior_movement": preload("res://sfx/warrior_movement.wav"),
	"warrior_ultimate": preload("res://sfx/warrior_ultimate.wav"),
	"archer_attack1_draw": preload("res://sfx/archer_attack1_draw.wav"),
	"archer_attack1_fire": preload("res://sfx/archer_attack1_fire.wav"),
	"archer_attack2": preload("res://sfx/archer_attack2.wav"),
	"archer_movement": preload("res://sfx/archer_movement.wav"),
	"archer_ultimate_loop": preload("res://sfx/archer_ultimate_loop.ogg")
}

onready var footsteps_player = $Footsteps

var channels_avail = []
var loops = {}

func _ready():
	for i in SFX_CHANNELS:
		var a = AudioStreamPlayer.new()
		$SFX.add_child(a)
		channels_avail.append(a)
		a.connect("finished", self, "_on_sound_finished", [a])
		
func play(sound_name, volume = 1.0):
	assert(sound_name in SOUNDS)
	var channel: AudioStreamPlayer = channels_avail.pop_back()
	if channel != null:
		var s = SOUNDS[sound_name]
		var sound
		if typeof(s) == TYPE_ARRAY:
			sound = N.rand_array(SOUNDS[sound_name])
		else:
			sound = s
		if typeof(sound) == TYPE_STRING:
			sound = load(sound)
		channel.stream = sound
		channel.volume_db = linear2db(volume)
		channel.play()
	return channel
		
func loop(sound_name, volume = 1.0):
	var ch = play(sound_name, volume)
	loops[sound_name] = ch
	
func stop_loop(sound_name):
	if sound_name in loops:
		loops[sound_name].stop()

func footsteps(type = null):
	if type == null:
		footsteps_player.stop()
	else:
		assert(type in SOUNDS)
		if SOUNDS[type] != footsteps_player.stream:
			footsteps_player.stream = SOUNDS[type]
			footsteps_player.play(0)
		elif not footsteps_player.playing:
			footsteps_player.play(0)

func _on_sound_finished(s):
	channels_avail.append(s)
