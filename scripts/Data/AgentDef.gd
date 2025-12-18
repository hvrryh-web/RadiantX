extends RefCounted
class_name AgentDef

## Agent definition with base stats and loadout
## Runtime state is separate (see AgentState)

var id: String = ""
var display_name: String = ""
var base_hp: float = 100.0
var base_armor: float = 0.0
var traits: TraitBlock = null
var loadout_weapon_ids: Array[String] = []
var loadout_utility_ids: Array[String] = []  # grenades or abilities

func _init(data: Dictionary = {}):
	traits = TraitBlock.new()
	
	if data.has("id"):
		id = str(data.id)
	if data.has("displayName"):
		display_name = str(data.displayName)
	if data.has("baseHp"):
		base_hp = float(data.baseHp)
	if data.has("baseArmor"):
		base_armor = float(data.baseArmor)
	if data.has("traits") and data.traits is Dictionary:
		traits = TraitBlock.new(data.traits)
	if data.has("loadoutWeaponIds") and data.loadoutWeaponIds is Array:
		for weapon_id in data.loadoutWeaponIds:
			loadout_weapon_ids.append(str(weapon_id))
	if data.has("loadoutUtilityIds") and data.loadoutUtilityIds is Array:
		for util_id in data.loadoutUtilityIds:
			loadout_utility_ids.append(str(util_id))

func to_dict() -> Dictionary:
	return {
		"id": id,
		"displayName": display_name,
		"baseHp": base_hp,
		"baseArmor": base_armor,
		"traits": traits.to_dict() if traits else {},
		"loadoutWeaponIds": loadout_weapon_ids,
		"loadoutUtilityIds": loadout_utility_ids
	}
