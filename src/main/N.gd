extends Node

var rng := RandomNumberGenerator.new()

#640x360 40x22.5
#576x324 36x20.25
#512x288 32x18


func _ready():
	rng.randomize()

# *** UTIL *** #

func fct(obj, text, color, crit = false):
	var t = R.FCT.instance()
	obj.add_child(t)
	t.init(text, color, crit)

# *** RANDOM *** #

func rand_int(from, to):
	return rng.randi_range(from, to)
	
func rand_float(from, to):
	return rng.randf_range(from, to)

func rand_array(array):
	return array[rng.randi_range(0, array.size() - 1)]

func rand_weighted(options):
	var total_weight = 0
	for option in options:
		total_weight += options[option]
	var rand = rand_float(0, total_weight)
	for option in options:
		rand -= options[option]
		if rand < 0:
			return option
	return options.keys()[0]


# *** PHYSICS *** #

func raycast(node, from, to, mask, exclude = []):
	var space = node.get_world_2d().direct_space_state
	return space.intersect_ray(from, to, exclude, mask)

func get_overlapping_bodies(area: Area2D, group = "", mask = 0):
	var space = area.get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	query.collision_layer = area.collision_mask if mask == 0 else mask
	query.transform = area.global_transform
	query.transform.origin += area.get_child(0).position
	query.set_shape(area.get_child(0).shape)
	var results = space.intersect_shape(query)
	var bodies = []
	for r in results:
		if group == "" or r.collider.is_in_group(group):
			bodies.append(r.collider)
	return bodies

func get_overlapping_hitboxes(area: Area2D, group = ""):
	var space = area.get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	query.collide_with_bodies = false
	query.collide_with_areas = true
	query.collision_layer = area.collision_mask
	query.transform = area.global_transform
	query.set_shape(area.get_child(0).shape)
	var results = space.intersect_shape(query)
	var bodies = []
	for r in results:
		if group == "" or r.collider.owner.is_in_group(group):
			bodies.append(r.collider.owner)
	return bodies
	
