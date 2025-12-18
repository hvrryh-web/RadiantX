extends RefCounted
class_name ThrowBallistics

## Throw ballistics for grenades and throwable utilities

var speed: float = 18.0
var gravity: float = 9.81
var fuse_time: float = 1.5  # seconds
var detonate_on_rest: bool = true

func _init(data: Dictionary = {}):
	if data.has("speed"):
		speed = float(data.speed)
	if data.has("gravity"):
		gravity = float(data.gravity)
	if data.has("fuseTime"):
		fuse_time = float(data.fuseTime)
	if data.has("detonateOnRest"):
		detonate_on_rest = bool(data.detonateOnRest)

func to_dict() -> Dictionary:
	return {
		"speed": speed,
		"gravity": gravity,
		"fuseTime": fuse_time,
		"detonateOnRest": detonate_on_rest
	}
