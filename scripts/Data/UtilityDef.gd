extends RefCounted
class_name UtilityDef

## Utility/Ability definition
## Can be CS-like grenade or VAL-like ability

var id: String = ""
var family: int = DataTypes.UtilityFamily.CS_GRENADE
var cast_type: int = DataTypes.CastType.THROW_ARC
var equip_time: float = 0.4  # seconds
var cast_time: float = 0.15  # seconds
var max_charges: int = 1
var cooldown: float = 0.0  # VAL-like signature cooldowns
var credit_cost: int = 0  # Economy-based (VAL uses credits)
var throw_ballistics: ThrowBallistics = null
var projectile: ProjectileDef = null
var effects: Array[EffectSpec] = []

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = str(data.id)
	if data.has("family"):
		family = DataTypes.parse_utility_family(str(data.family))
	if data.has("castType"):
		cast_type = DataTypes.parse_cast_type(str(data.castType))
	if data.has("equipTime"):
		equip_time = float(data.equipTime)
	if data.has("castTime"):
		cast_time = float(data.castTime)
	if data.has("maxCharges"):
		max_charges = int(data.maxCharges)
	if data.has("cooldown"):
		cooldown = float(data.cooldown)
	if data.has("creditCost"):
		credit_cost = int(data.creditCost)
	if data.has("throw") and data["throw"] is Dictionary:
		throw_ballistics = ThrowBallistics.new(data["throw"])
	if data.has("projectile") and data.projectile is Dictionary:
		projectile = ProjectileDef.new(data.projectile)
	if data.has("effects") and data.effects is Array:
		for effect_data in data.effects:
			if effect_data is Dictionary:
				effects.append(EffectSpec.new(effect_data))

func is_grenade() -> bool:
	return family == DataTypes.UtilityFamily.CS_GRENADE

func is_ability() -> bool:
	return family == DataTypes.UtilityFamily.VAL_ABILITY

func to_dict() -> Dictionary:
	var effects_arr = []
	for effect in effects:
		effects_arr.append(effect.to_dict())
	
	var result = {
		"id": id,
		"family": "CS_Grenade" if family == DataTypes.UtilityFamily.CS_GRENADE else "VAL_Ability",
		"castType": _cast_type_to_string(cast_type),
		"equipTime": equip_time,
		"castTime": cast_time,
		"maxCharges": max_charges,
		"cooldown": cooldown,
		"creditCost": credit_cost,
		"effects": effects_arr
	}
	
	if throw_ballistics:
		result["throw"] = throw_ballistics.to_dict()
	if projectile:
		result["projectile"] = projectile.to_dict()
	
	return result

func _cast_type_to_string(ct: int) -> String:
	match ct:
		DataTypes.CastType.THROW_ARC: return "ThrowArc"
		DataTypes.CastType.FIRE_PROJECTILE: return "FireProjectile"
		DataTypes.CastType.INSTANT_AOE: return "InstantAOE"
		DataTypes.CastType.PLACE_MARKER: return "PlaceMarker"
		DataTypes.CastType.BEAM: return "Beam"
		DataTypes.CastType.SELF: return "Self"
		_: return "ThrowArc"
