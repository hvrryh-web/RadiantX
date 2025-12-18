extends RefCounted
class_name RulesetDef

## Ruleset definition that configures game rules
## Can be CS-like (grenades, carry weight) or VAL-like (abilities, economy)

var id: String = ""
var utility_family: int = DataTypes.UtilityFamily.CS_GRENADE
var max_carry_weight: float = 0.0
var max_grenades: int = 4
var uses_ability_economy: bool = false

func _init(data: Dictionary = {}):
	if data.has("id"):
		id = str(data.id)
	if data.has("utilityFamily"):
		utility_family = DataTypes.parse_utility_family(str(data.utilityFamily))
	if data.has("maxCarryWeight"):
		max_carry_weight = float(data.maxCarryWeight)
	if data.has("maxGrenades"):
		max_grenades = int(data.maxGrenades)
	if data.has("usesAbilityEconomy"):
		uses_ability_economy = bool(data.usesAbilityEconomy)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"utilityFamily": "CS_Grenade" if utility_family == DataTypes.UtilityFamily.CS_GRENADE else "VAL_Ability",
		"maxCarryWeight": max_carry_weight,
		"maxGrenades": max_grenades,
		"usesAbilityEconomy": uses_ability_economy
	}
