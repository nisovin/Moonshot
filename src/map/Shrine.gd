extends Area2D

signal became_untargetable
signal destroyed

export (NodePath) var doodad = null
export (int) var max_health = 500
var health
var heal_max
var health_stones = 0
var targeted_by_count = 0
var time_since_corruption = 0
var active = false
var dead = false

onready var corruption_area = $CorruptionArea
onready var heal_area = $HealArea

func _ready():
	health = max_health
	heal_max = max_health
	health_stones = $HealthDisplay.get_child_count()
	
#	var noise = OpenSimplexNoise.new()
#
#	noise.seed = N.rng.randi()
#	noise.period = 1
#	$Sprite.texture = ImageTexture.new()
#	$Sprite.texture.create_from_image(noise.get_seamless_image(64), 0)
#
#	noise.seed = N.rng.randi()
#	noise.lacunarity = 6.0
#	noise.period = 1
#	$Sprite2.texture = ImageTexture.new()
#	$Sprite2.texture.create_from_image(noise.get_seamless_image(64), 0)
#
#	$Pool.material.set_shader_param("color_offset", $Sprite.texture)
#	$Pool.material.set_shader_param("time_offset", $Sprite2.texture)

func set_time(time):
	if health > 0:
		if time == "dusk":
			#$Tween.interpolate_property($Pool, "modulate", $Pool.modulate, Color.white, 20)
			$Tween.interpolate_property($Sun, "modulate", $Sun.modulate, Color.transparent, 20)
			$Tween.interpolate_property($Moon, "modulate", $Moon.modulate, Color.white, 20)
			$Tween.start()
		elif time == "midnight" and not dead:
			$MidnightParticles.emitting = true
		elif time == "latenight":
			$MidnightParticles.emitting = false
		elif time == "dawn":
			#$Tween.interpolate_property($Pool, "modulate", $Pool.modulate, Color(1.2, 1.2, 1), 20)
			$Tween.interpolate_property($Sun, "modulate", $Sun.modulate, Color.white, 20)
			$Tween.interpolate_property($Moon, "modulate", $Moon.modulate, Color.transparent, 20)
			$Tween.start()

func apply_damage(dam):
	if not active or dead: return
	health -= dam
	heal_max -= dam / 2.0
	var stones = ceil(float(health) / max_health * $HealthDisplay.get_child_count())
	if stones != health_stones:
		rpc("update_health_display", stones)
	if health <= 0:
		dead = true
		rpc("die")
		emit_signal("became_untargetable", self)
		emit_signal("destroyed")

remotesync func update_health_display(stones):
	health_stones = stones
	for i in $HealthDisplay.get_child_count():
		var s = $HealthDisplay.get_child(i)
		s.modulate = Color.aqua if i < health_stones else Color.darkcyan
	Audio.play("gem_break", Audio.MAP)

remotesync func die():
	print("Shrine died")
	$Tween.stop_all()
	$Tween.interpolate_property($Moon, "modulate", $Moon.modulate, Color.transparent, 10)
	$Tween.interpolate_property($Pool, "modulate", $Pool.modulate, Color(0.7, 0.4, 0.4), 10)
	$Tween.interpolate_property($Particles, "modulate", Color.white, Color.red, 10)
	$Tween.start()
	$MidnightParticles.emitting = false
	$DeathParticles.emitting = true
	if doodad:
		var doodad_node = get_node(doodad)
		if doodad_node:
			doodad_node.die()

func _physics_process(delta):
	if Game.player != null:
		var vector = Game.player.position - position + Vector2(0, 100)
		var dist = vector.length()
		if dist < 350:
			$Moon.visible = true
			#$Sun.visible = true
			$Moon.position = vector / 4
			#$Sun.position = vector / 4
			return
	$Moon.visible = false
	#$Sun.visible = false

func _on_Timer_timeout():
	if not dead and Game.is_host():
		var enemies = corruption_area.get_overlapping_bodies()
		if active:
			if enemies.size() > 0:
				apply_damage(enemies.size())
				time_since_corruption = 0
			else:
				time_since_corruption += 1
				if time_since_corruption > 15:
					health = clamp(health + 1, 0, ceil(heal_max))
		else:
			for enemy in enemies:
				enemy.hit({"damage": 100})
		if enemies.size() == 0:
			for p in heal_area.get_overlapping_bodies():
				p.apply_healing(10 if Game.level.is_effect_active(Game.Effects.MIDNIGHT) else 5)
