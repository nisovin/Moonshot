extends Panel

onready var volume_master = find_node("VolumeMasterSlider")
onready var volume_music = find_node("VolumeMusicSlider")
onready var volume_sfx = find_node("VolumeSFXSlider")
onready var volume_player = find_node("VolumePlayerSlider")
onready var volume_enemies = find_node("VolumeEnemiesSlider")
onready var volume_map = find_node("VolumeMapSlider")

onready var fct_player = find_node("FCTPlayer")
onready var fct_enemies = find_node("FCTEnemies")

func open():
	volume_master.value = Settings.volume_master
	volume_music.value = Settings.volume_music
	volume_sfx.value = Settings.volume_sfx
	volume_player.value = Settings.volume_player
	volume_enemies.value = Settings.volume_enemies
	volume_map.value = Settings.volume_map
	fct_player.pressed = Settings.gameplay_fct_self
	fct_enemies.pressed = Settings.gameplay_fct_enemies
	show()

func save():
	Settings.volume_master = volume_master.value
	Settings.volume_music = volume_music.value
	Settings.volume_sfx = volume_sfx.value
	Settings.volume_player = volume_player.value
	Settings.volume_enemies = volume_enemies.value
	Settings.volume_map = volume_map.value
	Settings.gameplay_fct_self = fct_player.pressed
	Settings.gameplay_fct_enemies = fct_enemies.pressed
	Settings.save_settings()
	Audio.update_bus_volumes()
	hide()
	
func _on_VolumeMasterSlider_value_changed(value):
	Audio.update_bus_volume(Audio.MASTER, value)

func _on_VolumeMusicSlider_value_changed(value):
	Audio.update_bus_volume(Audio.MUSIC, value)

func _on_VolumeSFXSlider_value_changed(value):
	Audio.update_bus_volume(Audio.SFX, value)

func _on_VolumePlayerSlider_value_changed(value):
	Audio.update_bus_volume(Audio.PLAYER, value)

func _on_VolumeEnemiesSlider_value_changed(value):
	Audio.update_bus_volume(Audio.ENEMIES, value)

func _on_VolumeMapSlider_value_changed(value):
	Audio.update_bus_volume(Audio.MAP, value)

func _on_Save_pressed():
	save()

func _on_Cancel_pressed():
	Audio.update_bus_volumes()
	hide()
