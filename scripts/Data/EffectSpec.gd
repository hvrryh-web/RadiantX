extends RefCounted
class_name EffectSpec

## Effect specification for utility/ability effects
## Defines what happens when a utility is activated

var kind: int = DataTypes.EffectKind.SMOKE
var duration: float = 18.0  # seconds
var radius: float = 4.5  # units
var dps_or_value: float = 1.0  # DPS for burn; intensity for flash; etc
var falloff: float = 0.0  # 0..1, how quickly value drops with distance
var requires_los: bool = false  # Line of sight required
var requires_facing: bool = false  # Target must be facing effect
var facing_angle_deg: float = 0.0  # Flash cone, etc

func _init(data: Dictionary = {}):
	if data.has("kind"):
		kind = DataTypes.parse_effect_kind(str(data.kind))
	if data.has("duration"):
		duration = float(data.duration)
	if data.has("radius"):
		radius = float(data.radius)
	if data.has("dpsOrValue"):
		dps_or_value = float(data.dpsOrValue)
	if data.has("falloff"):
		falloff = float(data.falloff)
	if data.has("requiresLOS"):
		requires_los = bool(data.requiresLOS)
	if data.has("requiresFacing"):
		requires_facing = bool(data.requiresFacing)
	if data.has("facingAngleDeg"):
		facing_angle_deg = float(data.facingAngleDeg)

func to_dict() -> Dictionary:
	return {
		"kind": _kind_to_string(kind),
		"duration": duration,
		"radius": radius,
		"dpsOrValue": dps_or_value,
		"falloff": falloff,
		"requiresLOS": requires_los,
		"requiresFacing": requires_facing,
		"facingAngleDeg": facing_angle_deg
	}

func _kind_to_string(k: int) -> String:
	match k:
		DataTypes.EffectKind.SMOKE: return "Smoke"
		DataTypes.EffectKind.FLASH_BLIND: return "FlashBlind"
		DataTypes.EffectKind.CONCUSS: return "Concuss"
		DataTypes.EffectKind.SLOW: return "Slow"
		DataTypes.EffectKind.BURN: return "Burn"
		DataTypes.EffectKind.HEAL: return "Heal"
		DataTypes.EffectKind.SHIELD: return "Shield"
		DataTypes.EffectKind.REVEAL: return "Reveal"
		DataTypes.EffectKind.SUPPRESS: return "Suppress"
		DataTypes.EffectKind.KNOCKBACK: return "Knockback"
		DataTypes.EffectKind.WALL: return "Wall"
		DataTypes.EffectKind.TRAP: return "Trap"
		DataTypes.EffectKind.DECOY_SOUND: return "DecoySound"
		_: return "Smoke"
