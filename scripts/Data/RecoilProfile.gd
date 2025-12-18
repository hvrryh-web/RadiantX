extends RefCounted
class_name RecoilProfile

## Weapon recoil profile

var recoil_per_shot: float = 0.02  # Recoil added per shot
var max_recoil: float = 0.15  # Maximum accumulated recoil
var recovery_per_sec: float = 0.1  # Recoil recovery per second

func _init(data: Dictionary = {}):
	if data.has("recoilPerShot"):
		recoil_per_shot = float(data.recoilPerShot)
	if data.has("maxRecoil"):
		max_recoil = float(data.maxRecoil)
	if data.has("recoveryPerSec"):
		recovery_per_sec = float(data.recoveryPerSec)

func to_dict() -> Dictionary:
	return {
		"recoilPerShot": recoil_per_shot,
		"maxRecoil": max_recoil,
		"recoveryPerSec": recovery_per_sec
	}
