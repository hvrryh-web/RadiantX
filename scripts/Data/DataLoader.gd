extends Node
class_name DataLoader

## Loads and validates all game definitions from JSON files
## Singleton pattern - use DataLoader.instance

static var _instance: DataLoader = null

var agents: Dictionary = {}  # id -> AgentDef
var weapons: Dictionary = {}  # id -> WeaponDef
var utilities: Dictionary = {}  # id -> UtilityDef
var rulesets: Dictionary = {}  # id -> RulesetDef

var _loaded: bool = false

static func get_instance() -> DataLoader:
	if _instance == null:
		_instance = DataLoader.new()
	return _instance

func _ready():
	_instance = self

func is_loaded() -> bool:
	return _loaded

func load_all(base_path: String = "res://Defs") -> bool:
	"""Load all definitions from the Defs directory"""
	_loaded = false
	
	var success = true
	success = _load_directory(base_path + "/agents", agents, _parse_agent) and success
	success = _load_directory(base_path + "/weapons", weapons, _parse_weapon) and success
	success = _load_directory(base_path + "/utilities", utilities, _parse_utility) and success
	success = _load_directory(base_path + "/rulesets", rulesets, _parse_ruleset) and success
	
	if success:
		success = _validate_references()
	
	_loaded = success
	return success

func _load_directory(dir_path: String, target: Dictionary, parser: Callable) -> bool:
	"""Load all JSON files from a directory"""
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_warning("Directory not found: " + dir_path)
		return true  # Not an error if directory doesn't exist yet
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = dir_path + "/" + file_name
			if not _load_json_file(file_path, target, parser):
				push_error("Failed to load: " + file_path)
				return false
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return true

func _load_json_file(file_path: String, target: Dictionary, parser: Callable) -> bool:
	"""Load a single JSON file"""
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + file_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [file_path, json.get_error_message()])
		return false
	
	var data = json.data
	
	# Handle both single object and array of objects
	if data is Array:
		for item in data:
			if item is Dictionary:
				var def = parser.call(item)
				if def and def.id != "":
					target[def.id] = def
				else:
					push_error("Invalid definition in: " + file_path)
					return false
	elif data is Dictionary:
		var def = parser.call(data)
		if def and def.id != "":
			target[def.id] = def
		else:
			push_error("Invalid definition in: " + file_path)
			return false
	
	return true

func _parse_agent(data: Dictionary) -> AgentDef:
	return AgentDef.new(data)

func _parse_weapon(data: Dictionary) -> WeaponDef:
	return WeaponDef.new(data)

func _parse_utility(data: Dictionary) -> UtilityDef:
	return UtilityDef.new(data)

func _parse_ruleset(data: Dictionary) -> RulesetDef:
	return RulesetDef.new(data)

func _validate_references() -> bool:
	"""Validate that all ID references are valid"""
	var valid = true
	
	# Validate agent loadouts reference valid weapons and utilities
	for agent_id in agents:
		var agent = agents[agent_id] as AgentDef
		
		for weapon_id in agent.loadout_weapon_ids:
			if not weapons.has(weapon_id):
				push_warning("Agent '%s' references unknown weapon: %s" % [agent_id, weapon_id])
				# Not a hard error, just a warning
		
		for utility_id in agent.loadout_utility_ids:
			if not utilities.has(utility_id):
				push_warning("Agent '%s' references unknown utility: %s" % [agent_id, utility_id])
	
	return valid

# ========== Accessors ==========

func get_agent(id: String) -> AgentDef:
	return agents.get(id, null)

func get_weapon(id: String) -> WeaponDef:
	return weapons.get(id, null)

func get_utility(id: String) -> UtilityDef:
	return utilities.get(id, null)

func get_ruleset(id: String) -> RulesetDef:
	return rulesets.get(id, null)

func get_all_agents() -> Array:
	return agents.values()

func get_all_weapons() -> Array:
	return weapons.values()

func get_all_utilities() -> Array:
	return utilities.values()

func get_all_rulesets() -> Array:
	return rulesets.values()

func get_utilities_by_family(family: int) -> Array:
	"""Get all utilities of a specific family (CS_Grenade or VAL_Ability)"""
	var result = []
	for utility in utilities.values():
		if utility.family == family:
			result.append(utility)
	return result

func get_cs_grenades() -> Array:
	return get_utilities_by_family(DataTypes.UtilityFamily.CS_GRENADE)

func get_val_abilities() -> Array:
	return get_utilities_by_family(DataTypes.UtilityFamily.VAL_ABILITY)
