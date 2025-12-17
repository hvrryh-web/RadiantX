extends RefCounted
class_name DuelContext

## Context for a duel between two agents
## Contains all information needed by both duel engines

var shooter_state: AgentState
var target_state: AgentState
var shooter_def: AgentDef
var target_def: AgentDef
var weapon_def: WeaponDef

# Environmental context
var distance: float = 0.0
var exposure: float = 1.0  # 0..1, how visible target is
var cover_factor: float = 0.0  # 0..1, how protected target is
var shooter_speed: float = 0.0
var target_speed: float = 0.0
var has_line_of_sight: bool = true

# Smoke/visibility
var smoke_density: float = 0.0  # 0..1, accumulated smoke along LOS

# Combat configuration
var max_duel_time: float = 5.0  # seconds
var base_radius: float = 0.5  # target body radius in world units

func _init(s_state: AgentState = null, t_state: AgentState = null):
	shooter_state = s_state
	target_state = t_state
	
	if shooter_state and target_state:
		distance = shooter_state.pos.distance_to(target_state.pos)
		shooter_speed = shooter_state.vel.length()
		target_speed = target_state.vel.length()

func compute_aim_sigma() -> float:
	##Compute effective aim sigma for the shooter##
	if not weapon_def or not weapon_def.spread:
		return 0.1  # Default fallback
	
	var spread = weapon_def.spread
	var sigma = spread.base_sigma
	
	# Movement penalty
	sigma += shooter_speed * spread.move_sigma_add
	
	# Recoil contribution
	if shooter_state and shooter_state.weapon:
		var recoil_factor = 0.5  # Tune this
		sigma += shooter_state.weapon.recoil * recoil_factor
	
	# Crouch bonus
	if shooter_state and shooter_state.stance == DataTypes.Stance.CROUCH:
		sigma *= spread.crouch_mult
	
	# Skill modifier (aim trait)
	if shooter_def and shooter_def.traits:
		# Higher aim = lower sigma
		# Factor: 1.15 at aim=0, 0.5 at aim=1
		sigma *= (1.15 - 0.65 * shooter_def.traits.aim)
	
	# Stress/composure modifier
	if shooter_state and shooter_def and shooter_def.traits:
		var stress_factor = 0.5  # Tune this
		sigma *= (1.0 + stress_factor * shooter_state.stress * (1 - shooter_def.traits.composure))
	
	# Flash penalty
	if shooter_state and shooter_state.is_flashed():
		sigma *= 3.0  # Significantly worse aim when flashed
	
	# Concussion penalty
	if shooter_state and shooter_state.status.is_concussed():
		sigma *= 1.5
	
	return sigma

func compute_reaction_time() -> float:
	##Compute reaction time for the shooter##
	var base_reaction = 0.25  # Base reaction time in seconds
	
	if shooter_def and shooter_def.traits:
		# Lower reaction trait = faster reaction
		base_reaction = 0.15 + 0.3 * (1 - shooter_def.traits.reaction)
	
	# Penalty from being flashed
	if shooter_state and shooter_state.is_flashed():
		base_reaction += 0.5
	
	# Penalty from concussion
	if shooter_state and shooter_state.status.is_concussed():
		base_reaction += 0.2
	
	return base_reaction

func compute_target_angular_radius() -> float:
	##Compute the angular radius of the target from shooter's perspective##
	if distance <= 0:
		return PI / 4  # Very close, large angle
	
	var effective_radius = base_radius * exposure
	return atan2(effective_radius, distance)

func compute_hit_probability() -> float:
	##Compute probability of hitting the target##
	var sigma = compute_aim_sigma()
	var r_ang = compute_target_angular_radius()
	
	# Probability a 2D Gaussian shot lands within a circle
	# p_hit = 1 - exp(-(r_ang^2) / (2*sigma^2))
	if sigma <= 0:
		return 1.0  # Perfect accuracy
	
	return 1.0 - exp(-(r_ang * r_ang) / (2.0 * sigma * sigma))

func compute_head_share() -> float:
	##Compute probability that a hit is a headshot##
	var base_head_share = 0.15  # Base headshot probability
	
	if shooter_def and shooter_def.traits:
		# Better aim = higher headshot chance
		base_head_share = 0.1 + 0.15 * shooter_def.traits.aim
	
	# Distance penalty
	if distance > 20:
		base_head_share *= maxf(0.5, 1.0 - (distance - 20) / 50.0)
	
	# Crouch target = smaller head target
	if target_state and target_state.stance == DataTypes.Stance.CROUCH:
		base_head_share *= 0.8
	
	# Recoil penalty for headshots
	if shooter_state and shooter_state.weapon:
		var recoil_penalty = 1.0 - shooter_state.weapon.recoil * 0.5
		base_head_share *= maxf(0.3, recoil_penalty)
	
	return clampf(base_head_share, 0.05, 0.5)

func get_shot_interval() -> float:
	##Get time between shots##
	if weapon_def:
		return weapon_def.get_fire_interval()
	return 0.1  # Default 10 shots per second
