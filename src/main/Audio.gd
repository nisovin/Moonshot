extends Node

const SFX_CHANNELS = 30
const POSITIONAL_DROP_START = 300
const POSITIONAL_DROP_END = 600

const SFX = "SFX"
const PLAYER = "Self"
const OTHERS = "Others"
const ENEMIES = "Enemies"
const MAP = "Map"

onready var footsteps_player = $Footsteps
onready var music_layers = {
	"main": $MusicMain,
	"danger": $MusicDanger,
	"epic": $MusicEpic
}

var channels_avail = []
var loops = {}
var last_played = {}

func _ready():
	if Game.is_server(): return
	for i in SFX_CHANNELS:
		var a = AudioStreamPlayer.new()
		$SFX.add_child(a)
		channels_avail.append(a)
		a.connect("finished", self, "_on_sound_finished", [a])

func start_music():
	if Game.is_server(): return
	$MusicMain.stream = R.Sounds.music_main
	$MusicDanger.stream = R.Sounds.music_danger
	$MusicEpic.stream = R.Sounds.music_epic
	$MusicMain.volume_db = linear2db(0.1)
	$MusicDanger.volume_db = linear2db(0)
	$MusicEpic.volume_db = linear2db(0)
	$MusicMain.play(0)
	$MusicDanger.play(0)
	$MusicEpic.play(0)
	
func music_transition(type, volume = 50, time = 5):
	volume /= 500.0
	$Tween.remove(self, "volume_" + type)
	$Tween.interpolate_method(self, "volume_" + type, db2linear(music_layers[type].volume_db), volume, time)
	$Tween.start()

func volume_main(vol):
	$MusicMain.volume_db = linear2db(vol)
func volume_danger(vol):
	$MusicDanger.volume_db = linear2db(vol)
func volume_epic(vol):
	$MusicEpic.volume_db = linear2db(vol)

func play(sound_name, bus = SFX, volume = 1.0, avoid_overlap = 10):
	if Game.is_server(): return null
	if not sound_name in R.Sounds: return null
	if avoid_overlap > 0 and sound_name in last_played and last_played[sound_name] > OS.get_ticks_msec() - avoid_overlap: return null
	var channel: AudioStreamPlayer = channels_avail.pop_back()
	if channel != null:
		var s = R.Sounds[sound_name]
		var sound
		if typeof(s) == TYPE_ARRAY:
			sound = N.rand_array(R.Sounds[sound_name])
		else:
			sound = s
		channel.bus = bus
		channel.stream = sound
		channel.volume_db = linear2db(volume)
		channel.play()
		last_played[sound_name] = OS.get_ticks_msec()
	return channel

func play_at_position(position, sound_name, bus = SFX, min_volume = 0.0, volume = 1.0):
	if Game.is_server() or Game.player == null: return
	var dist = Game.player.position.distance_to(position)
	var vol = 0
	if dist < POSITIONAL_DROP_START:
		vol = 1
	elif dist > POSITIONAL_DROP_END:
		vol = min_volume
	else:
		vol = clamp((dist - POSITIONAL_DROP_START) / (POSITIONAL_DROP_END - POSITIONAL_DROP_START), min_volume, 1.0)
	if vol > 0:
		play(sound_name, bus, vol * volume, 0)
	

func loop(sound_name, bus = SFX, volume = 1.0):
	if Game.is_server(): return
	var ch = play(sound_name, bus, volume, 0)
	if ch != null:
		loops[sound_name] = ch
	
func stop_loop(sound_name):
	if Game.is_server(): return
	if sound_name in loops:
		loops[sound_name].stop()

func footsteps(type = null):
	if Game.is_server(): return
	if type == null:
		footsteps_player.stop()
	else:
		assert(type in R.Sounds)
		if R.Sounds[type] != footsteps_player.stream:
			footsteps_player.stream = R.Sounds[type]
			footsteps_player.play(0)
		elif not footsteps_player.playing:
			footsteps_player.play(0)

func _on_sound_finished(s):
	channels_avail.append(s)

func _on_MusicMain_finished():
	$MusicMain.play(0)
	$MusicDanger.play(0)
	$MusicEpic.play(0)
