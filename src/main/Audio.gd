extends Node

const SFX_CHANNELS = 30

onready var footsteps_player = $Footsteps

var channels_avail = []
var loops = {}

func _ready():
	if Game.is_server(): return
	for i in SFX_CHANNELS:
		var a = AudioStreamPlayer.new()
		$SFX.add_child(a)
		channels_avail.append(a)
		a.connect("finished", self, "_on_sound_finished", [a])

func start_music():
	$MusicMain.stream = R.Sounds.music_main
	$MusicDay.stream = R.Sounds.music_day
	$MusicNight.stream = R.Sounds.music_night
	$MusicMain.volume_db = linear2db(0.1)
	$MusicDay.volume_db = linear2db(0)
	$MusicNight.volume_db = linear2db(0)
	$MusicMain.play(0)
	$MusicDay.play(0)
	$MusicNight.play(0)
	
func music_time_update(time):
	if time == "dawn":
		$Tween.interpolate_method(self, "_day_volume", 0, 0.2, 20, Tween.TRANS_LINEAR)
		$Tween.interpolate_method(self, "_night_volume", db2linear($MusicNight.volume_db), 0, 20, Tween.TRANS_LINEAR)
		$Tween.start()
	elif time == "dusk":
		$Tween.interpolate_method(self, "_night_volume", 0, 0.2, 20, Tween.TRANS_LINEAR)
		$Tween.interpolate_method(self, "_day_volume", db2linear($MusicDay.volume_db), 0, 20, Tween.TRANS_LINEAR)
		$Tween.start()

func _day_volume(vol):
	$MusicDay.volume_db = linear2db(vol)
func _night_volume(vol):
	$MusicNight.volume_db = linear2db(vol)

func play(sound_name, volume = 1.0):
	if Game.is_server(): return null
	assert(sound_name in R.Sounds)
	var channel: AudioStreamPlayer = channels_avail.pop_back()
	if channel != null:
		var s = R.Sounds[sound_name]
		var sound
		if typeof(s) == TYPE_ARRAY:
			sound = N.rand_array(R.Sounds[sound_name])
		else:
			sound = s
		if typeof(sound) == TYPE_STRING:
			sound = load(sound)
		channel.stream = sound
		channel.volume_db = linear2db(volume)
		channel.play()
	return channel
		
func loop(sound_name, volume = 1.0):
	if Game.is_server(): return
	var ch = play(sound_name, volume)
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
