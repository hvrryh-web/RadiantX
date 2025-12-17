extends RefCounted
class_name SimEvent

## Base class for simulation events

var time: float = 0.0

func _init(t: float = 0.0):
	time = t

func to_dict() -> Dictionary:
	return {"time": time, "type": "base"}


class ShotEvent extends SimEvent:
	## Event for a shot being fired
	var shooter_id: int = 0
	var target_id: int = 0
	var weapon_id: String = ""
	var hit: bool = false
	var hit_zone: int = DataTypes.HitZone.TORSO
	var damage: float = 0.0
	
	func _init(t: float = 0.0, s_id: int = 0, t_id: int = 0, w_id: String = ""):
		super._init(t)
		shooter_id = s_id
		target_id = t_id
		weapon_id = w_id
	
	func to_dict() -> Dictionary:
		return {
			"type": "shot",
			"time": time,
			"shooterId": shooter_id,
			"targetId": target_id,
			"weaponId": weapon_id,
			"hit": hit,
			"hitZone": _zone_to_string(hit_zone),
			"damage": damage
		}
	
	func _zone_to_string(zone: int) -> String:
		match zone:
			DataTypes.HitZone.HEAD: return "Head"
			DataTypes.HitZone.TORSO: return "Torso"
			DataTypes.HitZone.LEGS: return "Legs"
			_: return "Torso"


class UtilityCastEvent extends SimEvent:
	## Event for utility/ability being cast
	var caster_id: int = 0
	var utility_id: String = ""
	var target_pos: Vector2 = Vector2.ZERO
	
	func _init(t: float = 0.0, c_id: int = 0, u_id: String = "", pos: Vector2 = Vector2.ZERO):
		super._init(t)
		caster_id = c_id
		utility_id = u_id
		target_pos = pos
	
	func to_dict() -> Dictionary:
		return {
			"type": "utility_cast",
			"time": time,
			"casterId": caster_id,
			"utilityId": utility_id,
			"targetPos": {"x": target_pos.x, "y": target_pos.y}
		}


class ExplosionEvent extends SimEvent:
	## Event for an explosion/detonation
	var source_id: int = 0
	var pos: Vector2 = Vector2.ZERO
	var utility_id: String = ""
	
	func _init(t: float = 0.0, s_id: int = 0, p: Vector2 = Vector2.ZERO, u_id: String = ""):
		super._init(t)
		source_id = s_id
		pos = p
		utility_id = u_id
	
	func to_dict() -> Dictionary:
		return {
			"type": "explosion",
			"time": time,
			"sourceId": source_id,
			"pos": {"x": pos.x, "y": pos.y},
			"utilityId": utility_id
		}


class DamageEvent extends SimEvent:
	## Event for damage being dealt
	var source_id: int = 0
	var target_id: int = 0
	var damage_type: int = DataTypes.DamageType.BULLET
	var amount: float = 0.0
	var lethal: bool = false
	
	func _init(t: float = 0.0, s_id: int = 0, t_id: int = 0, d_type: int = 0, amt: float = 0.0):
		super._init(t)
		source_id = s_id
		target_id = t_id
		damage_type = d_type
		amount = amt
	
	func to_dict() -> Dictionary:
		return {
			"type": "damage",
			"time": time,
			"sourceId": source_id,
			"targetId": target_id,
			"damageType": _damage_type_to_string(damage_type),
			"amount": amount,
			"lethal": lethal
		}
	
	func _damage_type_to_string(dt: int) -> String:
		match dt:
			DataTypes.DamageType.BULLET: return "Bullet"
			DataTypes.DamageType.EXPLOSION: return "Explosion"
			DataTypes.DamageType.FIRE: return "Fire"
			DataTypes.DamageType.SHOCK: return "Shock"
			DataTypes.DamageType.ABILITY: return "Ability"
			_: return "Bullet"


class EffectAppliedEvent extends SimEvent:
	## Event for an effect being applied to an agent
	var source_id: int = 0
	var target_id: int = 0
	var effect_kind: int = DataTypes.EffectKind.SMOKE
	var duration: float = 0.0
	
	func _init(t: float = 0.0, s_id: int = 0, t_id: int = 0, kind: int = 0, dur: float = 0.0):
		super._init(t)
		source_id = s_id
		target_id = t_id
		effect_kind = kind
		duration = dur
	
	func to_dict() -> Dictionary:
		return {
			"type": "effect_applied",
			"time": time,
			"sourceId": source_id,
			"targetId": target_id,
			"effectKind": _effect_kind_to_string(effect_kind),
			"duration": duration
		}
	
	func _effect_kind_to_string(kind: int) -> String:
		match kind:
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
			_: return "Unknown"
