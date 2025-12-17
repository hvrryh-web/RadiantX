extends RefCounted
class_name UtilityState

## Runtime state for a utility/ability instance

var utility_id: String = ""
var charges: int = 1
var cooldown_timer: float = 0.0

func _init(utility_def: UtilityDef = null):
	if utility_def:
		utility_id = utility_def.id
		charges = utility_def.max_charges

func can_use() -> bool:
	return charges > 0 and cooldown_timer <= 0.0

func is_on_cooldown() -> bool:
	return cooldown_timer > 0.0

func update(delta: float):
	"""Update utility state for this frame"""
	if cooldown_timer > 0:
		cooldown_timer = maxf(0.0, cooldown_timer - delta)

func use(utility_def: UtilityDef) -> bool:
	"""Use the utility, returns true if successful"""
	if not can_use():
		return false
	
	charges -= 1
	if utility_def.cooldown > 0:
		cooldown_timer = utility_def.cooldown
	
	return true

func add_charge(count: int = 1):
	"""Add charges (e.g., from purchase or round reset)"""
	charges += count

func reset(utility_def: UtilityDef):
	"""Reset to full charges"""
	charges = utility_def.max_charges
	cooldown_timer = 0.0

func to_dict() -> Dictionary:
	return {
		"utilityId": utility_id,
		"charges": charges,
		"cooldownTimer": cooldown_timer
	}

static func from_dict(data: Dictionary) -> UtilityState:
	var state = UtilityState.new()
	if data.has("utilityId"):
		state.utility_id = str(data.utilityId)
	if data.has("charges"):
		state.charges = int(data.charges)
	if data.has("cooldownTimer"):
		state.cooldown_timer = float(data.cooldownTimer)
	return state
