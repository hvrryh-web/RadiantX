extends RefCounted
class_name AgentBridge

## Bridge class connecting legacy Agent.gd with new AgentState/AgentDef system
## Enables data-driven gameplay while maintaining backward compatibility

var agent: Agent  # Legacy agent reference
var agent_def: AgentDef  # Definition data
var agent_state: AgentState  # Runtime state
var weapon_def: WeaponDef  # Current weapon definition

func _init(legacy_agent: Agent = null):
	agent = legacy_agent

func setup_from_def(def: AgentDef, weapon: WeaponDef = null):
	## Initialize bridge from definition
	agent_def = def
	weapon_def = weapon
	agent_state = AgentState.new(def, agent.agent_id if agent else 0)
	
	if weapon_def:
		agent_state.weapon = WeaponState.new(weapon_def)

func sync_to_legacy():
	## Sync state from AgentState to legacy Agent
	if not agent or not agent_state:
		return
	
	agent.health = agent_state.hp
	agent.position = agent_state.pos
	agent.velocity = agent_state.vel
	
	# Sync flash state
	if agent_state.status.is_flashed():
		# Convert remaining timer to tick-based
		agent.is_flashed_until = int(agent_state.status.flash_timer * 20)  # 20 TPS

func sync_from_legacy():
	## Sync state from legacy Agent to AgentState
	if not agent or not agent_state:
		return
	
	agent_state.hp = agent.health
	agent_state.pos = agent.position
	agent_state.vel = agent.velocity
	agent_state.entity_id = agent.agent_id
	
	# Sync stance
	# Note: Legacy Agent doesn't have stance, default to STAND

func get_traits() -> TraitBlock:
	## Get agent traits for skill calculations
	if agent_def and agent_def.traits:
		return agent_def.traits
	return TraitBlock.new()  # Default traits

func get_aim_skill() -> float:
	## Get aim skill (0-1)
	return get_traits().aim

func get_reaction_skill() -> float:
	## Get reaction time skill (0-1, higher = faster)
	return get_traits().reaction

func get_composure() -> float:
	## Get composure under pressure (0-1)
	return get_traits().composure

func create_duel_context(target_bridge: AgentBridge, map_data: MapData = null) -> DuelContext:
	## Create a DuelContext for combat simulation
	sync_from_legacy()
	target_bridge.sync_from_legacy()
	
	var context = DuelContext.new(agent_state, target_bridge.agent_state)
	context.shooter_def = agent_def
	context.target_def = target_bridge.agent_def
	context.weapon_def = weapon_def
	
	# Calculate LOS if map provided
	if map_data:
		context.has_line_of_sight = map_data.check_line_of_sight(
			agent_state.pos, target_bridge.agent_state.pos)
	
	return context

func apply_damage(amount: float, damage_type: int = DataTypes.DamageType.BULLET) -> float:
	## Apply damage through the new system
	if not agent_state:
		if agent:
			agent.health -= amount
			return amount
		return 0.0
	
	var actual = agent_state.take_damage(amount)
	sync_to_legacy()
	return actual

func apply_effect(effect: EffectSpec):
	## Apply a utility effect to this agent
	if not agent_state or not agent_state.status:
		return
	
	match effect.kind:
		DataTypes.EffectKind.FLASH_BLIND:
			agent_state.status.apply_flash(effect.duration, effect.dps_or_value)
		DataTypes.EffectKind.CONCUSS:
			agent_state.status.apply_concuss(effect.duration)
		DataTypes.EffectKind.SLOW:
			agent_state.status.apply_slow(effect.duration)
		DataTypes.EffectKind.BURN:
			agent_state.status.apply_burn(effect.duration, effect.dps_or_value)
		DataTypes.EffectKind.REVEAL:
			agent_state.status.apply_reveal(effect.duration)
		DataTypes.EffectKind.SUPPRESS:
			agent_state.status.apply_suppress(effect.duration)
		DataTypes.EffectKind.HEAL:
			agent_state.heal(effect.dps_or_value * effect.duration)
		DataTypes.EffectKind.SHIELD:
			agent_state.armor += effect.dps_or_value
	
	sync_to_legacy()

func update(delta: float):
	## Update agent state for this frame
	if agent_state:
		agent_state.update(delta)
		sync_to_legacy()

func is_alive() -> bool:
	if agent_state:
		return agent_state.is_alive()
	if agent:
		return agent.is_alive()
	return false

func to_dict() -> Dictionary:
	## Serialize bridge state
	return {
		"agent_id": agent.agent_id if agent else -1,
		"agent_def_id": agent_def.id if agent_def else "",
		"weapon_def_id": weapon_def.id if weapon_def else "",
		"agent_state": agent_state.to_dict() if agent_state else {}
	}
