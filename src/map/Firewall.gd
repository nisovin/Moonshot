extends Node2D

onready var visual = $Visual
onready var killzone = $KillZone

func _ready():
	yield(get_tree(), "idle_frame")
	if Game.is_host():
		$Timer.start()

func _physics_process(delta):
	if Game.player != null:
		visual.global_position.x = stepify(Game.player.position.x, Game.TILE_SIZE)

func _on_Timer_timeout():
	for p in N.get_overlapping_bodies(killzone):
		var dam = 10
		if p.position.y < position.y - 160:
			dam *= 2
		if p.position.y < position.y - 320:
			dam *= 2
		p.apply_damage(dam, true, 5)
