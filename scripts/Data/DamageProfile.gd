extends RefCounted
class_name DamageProfile

## Weapon damage profile with range falloff

var base_damage: float = 30.0
var head_mult: float = 4.0
var leg_mult: float = 0.75
var range_multiplier: AnimCurve = null  # distance -> scalar

func _init(data: Dictionary = {}):
	range_multiplier = AnimCurve.new()
	
	if data.has("baseDamage"):
		base_damage = float(data.baseDamage)
	if data.has("headMult"):
		head_mult = float(data.headMult)
	if data.has("legMult"):
		leg_mult = float(data.legMult)
	if data.has("rangeMultiplierKeys") and data.rangeMultiplierKeys is Array:
		range_multiplier = AnimCurve.from_array(data.rangeMultiplierKeys)

func get_damage_for_zone(zone: int, distance: float) -> float:
	##Calculate damage for a hit zone at a given distance##
	var range_mult = range_multiplier.evaluate(distance)
	var zone_mult = 1.0
	
	match zone:
		DataTypes.HitZone.HEAD:
			zone_mult = head_mult
		DataTypes.HitZone.TORSO:
			zone_mult = 1.0
		DataTypes.HitZone.LEGS:
			zone_mult = leg_mult
	
	return base_damage * range_mult * zone_mult

func to_dict() -> Dictionary:
	var keys = []
	for key in range_multiplier.keys:
		keys.append({"x": key.x, "y": key.y})
	return {
		"baseDamage": base_damage,
		"headMult": head_mult,
		"legMult": leg_mult,
		"rangeMultiplierKeys": keys
	}
