extends RefCounted
class_name WeaponState

## Runtime state for a weapon instance

var weapon_id: String = ""
var ammo_in_mag: int = 0
var fire_cooldown: float = 0.0
var reload_timer: float = 0.0
var recoil: float = 0.0  # 0..MaxRecoil

func _init(weapon_def: WeaponDef = null):
	if weapon_def:
		weapon_id = weapon_def.id
		ammo_in_mag = weapon_def.magazine_size

func is_reloading() -> bool:
	return reload_timer > 0.0

func can_fire() -> bool:
	return fire_cooldown <= 0.0 and not is_reloading() and ammo_in_mag > 0

func update(delta: float, weapon_def: WeaponDef):
	##Update weapon state for this frame##
	# Update fire cooldown
	if fire_cooldown > 0:
		fire_cooldown = maxf(0.0, fire_cooldown - delta)
	
	# Update reload timer
	if reload_timer > 0:
		reload_timer -= delta
		if reload_timer <= 0:
			reload_timer = 0
			ammo_in_mag = weapon_def.magazine_size
	
	# Recoil recovery
	if weapon_def and weapon_def.recoil:
		recoil = maxf(0.0, recoil - weapon_def.recoil.recovery_per_sec * delta)

func fire(weapon_def: WeaponDef):
	##Fire the weapon##
	if not can_fire():
		return
	
	ammo_in_mag -= 1
	fire_cooldown = weapon_def.get_fire_interval()
	
	# Add recoil
	if weapon_def.recoil:
		recoil = minf(recoil + weapon_def.recoil.recoil_per_shot, weapon_def.recoil.max_recoil)

func start_reload(weapon_def: WeaponDef):
	##Start reloading the weapon##
	if not is_reloading() and ammo_in_mag < weapon_def.magazine_size:
		reload_timer = weapon_def.reload_time

func to_dict() -> Dictionary:
	return {
		"weaponId": weapon_id,
		"ammoInMag": ammo_in_mag,
		"fireCooldown": fire_cooldown,
		"reloadTimer": reload_timer,
		"recoil": recoil
	}

static func from_dict(data: Dictionary) -> WeaponState:
	var state = WeaponState.new()
	if data.has("weaponId"):
		state.weapon_id = str(data.weaponId)
	if data.has("ammoInMag"):
		state.ammo_in_mag = int(data.ammoInMag)
	if data.has("fireCooldown"):
		state.fire_cooldown = float(data.fireCooldown)
	if data.has("reloadTimer"):
		state.reload_timer = float(data.reloadTimer)
	if data.has("recoil"):
		state.recoil = float(data.recoil)
	return state
