extends StaticBody2D

func _ready():
	$AnimationPlayer.play("hover")

func die():
	$Tween.interpolate_property($Moon, "modulate", Color(1, 1, 1, 0.75), Color(1, 0.35, 0, 0.75), 3)
	$Tween.start()
