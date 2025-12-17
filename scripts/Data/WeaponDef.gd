extends RefCounted
class_name WeaponDef

## Weapon definition with all tunable parameters
## Runtime state is separate (see WeaponState)

var id: String = ""
var fire_mode: int = DataTypes.FireMode.SEMI
var magazine_size: int = 30
var rounds_per_minute: float = 600.0
var reload_time: float = 2.5  # seconds
var damage: DamageProfile = null
var spread: SpreadProfile = null
var recoil: RecoilProfile = null
var penetration: PenetrationProfile = null

func _init(data: Dictionary = {}):
	damage = DamageProfile.new()
	spread = SpreadProfile.new()
	recoil = RecoilProfile.new()
	penetration = PenetrationProfile.new()
	
	if data.has("id"):
		id = str(data.id)
	if data.has("fireMode"):
		fire_mode = DataTypes.parse_fire_mode(str(data.fireMode))
	if data.has("magazineSize"):
		magazine_size = int(data.magazineSize)
	if data.has("roundsPerMinute"):
		rounds_per_minute = float(data.roundsPerMinute)
	if data.has("reloadTime"):
		reload_time = float(data.reloadTime)
	if data.has("damage") and data.damage is Dictionary:
		damage = DamageProfile.new(data.damage)
	if data.has("spread") and data.spread is Dictionary:
		spread = SpreadProfile.new(data.spread)
	if data.has("recoil") and data.recoil is Dictionary:
		recoil = RecoilProfile.new(data.recoil)
	if data.has("penetration") and data.penetration is Dictionary:
		penetration = PenetrationProfile.new(data.penetration)

func get_fire_interval() -> float:
	"""Get time between shots in seconds"""
	return 60.0 / rounds_per_minute

func to_dict() -> Dictionary:
	return {
		"id": id,
		"fireMode": _fire_mode_to_string(fire_mode),
		"magazineSize": magazine_size,
		"roundsPerMinute": rounds_per_minute,
		"reloadTime": reload_time,
		"damage": damage.to_dict() if damage else {},
		"spread": spread.to_dict() if spread else {},
		"recoil": recoil.to_dict() if recoil else {},
		"penetration": penetration.to_dict() if penetration else {}
	}

func _fire_mode_to_string(mode: int) -> String:
	match mode:
		DataTypes.FireMode.SEMI: return "Semi"
		DataTypes.FireMode.BURST: return "Burst"
		DataTypes.FireMode.AUTO: return "Auto"
		_: return "Semi"
