extends RefCounted
class_name TraitBlock

## Agent traits for skill modeling (0..1 normalized values)
## Used for tuning and scouting agent capabilities

var aim: float = 0.5
var recoil_control: float = 0.5
var reaction: float = 0.5
var movement: float = 0.5
var game_sense: float = 0.5
var composure: float = 0.5
var teamwork: float = 0.5
var utility: float = 0.5
var discipline: float = 0.5
var aggression: float = 0.5

func _init(data: Dictionary = {}):
	if data.has("aim"):
		aim = clampf(float(data.aim), 0.0, 1.0)
	if data.has("recoilControl"):
		recoil_control = clampf(float(data.recoilControl), 0.0, 1.0)
	if data.has("reaction"):
		reaction = clampf(float(data.reaction), 0.0, 1.0)
	if data.has("movement"):
		movement = clampf(float(data.movement), 0.0, 1.0)
	if data.has("gameSense"):
		game_sense = clampf(float(data.gameSense), 0.0, 1.0)
	if data.has("composure"):
		composure = clampf(float(data.composure), 0.0, 1.0)
	if data.has("teamwork"):
		teamwork = clampf(float(data.teamwork), 0.0, 1.0)
	if data.has("utility"):
		utility = clampf(float(data.utility), 0.0, 1.0)
	if data.has("discipline"):
		discipline = clampf(float(data.discipline), 0.0, 1.0)
	if data.has("aggression"):
		aggression = clampf(float(data.aggression), 0.0, 1.0)

func to_dict() -> Dictionary:
	return {
		"aim": aim,
		"recoilControl": recoil_control,
		"reaction": reaction,
		"movement": movement,
		"gameSense": game_sense,
		"composure": composure,
		"teamwork": teamwork,
		"utility": utility,
		"discipline": discipline,
		"aggression": aggression
	}
