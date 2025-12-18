extends RefCounted
class_name MatchConfig

## Match configuration for a simulation run

var tick_rate: int = 20
var seed_value: int = 12345
var ruleset_id: String = "rules.cs"

func _init(data: Dictionary = {}):
	if data.has("tickRate"):
		tick_rate = int(data.tickRate)
	if data.has("seed"):
		seed_value = int(data.seed)
	if data.has("rulesetId"):
		ruleset_id = str(data.rulesetId)

func to_dict() -> Dictionary:
	return {
		"tickRate": tick_rate,
		"seed": seed_value,
		"rulesetId": ruleset_id
	}
