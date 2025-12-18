extends RefCounted
class_name DuelResult

## Result of a duel simulation

var winner_id: int = -1  # Entity ID of winner, -1 if no winner
var loser_id: int = -1
var ttk: float = 0.0  # Time to kill
var shots_fired: int = 0
var hits: int = 0
var headshots: int = 0
var damage_dealt: float = 0.0
var events: Array = []  # Array of SimEvent

func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return float(hits) / float(shots_fired)

func get_headshot_rate() -> float:
	if hits == 0:
		return 0.0
	return float(headshots) / float(hits)

func to_dict() -> Dictionary:
	var event_dicts = []
	for event in events:
		if event.has_method("to_dict"):
			event_dicts.append(event.to_dict())
	
	return {
		"winnerId": winner_id,
		"loserId": loser_id,
		"ttk": ttk,
		"shotsFired": shots_fired,
		"hits": hits,
		"headshots": headshots,
		"damageDealt": damage_dealt,
		"accuracy": get_accuracy(),
		"headshotRate": get_headshot_rate(),
		"events": event_dicts
	}
