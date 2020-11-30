extends Node

const SFX_CHANNELS = 30
const POSITIONAL_DROP_START = 300
const POSITIONAL_DROP_END = 600

const MASTER = "Master"
const MUSIC = "Music"
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
var no_music_loop = false

func _ready():
	if Game.is_server(): return
	for i in SFX_CHANNELS:
		var a = AudioStreamPlayer.new()
		$SFX.add_child(a)
		channels_avail.append(a)
		a.connect("finished", self, "_on_sound_finished", [a])

func update_bus_volumes():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(Settings.volume_master))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(Settings.volume_music))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(Settings.volume_sfx))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Self"), linear2db(Settings.volume_player))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Others"), linear2db(Settings.volume_others))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Enemies"), linear2db(Settings.volume_enemies))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Map"), linear2db(Settings.volume_map))

func update_bus_volume(bus, volume):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear2db(volume))

func start_music():
	if Game.is_server(): return
	$MusicLoss.stop()
	$MusicMain.stream = R.Sounds.music_main
	$MusicDanger.stream = R.Sounds.music_danger
	$MusicEpic.stream = R.Sounds.music_epic
	$MusicLoss.stream = R.Sounds.music_loss
	$MusicMain.volume_db = linear2db(0.1)
	$MusicDanger.volume_db = linear2db(0)
	$MusicEpic.volume_db = linear2db(0)
	$MusicMain.play(0)
	$MusicDanger.play(0)
	$MusicEpic.play(0)
	
func stop_music():
	if Game.is_server(): return
	no_music_loop = true
	$MusicMain.stop()
	$MusicDanger.stop()
	$MusicEpic.stop()
	$MusicLoss.stop()
	yield(get_tree().create_timer(0.5), "timeout")
	no_music_loop = false

func start_loss_music():
	if Game.is_server(): return
	$Tween.remove(self, "volume_main")
	$Tween.remove(self, "volume_danger")
	$Tween.remove(self, "volume_epic")
	$MusicLoss.play()
	$Tween.interpolate_method(self, "volume_main", db2linear($MusicMain.volume_db), 0, 2.5)
	$Tween.interpolate_method(self, "volume_danger", db2linear($MusicDanger.volume_db), 0, 2.5)
	$Tween.interpolate_method(self, "volume_epic", db2linear($MusicEpic.volume_db), 0, 2.5)
	$Tween.interpolate_method(self, "volume_loss", 0, 1.0, 2.5)
	$Tween.start()
	yield(get_tree().create_timer(1.5), "timeout")
	$MusicMain.stop()
	$MusicDanger.stop()
	$MusicEpic.stop()
	
func music_transition(type, volume = 50, time = 5):
	if $MusicLoss.playing: return
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
func volume_loss(vol):
	$MusicLoss.volume_db = linear2db(vol)

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

func play_at_position(position, sound_name, bus = SFX, min_volume = 0.0, volume = 1.0, avoid_overlap = 0):
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
		play(sound_name, bus, vol * volume, avoid_overlap)
	

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
	if no_music_loop:
		no_music_loop = false
		return
	$MusicMain.play(0)
	$MusicDanger.play(0)
	$MusicEpic.play(0)
