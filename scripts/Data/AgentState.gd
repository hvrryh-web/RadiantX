extends RefCounted
class_name AgentState

## Runtime state for an agent in the simulation

var agent_id: String = ""
var entity_id: int = 0
var side: int = DataTypes.TeamSide.ATTACK
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var facing_rad: float = 0.0
var stance: int = DataTypes.Stance.STAND
var hp: float = 100.0
var armor: float = 0.0
var stress: float = 0.0  # Suppression
var reaction_timer: float = 0.0
var weapon: WeaponState = null
var utilities: Dictionary = {}  # utility_id -> UtilityState
var status: StatusState = null

func _init(agent_def: AgentDef = null, id: int = 0):
	status = StatusState.new()
	weapon = WeaponState.new()
	
	if agent_def:
		agent_id = agent_def.id
		entity_id = id
		hp = agent_def.base_hp
		max_hp = agent_def.base_hp
		armor = agent_def.base_armor

func is_alive() -> bool:
	return hp > 0

func is_flashed() -> bool:
	return status.is_flashed()

func is_suppressed() -> bool:
	return status.is_suppressed()

func can_use_utility() -> bool:
	return not is_suppressed()

func take_damage(amount: float) -> float:
	##Take damage, returns actual damage dealt##
	var actual_damage = amount
	
	# Apply armor mitigation (simple model)
	if armor > 0:
		var armor_absorbed = minf(armor, amount * 0.5)
		armor -= armor_absorbed
		actual_damage = amount - armor_absorbed
	
	hp = maxf(0.0, hp - actual_damage)
	return actual_damage

var max_hp: float = 100.0  # Maximum HP for clamping heals

func heal(amount: float, cap: float = -1.0):
	## Heal the agent, clamped to max_hp
	var max_val = cap if cap > 0 else max_hp
	hp = minf(hp + amount, max_val)

func add_stress(amount: float):
	##Add stress/suppression##
	stress = clampf(stress + amount, 0.0, 1.0)

func update(delta: float):
	##Update agent state for this frame##
	# Update reaction timer
	if reaction_timer > 0:
		reaction_timer = maxf(0.0, reaction_timer - delta)
	
	# Update status effects
	var burn_damage = status.update(delta)
	if burn_damage > 0:
		take_damage(burn_damage)
	
	# Stress recovery
	stress = maxf(0.0, stress - 0.1 * delta)

func get_utility_state(utility_id: String) -> UtilityState:
	##Get utility state by ID##
	if utilities.has(utility_id):
		return utilities[utility_id]
	return null

func add_utility(utility_def: UtilityDef):
	##Add a utility to the agent's inventory##
	utilities[utility_def.id] = UtilityState.new(utility_def)

func to_dict() -> Dictionary:
	var utils_dict = {}
	for util_id in utilities:
		utils_dict[util_id] = utilities[util_id].to_dict()
	
	return {
		"agentId": agent_id,
		"entityId": entity_id,
		"side": "Attack" if side == DataTypes.TeamSide.ATTACK else "Defend",
		"pos": {"x": pos.x, "y": pos.y},
		"vel": {"x": vel.x, "y": vel.y},
		"facingRad": facing_rad,
		"stance": "Stand" if stance == DataTypes.Stance.STAND else "Crouch",
		"hp": hp,
		"armor": armor,
		"stress": stress,
		"reactionTimer": reaction_timer,
		"weapon": weapon.to_dict() if weapon else {},
		"utilities": utils_dict,
		"status": status.to_dict() if status else {}
	}

static func from_dict(data: Dictionary) -> AgentState:
	var state = AgentState.new()
	if data.has("agentId"):
		state.agent_id = str(data.agentId)
	if data.has("entityId"):
		state.entity_id = int(data.entityId)
	if data.has("side"):
		state.side = DataTypes.parse_team_side(str(data.side))
	if data.has("pos") and data.pos is Dictionary:
		state.pos = Vector2(float(data.pos.x), float(data.pos.y))
	if data.has("vel") and data.vel is Dictionary:
		state.vel = Vector2(float(data.vel.x), float(data.vel.y))
	if data.has("facingRad"):
		state.facing_rad = float(data.facingRad)
	if data.has("stance"):
		state.stance = DataTypes.parse_stance(str(data.stance))
	if data.has("hp"):
		state.hp = float(data.hp)
	if data.has("armor"):
		state.armor = float(data.armor)
	if data.has("stress"):
		state.stress = float(data.stress)
	if data.has("reactionTimer"):
		state.reaction_timer = float(data.reactionTimer)
	if data.has("weapon") and data.weapon is Dictionary:
		state.weapon = WeaponState.from_dict(data.weapon)
	if data.has("utilities") and data.utilities is Dictionary:
		for util_id in data.utilities:
			state.utilities[util_id] = UtilityState.from_dict(data.utilities[util_id])
	if data.has("status") and data.status is Dictionary:
		state.status = StatusState.from_dict(data.status)
	return state
