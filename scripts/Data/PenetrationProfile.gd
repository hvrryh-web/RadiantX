extends RefCounted
class_name PenetrationProfile

## Weapon penetration profile for wallbang mechanics

var can_penetrate: bool = false
var pen_power: float = 0.0  # Higher = better penetration
var damage_loss_per_unit: float = 0.1  # Damage lost per unit of penetration

func _init(data: Dictionary = {}):
	if data.has("canPenetrate"):
		can_penetrate = bool(data.canPenetrate)
	if data.has("penPower"):
		pen_power = float(data.penPower)
	if data.has("damageLossPerUnit"):
		damage_loss_per_unit = float(data.damageLossPerUnit)

func to_dict() -> Dictionary:
	return {
		"canPenetrate": can_penetrate,
		"penPower": pen_power,
		"damageLossPerUnit": damage_loss_per_unit
	}
