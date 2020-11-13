tool
extends Area2D

export (Vector2) var target = Vector2.UP * 64 setget set_target

func set_target(val):
	target = val
	if Engine.editor_hint:
		update()

func interact(body):
	if overlaps_body(body):
		body.teleport(position + target)

func _on_Teleporter_body_entered(body):
	if body.is_network_master():
		body.interact_with = self
		$Label.show()

func _on_Teleporter_body_exited(body):
	if body.is_network_master():
		$Label.hide()
		if body.interact_with == self:
			body.interact_with = null
		
func _draw():
	if Engine.editor_hint:
		draw_line(Vector2.ZERO, target, Color.cyan, 2)
		draw_circle(target, 4, Color.blue)
	
	


