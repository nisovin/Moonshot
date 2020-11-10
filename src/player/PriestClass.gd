extends Node2D

enum PriestState { NORMAL }

const SERIALIZE_FIELDS = [ "state", "ultimate_duration" ]

var state = PriestState.NORMAL

func get_data():
	var data = {}
	for field in SERIALIZE_FIELDS:
		data[field] = get(field)
	return data

func load_data(data):
	if Game.mp_mode == Game.MPMode.SERVER:
		set_physics_process(false)
	if data != null:
		for field in SERIALIZE_FIELDS:
			if field in data:
				set(field, data[field])

func is_moving():
	return false

func attack1_press():
	pass
	
func attack1_release():
	pass
	
func attack2_press():
	pass
	
func attack2_release():
	pass
	
func movement_press():
	pass
	
func movement_release():
	pass
	
func ultimate_press():
	pass
	
func ultimate_release():
	pass

func get_attack1_cooldown():
	return 0
	
func get_attack2_cooldown():
	return 0
	
func get_movement_cooldown():
	return 0
	
func get_ultimate_cooldown():
	return 0
