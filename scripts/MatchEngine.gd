extends Node
class_name MatchEngine

## Deterministic 20 TPS match engine with seeded RNG
## Handles tick-based simulation for reproducible matches

signal tick_processed(tick_number: int)
signal match_started()
signal match_ended()

const TICKS_PER_SECOND = 20
const TICK_DELTA = 1.0 / TICKS_PER_SECOND

var current_tick: int = 0
var match_seed: int = 0
var rng: RandomNumberGenerator
var is_running: bool = false
var agents: Array[Agent] = []
var map_data: MapData
var event_log: EventLog

func _ready():
	rng = RandomNumberGenerator.new()
	event_log = EventLog.new()
	add_child(event_log)

func start_match(seed: int, map: MapData, team_a: Array[Agent], team_b: Array[Agent]):
	"""Start a new match with given seed and teams"""
	match_seed = seed
	rng.seed = seed
	map_data = map
	current_tick = 0
	is_running = true
	
	# Initialize agents
	agents.clear()
	agents.append_array(team_a)
	agents.append_array(team_b)
	
	for agent in agents:
		agent.reset(rng.randi())
	
	event_log.clear()
	event_log.log_event({
		"type": "match_start",
		"tick": current_tick,
		"seed": match_seed,
		"agents": agents.size()
	})
	
	match_started.emit()

func stop_match():
	"""Stop the current match"""
	is_running = false
	event_log.log_event({
		"type": "match_end",
		"tick": current_tick
	})
	match_ended.emit()

func process_tick():
	"""Process a single simulation tick"""
	if not is_running:
		return
	
	current_tick += 1
	
	# Update agent beliefs
	for agent in agents:
		agent.update_beliefs(current_tick, agents, map_data)
	
	# Process agent decisions
	for agent in agents:
		agent.make_decision(current_tick, rng)
	
	# Apply agent actions
	for agent in agents:
		agent.apply_action(current_tick, TICK_DELTA)
	
	# Check for tactical events (smokes, flashes, etc)
	_process_tactical_events()
	
	# Check combat
	_process_combat()
	
	tick_processed.emit(current_tick)

func _process_tactical_events():
	"""Process smoke grenades, flashbangs, etc"""
	for agent in agents:
		# Process smoke deployment
		if agent.has_pending_smoke():
			var smoke_pos = agent.get_pending_smoke_position()
			_deploy_smoke(smoke_pos, agent)
			event_log.log_event({
				"type": "smoke_deployed",
				"tick": current_tick,
				"agent_id": agent.agent_id,
				"position": {"x": smoke_pos.x, "y": smoke_pos.y}
			})
		
		# Process flashbang
		if agent.has_pending_flash():
			var flash_pos = agent.get_pending_flash_position()
			_deploy_flash(flash_pos, agent)
			event_log.log_event({
				"type": "flash_deployed",
				"tick": current_tick,
				"agent_id": agent.agent_id,
				"position": {"x": flash_pos.x, "y": flash_pos.y}
			})

func _deploy_smoke(position: Vector2, source_agent: Agent):
	"""Deploy smoke at position"""
	for agent in agents:
		if agent != source_agent:
			agent.notify_smoke_deployed(position, current_tick)

func _deploy_flash(position: Vector2, source_agent: Agent):
	"""Deploy flashbang at position"""
	for agent in agents:
		if agent != source_agent:
			var distance = agent.position.distance_to(position)
			if distance < 20.0:  # Flash radius
				agent.notify_flashed(current_tick, distance)

func _process_combat():
	"""Process combat between agents"""
	for attacker in agents:
		if not attacker.is_alive():
			continue
		
		var target = attacker.get_current_target()
		if target and target.is_alive():
			# Check line of sight
			if _has_line_of_sight(attacker.position, target.position):
				var hit_chance = _calculate_hit_chance(attacker, target)
				if rng.randf() < hit_chance:
					target.take_damage(attacker.get_damage(), current_tick)
					event_log.log_event({
						"type": "hit",
						"tick": current_tick,
						"attacker_id": attacker.agent_id,
						"target_id": target.agent_id
					})
					
					if not target.is_alive():
						event_log.log_event({
							"type": "kill",
							"tick": current_tick,
							"attacker_id": attacker.agent_id,
							"target_id": target.agent_id
						})

func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	"""Check if there's line of sight between two points"""
	if not map_data:
		return true
	
	return map_data.check_line_of_sight(from, to)

func _calculate_hit_chance(attacker: Agent, target: Agent) -> float:
	"""Calculate hit probability based on distance and conditions"""
	var distance = attacker.position.distance_to(target.position)
	var base_chance = 0.3
	
	# Distance penalty
	var distance_factor = clamp(1.0 - (distance / 50.0), 0.1, 1.0)
	
	# Flash penalty
	var flash_factor = 1.0 if not attacker.is_flashed() else 0.1
	
	return base_chance * distance_factor * flash_factor

func get_state_at_tick(tick: int) -> Dictionary:
	"""Get the match state at a specific tick (for replay)"""
	return {
		"tick": tick,
		"agents": agents.map(func(a): return a.get_state())
	}

func set_replay_state(state: Dictionary):
	"""Set match state from replay data"""
	current_tick = state.tick
	for i in range(agents.size()):
		if i < state.agents.size():
			agents[i].set_state(state.agents[i])
