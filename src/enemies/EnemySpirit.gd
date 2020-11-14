extends EnemyType

const MAX_DISTANCE_SQ = 16 * 8 * 16 * 8
const MAX_TIME = 15 * 1000

var enemy
var controller
var spawned

func init_sub(node):
	enemy = node
	controller = enemy.controller
	spawned = OS.get_ticks_msec()

func find_target(players, walls):
	var dsq = controller.target.position.distance_squared_to(enemy.position)
	if controller.target == null or dsq > MAX_DISTANCE_SQ or OS.get_ticks_msec() > spawned + MAX_TIME:
		controller.remove_target()
		enemy.rpc("die")
	
func get_velocity():
	return enemy.position.direction_to(controller.target.position) * movement_speed
