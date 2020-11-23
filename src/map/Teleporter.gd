tool
extends Area2D

export (Vector2) var target = Vector2.UP * 64 setget set_target

onready var label = $Z/Label

var cooldown_until = 0

func _ready():
	$Sprite.rotation = target.angle()
	$Sprite/Particles2D.lifetime = target.length() / 32
	label.hide()
	if not Engine.editor_hint and Game.is_server():
		$CollisionShape2D.disabled = true
		monitoring = false

func set_target(val):
	target = val
	if Engine.editor_hint:
		$Sprite.rotation = target.angle()
		$Sprite/Particles2D.lifetime = target.length() / 32
		update()

func interact(body):
	if overlaps_body(body) and cooldown_until < OS.get_ticks_msec():
		body.teleport(position + target)
		Audio.play("teleport", Audio.MAP)
		cooldown_until = OS.get_ticks_msec() + 3000

func _on_Teleporter_body_entered(body):
	if body.is_network_master():
		body.interact_with = self
		label.show()

func _on_Teleporter_body_exited(body):
	if body.is_network_master():
		label.hide()
		if body.interact_with == self:
			body.interact_with = null
		
func _draw():
	if Engine.editor_hint:
		draw_line(Vector2.ZERO, target, Color.cyan, 2)
		draw_circle(target, 4, Color.blue)
	
	


