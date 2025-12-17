extends RefCounted
class_name StatusState

## Runtime status effects on an agent

var flash_timer: float = 0.0
var concuss_timer: float = 0.0
var slow_timer: float = 0.0
var burn_timer: float = 0.0
var burn_dps: float = 0.0
var reveal_timer: float = 0.0
var suppress_timer: float = 0.0

func is_flashed() -> bool:
	return flash_timer > 0.0

func is_concussed() -> bool:
	return concuss_timer > 0.0

func is_slowed() -> bool:
	return slow_timer > 0.0

func is_burning() -> bool:
	return burn_timer > 0.0

func is_revealed() -> bool:
	return reveal_timer > 0.0

func is_suppressed() -> bool:
	return suppress_timer > 0.0

func apply_flash(duration: float, intensity: float = 1.0):
	"""Apply flash effect"""
	flash_timer = maxf(flash_timer, duration * intensity)

func apply_concuss(duration: float):
	"""Apply concussion effect"""
	concuss_timer = maxf(concuss_timer, duration)

func apply_slow(duration: float):
	"""Apply slow effect"""
	slow_timer = maxf(slow_timer, duration)

func apply_burn(duration: float, dps: float):
	"""Apply burn effect"""
	burn_timer = maxf(burn_timer, duration)
	burn_dps = dps

func apply_reveal(duration: float):
	"""Apply reveal effect"""
	reveal_timer = maxf(reveal_timer, duration)

func apply_suppress(duration: float):
	"""Apply suppress effect"""
	suppress_timer = maxf(suppress_timer, duration)

func update(delta: float) -> float:
	"""Update status timers, returns burn damage for this frame"""
	var burn_damage = 0.0
	
	if flash_timer > 0:
		flash_timer = maxf(0.0, flash_timer - delta)
	if concuss_timer > 0:
		concuss_timer = maxf(0.0, concuss_timer - delta)
	if slow_timer > 0:
		slow_timer = maxf(0.0, slow_timer - delta)
	if burn_timer > 0:
		burn_damage = burn_dps * delta
		burn_timer = maxf(0.0, burn_timer - delta)
		if burn_timer <= 0:
			burn_dps = 0.0
	if reveal_timer > 0:
		reveal_timer = maxf(0.0, reveal_timer - delta)
	if suppress_timer > 0:
		suppress_timer = maxf(0.0, suppress_timer - delta)
	
	return burn_damage

func clear():
	"""Clear all status effects"""
	flash_timer = 0.0
	concuss_timer = 0.0
	slow_timer = 0.0
	burn_timer = 0.0
	burn_dps = 0.0
	reveal_timer = 0.0
	suppress_timer = 0.0

func to_dict() -> Dictionary:
	return {
		"flashTimer": flash_timer,
		"concussTimer": concuss_timer,
		"slowTimer": slow_timer,
		"burnTimer": burn_timer,
		"burnDps": burn_dps,
		"revealTimer": reveal_timer,
		"suppressTimer": suppress_timer
	}

static func from_dict(data: Dictionary) -> StatusState:
	var state = StatusState.new()
	if data.has("flashTimer"):
		state.flash_timer = float(data.flashTimer)
	if data.has("concussTimer"):
		state.concuss_timer = float(data.concussTimer)
	if data.has("slowTimer"):
		state.slow_timer = float(data.slowTimer)
	if data.has("burnTimer"):
		state.burn_timer = float(data.burnTimer)
	if data.has("burnDps"):
		state.burn_dps = float(data.burnDps)
	if data.has("revealTimer"):
		state.reveal_timer = float(data.revealTimer)
	if data.has("suppressTimer"):
		state.suppress_timer = float(data.suppressTimer)
	return state
