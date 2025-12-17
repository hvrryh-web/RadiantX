extends Node2D
class_name Agent

## Agent with partial observability and belief system

signal position_changed(new_position: Vector2)
signal health_changed(new_health: float)
signal died()

enum Team { TEAM_A, TEAM_B }
enum State { IDLE, MOVING, ATTACKING, TAKING_COVER }

var agent_id: int = 0
var team: Team = Team.TEAM_A
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var health: float = 100.0
var max_health: float = 100.0

var current_state: State = State.IDLE
var current_target: Agent = null

# Partial observability - belief state
var beliefs: Dictionary = {}  # agent_id -> belief
var last_seen: Dictionary = {}  # agent_id -> tick
var communication_delay: int = 2  # ticks

# Tactical
var is_flashed_until: int = 0
var smoke_positions: Array[Vector2] = []
var pending_smoke: Vector2 = Vector2.ZERO
var pending_flash: Vector2 = Vector2.ZERO
var has_smoke_pending: bool = false
var has_flash_pending: bool = false

# Movement
var move_speed: float = 5.0
var target_position: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("agents")

func reset(seed: int):
	"""Reset agent to initial state"""
	health = max_health
	current_state = State.IDLE
	current_target = null
	beliefs.clear()
	last_seen.clear()
	smoke_positions.clear()
	is_flashed_until = 0
	velocity = Vector2.ZERO

func update_beliefs(current_tick: int, all_agents: Array[Agent], map_data: MapData):
	"""Update agent's beliefs about other agents (partial observability)"""
	for other in all_agents:
		if other == self or not other.is_alive():
			continue
		
		# Check if can see the agent
		if _can_see(other, map_data):
			# Update belief with actual information
			beliefs[other.agent_id] = {
				"position": other.position,
				"health": other.health,
				"state": other.current_state,
				"confidence": 1.0
			}
			last_seen[other.agent_id] = current_tick
		else:
			# Decay belief confidence over time
			if other.agent_id in beliefs:
				var ticks_since_seen = current_tick - last_seen.get(other.agent_id, 0)
				var confidence = max(0.0, 1.0 - (ticks_since_seen * 0.05))
				beliefs[other.agent_id]["confidence"] = confidence
				
				if confidence <= 0.0:
					beliefs.erase(other.agent_id)

func _can_see(other: Agent, map_data: MapData) -> bool:
	"""Check if this agent can see another agent"""
	if is_flashed():
		return false
	
	var distance = position.distance_to(other.position)
	if distance > 50.0:  # Vision range
		return false
	
	# Check for smoke blocking vision
	for smoke_pos in smoke_positions:
		if _line_intersects_smoke(position, other.position, smoke_pos):
			return false
	
	# Check line of sight with map occluders
	if map_data:
		return map_data.check_line_of_sight(position, other.position)
	
	return true

func _line_intersects_smoke(from: Vector2, to: Vector2, smoke_center: Vector2) -> bool:
	"""Check if line of sight passes through smoke"""
	var smoke_radius = 5.0
	var closest = _closest_point_on_line(from, to, smoke_center)
	return closest.distance_to(smoke_center) < smoke_radius

func _closest_point_on_line(line_start: Vector2, line_end: Vector2, point: Vector2) -> Vector2:
	"""Find closest point on line segment to given point"""
	var line = line_end - line_start
	var len_squared = line.length_squared()
	if len_squared == 0:
		return line_start
	var t = clamp((point - line_start).dot(line) / len_squared, 0.0, 1.0)
	return line_start + t * line

func make_decision(current_tick: int, rng: RandomNumberGenerator):
	"""Make tactical decision based on beliefs"""
	if not is_alive():
		return
	
	# Find enemies in beliefs
	var known_enemies = []
	for agent_id in beliefs:
		var belief = beliefs[agent_id]
		if belief.confidence > 0.3:
			# Check if it's an enemy (different team)
			# This is simplified - in real implementation would track teams
			known_enemies.append(belief)
	
	if known_enemies.size() > 0:
		# Choose target
		var target_belief = known_enemies[rng.randi() % known_enemies.size()]
		target_position = target_belief.position
		current_state = State.ATTACKING
		
		# Randomly decide to use smoke or flash
		if rng.randf() < 0.05:  # 5% chance to use smoke
			pending_smoke = position + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10))
			has_smoke_pending = true
		
		if rng.randf() < 0.03:  # 3% chance to use flash
			pending_flash = target_position
			has_flash_pending = true
	else:
		# No enemies known, move randomly
		if rng.randf() < 0.1:  # 10% chance to pick new random position
			target_position = Vector2(rng.randf_range(0, 100), rng.randf_range(0, 100))
			current_state = State.MOVING

func apply_action(current_tick: int, delta: float):
	"""Apply the current action"""
	if not is_alive():
		return
	
	match current_state:
		State.MOVING, State.ATTACKING:
			# Move towards target
			var direction = (target_position - position).normalized()
			velocity = direction * move_speed
			position += velocity * delta
			position_changed.emit(position)

func take_damage(amount: float, tick: int):
	"""Take damage"""
	health -= amount
	health_changed.emit(health)
	
	if health <= 0:
		health = 0
		died.emit()

func is_alive() -> bool:
	return health > 0

func is_flashed() -> bool:
	return is_flashed_until > 0

func notify_flashed(current_tick: int, distance: float):
	"""Notify that agent was flashed"""
	var duration = int(10.0 * (1.0 - distance / 20.0))  # Closer = longer flash
	is_flashed_until = max(is_flashed_until, current_tick + duration)

func notify_smoke_deployed(pos: Vector2, current_tick: int):
	"""Notify about smoke deployment (with comm delay)"""
	smoke_positions.append(pos)
	# In a more complex system, this would be delayed

func has_pending_smoke() -> bool:
	return has_smoke_pending

func get_pending_smoke_position() -> Vector2:
	has_smoke_pending = false
	return pending_smoke

func has_pending_flash() -> bool:
	return has_flash_pending

func get_pending_flash_position() -> Vector2:
	has_flash_pending = false
	return pending_flash

func get_current_target() -> Agent:
	return current_target

func get_damage() -> float:
	return 25.0

func get_state() -> Dictionary:
	"""Get current state for serialization"""
	return {
		"id": agent_id,
		"team": team,
		"position": {"x": position.x, "y": position.y},
		"velocity": {"x": velocity.x, "y": velocity.y},
		"health": health,
		"state": current_state,
		"is_flashed": is_flashed()
	}

func set_state(state: Dictionary):
	"""Restore state from dictionary"""
	agent_id = state.id
	team = state.team
	position = Vector2(state.position.x, state.position.y)
	velocity = Vector2(state.velocity.x, state.velocity.y)
	health = state.health
	current_state = state.state
