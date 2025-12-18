extends RefCounted
class_name DataTypes

## Common data types and enums for the tactical FPS simulation
## All tunables live in data (JSON files) and are loaded into strongly-typed classes

# ========== Enums ==========

enum TeamSide { ATTACK, DEFEND }
enum Stance { STAND, CROUCH }
enum FireMode { SEMI, BURST, AUTO }
enum DamageType { BULLET, EXPLOSION, FIRE, SHOCK, ABILITY }
enum HitZone { HEAD, TORSO, LEGS }
enum CastType { THROW_ARC, FIRE_PROJECTILE, INSTANT_AOE, PLACE_MARKER, BEAM, SELF }
enum UtilityFamily { CS_GRENADE, VAL_ABILITY }
enum EffectKind {
	SMOKE, FLASH_BLIND, CONCUSS, SLOW, BURN, HEAL, SHIELD,
	REVEAL, SUPPRESS, KNOCKBACK, WALL, TRAP, DECOY_SOUND
}

# ========== Helper Functions ==========

static func parse_team_side(value: String) -> TeamSide:
	match value.to_upper():
		"ATTACK": return TeamSide.ATTACK
		"DEFEND": return TeamSide.DEFEND
		_: return TeamSide.ATTACK

static func parse_stance(value: String) -> Stance:
	match value.to_upper():
		"STAND": return Stance.STAND
		"CROUCH": return Stance.CROUCH
		_: return Stance.STAND

static func parse_fire_mode(value: String) -> FireMode:
	match value.to_upper():
		"SEMI": return FireMode.SEMI
		"BURST": return FireMode.BURST
		"AUTO": return FireMode.AUTO
		_: return FireMode.SEMI

static func parse_damage_type(value: String) -> DamageType:
	match value.to_upper():
		"BULLET": return DamageType.BULLET
		"EXPLOSION": return DamageType.EXPLOSION
		"FIRE": return DamageType.FIRE
		"SHOCK": return DamageType.SHOCK
		"ABILITY": return DamageType.ABILITY
		_: return DamageType.BULLET

static func parse_hit_zone(value: String) -> HitZone:
	match value.to_upper():
		"HEAD": return HitZone.HEAD
		"TORSO": return HitZone.TORSO
		"LEGS": return HitZone.LEGS
		_: return HitZone.TORSO

static func parse_cast_type(value: String) -> CastType:
	match value.to_upper():
		"THROW_ARC", "THROWARC": return CastType.THROW_ARC
		"FIRE_PROJECTILE", "FIREPROJECTILE": return CastType.FIRE_PROJECTILE
		"INSTANT_AOE", "INSTANTAOE": return CastType.INSTANT_AOE
		"PLACE_MARKER", "PLACEMARKER": return CastType.PLACE_MARKER
		"BEAM": return CastType.BEAM
		"SELF": return CastType.SELF
		_: return CastType.THROW_ARC

static func parse_utility_family(value: String) -> UtilityFamily:
	match value.to_upper():
		"CS_GRENADE", "CSGRENADE", "CS": return UtilityFamily.CS_GRENADE
		"VAL_ABILITY", "VALABILITY", "VAL": return UtilityFamily.VAL_ABILITY
		_: return UtilityFamily.CS_GRENADE

static func parse_effect_kind(value: String) -> EffectKind:
	match value.to_upper():
		"SMOKE": return EffectKind.SMOKE
		"FLASH_BLIND", "FLASHBLIND", "FLASH": return EffectKind.FLASH_BLIND
		"CONCUSS": return EffectKind.CONCUSS
		"SLOW": return EffectKind.SLOW
		"BURN": return EffectKind.BURN
		"HEAL": return EffectKind.HEAL
		"SHIELD": return EffectKind.SHIELD
		"REVEAL": return EffectKind.REVEAL
		"SUPPRESS": return EffectKind.SUPPRESS
		"KNOCKBACK": return EffectKind.KNOCKBACK
		"WALL": return EffectKind.WALL
		"TRAP": return EffectKind.TRAP
		"DECOY_SOUND", "DECOYSOUND", "DECOY": return EffectKind.DECOY_SOUND
		_: return EffectKind.SMOKE
