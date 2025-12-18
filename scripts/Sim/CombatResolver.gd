extends RefCounted
class_name CombatResolver

## Integration layer connecting MatchEngine with the new duel system
## Provides data-driven combat resolution using DuelResolver

var duel_resolver: DuelResolver
var data_loader: DataLoader
var map_data: MapData

# Agent bridges for data-driven combat
var agent_bridges: Dictionary = {}  # agent_id -> AgentBridge

# Configuration
var use_data_driven_combat: bool = true

func _init():
	duel_resolver = DuelResolver.new()

func setup(seed: int, map: MapData, loader: DataLoader = null):
	## Setup combat resolver with match configuration
	duel_resolver.set_seed(seed)
	duel_resolver.set_map(map)
	map_data = map
	data_loader = loader

func set_spectator_viewport(viewport: Rect2):
	## Set viewport for LOD determination
	duel_resolver.set_spectator_viewport(viewport)

func register_agent(agent: Agent, agent_def_id: String = "", weapon_def_id: String = ""):
	## Register an agent for data-driven combat
	var bridge = AgentBridge.new(agent)
	
	if data_loader and agent_def_id != "":
		var agent_def = data_loader.get_agent(agent_def_id)
		var weapon_def = data_loader.get_weapon(weapon_def_id) if weapon_def_id != "" else null
		if agent_def:
			bridge.setup_from_def(agent_def, weapon_def)
	
	agent_bridges[agent.agent_id] = bridge

func get_bridge(agent: Agent) -> AgentBridge:
	## Get the bridge for an agent
	return agent_bridges.get(agent.agent_id, null)

func resolve_combat(attacker: Agent, target: Agent, rng: RandomNumberGenerator) -> Dictionary:
	## Resolve combat between two agents
	## Returns dictionary with hit info compatible with existing MatchEngine
	
	var result = {
		"hit": false,
		"damage": 0.0,
		"hit_zone": DataTypes.HitZone.TORSO,
		"lethal": false
	}
	
	# Get bridges
	var attacker_bridge = agent_bridges.get(attacker.agent_id)
	var target_bridge = agent_bridges.get(target.agent_id)
	
	# Fall back to legacy combat if bridges not available
	if not attacker_bridge or not target_bridge or not use_data_driven_combat:
		return _legacy_combat(attacker, target, rng)
	
	# Create duel context
	var context = attacker_bridge.create_duel_context(target_bridge, map_data)
	
	# Count alive agents for LOD determination
	var alive_attackers = _count_alive_team(attacker.team)
	var alive_defenders = _count_alive_team(Agent.Team.TEAM_B if attacker.team == Agent.Team.TEAM_A else Agent.Team.TEAM_A)
	
	# Resolve single shot (not full duel for per-tick integration)
	var duel_result = _resolve_single_shot(context, rng)
	
	if duel_result.hit:
		result.hit = true
		result.damage = duel_result.damage
		result.hit_zone = duel_result.hit_zone
		
		# Apply damage through bridge
		target_bridge.apply_damage(result.damage)
		result.lethal = not target_bridge.is_alive()
	
	return result

func _resolve_single_shot(context: DuelContext, rng: RandomNumberGenerator) -> Dictionary:
	## Resolve a single shot (for per-tick combat)
	var result = {"hit": false, "damage": 0.0, "hit_zone": DataTypes.HitZone.TORSO}
	
	# Calculate hit probability
	var p_hit = context.compute_hit_probability()
	
	if rng.randf() < p_hit:
		result.hit = true
		
		# Determine hit zone
		var head_share = context.compute_head_share()
		if rng.randf() < head_share:
			result.hit_zone = DataTypes.HitZone.HEAD
		elif rng.randf() < 0.1:  # 10% leg hits
			result.hit_zone = DataTypes.HitZone.LEGS
		else:
			result.hit_zone = DataTypes.HitZone.TORSO
		
		# Calculate damage
		if context.weapon_def and context.weapon_def.damage:
			result.damage = context.weapon_def.damage.get_damage_for_zone(
				result.hit_zone, context.distance)
		else:
			result.damage = 25.0  # Legacy fallback
	
	return result

func _legacy_combat(attacker: Agent, target: Agent, rng: RandomNumberGenerator) -> Dictionary:
	## Fallback to legacy combat calculation
	var result = {
		"hit": false,
		"damage": 0.0,
		"hit_zone": DataTypes.HitZone.TORSO,
		"lethal": false
	}
	
	var distance = attacker.position.distance_to(target.position)
	var base_chance = 0.3
	var distance_factor = clampf(1.0 - (distance / 50.0), 0.1, 1.0)
	var flash_factor = 1.0 if not attacker.is_flashed() else 0.1
	var hit_chance = base_chance * distance_factor * flash_factor
	
	if rng.randf() < hit_chance:
		result.hit = true
		result.damage = attacker.get_damage()
		result.lethal = (target.health - result.damage) <= 0
	
	return result

func _count_alive_team(team: int) -> int:
	## Count alive agents on a team
	var count = 0
	for bridge in agent_bridges.values():
		if bridge.agent and bridge.agent.team == team and bridge.is_alive():
			count += 1
	return count

func update_agents(delta: float):
	## Update all agent bridges
	for bridge in agent_bridges.values():
		bridge.update(delta)

func apply_utility_effect(source: Agent, target: Agent, effect: EffectSpec):
	## Apply a utility effect from source to target
	var target_bridge = agent_bridges.get(target.agent_id)
	if target_bridge:
		target_bridge.apply_effect(effect)

func clear():
	## Clear all registered agents
	agent_bridges.clear()
