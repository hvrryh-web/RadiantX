extends RefCounted
class_name AnimCurve

## Simple animation curve for JSON-friendly interpolation
## Used for damage range falloff, spread patterns, etc.

var keys: Array[Dictionary] = []  # Array of {x: float, y: float}

func _init(key_data: Array = []):
	for key in key_data:
		if key is Dictionary and key.has("x") and key.has("y"):
			keys.append({"x": float(key.x), "y": float(key.y)})

func evaluate(x: float) -> float:
	"""Linear interpolate between keys to get value at x"""
	if keys.is_empty():
		return 1.0
	
	if keys.size() == 1:
		return keys[0].y
	
	# Before first key
	if x <= keys[0].x:
		return keys[0].y
	
	# After last key
	if x >= keys[keys.size() - 1].x:
		return keys[keys.size() - 1].y
	
	# Find surrounding keys and interpolate
	for i in range(keys.size() - 1):
		var k0 = keys[i]
		var k1 = keys[i + 1]
		if x >= k0.x and x <= k1.x:
			var t = (x - k0.x) / (k1.x - k0.x)
			return lerpf(k0.y, k1.y, t)
	
	return 1.0

static func from_array(arr: Array) -> AnimCurve:
	"""Create curve from array of {x, y} dictionaries"""
	return AnimCurve.new(arr)
