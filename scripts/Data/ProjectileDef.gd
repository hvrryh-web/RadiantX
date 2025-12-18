extends RefCounted
class_name ProjectileDef

## Projectile definition for fired projectiles (not thrown)

var speed: float = 22.0
var gravity: float = 9.81
var max_life: float = 2.0  # seconds
var bounces: bool = false
var bounce_damp: float = 0.0  # velocity retention on bounce

func _init(data: Dictionary = {}):
	if data.has("speed"):
		speed = float(data.speed)
	if data.has("gravity"):
		gravity = float(data.gravity)
	if data.has("maxLife"):
		max_life = float(data.maxLife)
	if data.has("bounces"):
		bounces = bool(data.bounces)
	if data.has("bounceDamp"):
		bounce_damp = float(data.bounceDamp)

func to_dict() -> Dictionary:
	return {
		"speed": speed,
		"gravity": gravity,
		"maxLife": max_life,
		"bounces": bounces,
		"bounceDamp": bounce_damp
	}
