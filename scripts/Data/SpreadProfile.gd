extends RefCounted
class_name SpreadProfile

## Weapon spread profile - angular sigma in radians

var base_sigma: float = 0.02  # Base spread (radians)
var crouch_mult: float = 0.85  # Multiplier when crouching
var move_sigma_add: float = 0.01  # Added spread when moving (speed-weighted)
var jump_sigma_add: float = 0.05  # Added spread when jumping
var first_shot_bonus: float = -0.01  # Negative reduces sigma briefly on first shot

func _init(data: Dictionary = {}):
	if data.has("baseSigma"):
		base_sigma = float(data.baseSigma)
	if data.has("crouchMult"):
		crouch_mult = float(data.crouchMult)
	if data.has("moveSigmaAdd"):
		move_sigma_add = float(data.moveSigmaAdd)
	if data.has("jumpSigmaAdd"):
		jump_sigma_add = float(data.jumpSigmaAdd)
	if data.has("firstShotBonus"):
		first_shot_bonus = float(data.firstShotBonus)

func to_dict() -> Dictionary:
	return {
		"baseSigma": base_sigma,
		"crouchMult": crouch_mult,
		"moveSigmaAdd": move_sigma_add,
		"jumpSigmaAdd": jump_sigma_add,
		"firstShotBonus": first_shot_bonus
	}
