extends Node2D

func init(text, color, crit = false):
	var label = $Float/Label
	var floater = $Float
	var tween = $Tween
	position = Vector2(0, -16)
	if typeof(text) == TYPE_REAL:
		var rounded = round(text * 10) / 10.0
		label.text = str(rounded)
	else:
		label.text = str(text)
	label.set("custom_colors/font_color", color)
	var y = -N.rand_float(16, 32)
	var x = N.rand_float(-24, 24)
	
	tween.interpolate_property(floater, "position:x", 0, x, 1)
	tween.interpolate_property(floater, "position:y", 0, y, 1, Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.interpolate_property(floater, "modulate", floater.modulate, Color.transparent, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN, 0.5)
	if crit:
		tween.interpolate_property(label, "rect_scale", Vector2(1, 1), Vector2(2, 2), 0.1)
		tween.interpolate_property(label, "rect_scale", Vector2(2, 2), Vector2(1, 1), 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.5)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
