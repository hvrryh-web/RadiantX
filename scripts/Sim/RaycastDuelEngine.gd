extends RefCounted
class_name RaycastDuelEngine

## Full hitscan raycast duel engine
## Provides high-fidelity shot-by-shot simulation
## Best for on-camera engagements and clutch moments

var rng: RandomNumberGenerator
var map_data: MapData

func _init():
	rng = RandomNumberGenerator.new()

func set_seed(seed: int):
	rng.seed = seed

func set_map(map: MapData):
	map_data = map

func simulate(context: DuelContext) -> DuelResult:
	##Simulate a full duel with raycasts##
	var result = DuelResult.new()
	
	# Clone states for simulation
	var shooter = _clone_agent_state(context.shooter_state)
	var target = _clone_agent_state(context.target_state)
	
	var time = 0.0
	var shot_interval = context.get_shot_interval()
	
	# Initial reaction time
	shooter.reaction_timer = context.compute_reaction_time()
	
	while target.hp > 0 and time < context.max_duel_time:
		# Update reaction timer
		if shooter.reaction_timer > 0:
			var step = minf(shooter.reaction_timer, shot_interval)
			time += step
			shooter.reaction_timer -= step
			continue
		
		# Check if can fire
		if not _can_fire(shooter, context.weapon_def):
			# Handle reload
			if shooter.weapon.ammo_in_mag <= 0:
				shooter.weapon.start_reload(context.weapon_def)
			
			# Step time
			time += 0.05  # 50ms steps
			shooter.weapon.update(0.05, context.weapon_def)
			continue
		
		# Fire shot
		var shot_result = _fire_shot(shooter, target, context, time)
		result.events.append(shot_result)
		result.shots_fired += 1
		
		if shot_result.hit:
			result.hits += 1
			result.damage_dealt += shot_result.damage
			target.hp -= shot_result.damage
			
			if shot_result.hit_zone == DataTypes.HitZone.HEAD:
				result.headshots += 1
		
		# Update weapon state
		shooter.weapon.fire(context.weapon_def)
		
		time += shot_interval
	
	result.ttk = time if target.hp <= 0 else INF
	if target.hp <= 0:
		result.winner_id = shooter.entity_id
		result.loser_id = target.entity_id
	
	return result

func _can_fire(agent: AgentState, weapon_def: WeaponDef) -> bool:
	##Check if agent can fire##
	if agent.reaction_timer > 0:
		return false
	if agent.is_flashed() and agent.status.flash_timer > 1.0:
		return false  # Fully flashed
	if not agent.weapon:
		return false
	return agent.weapon.can_fire()

func _fire_shot(shooter: AgentState, target: AgentState, context: DuelContext, time: float) -> SimEvent.ShotEvent:
	##Fire a single shot using raycast##
	var event = SimEvent.ShotEvent.new(time, shooter.entity_id, target.entity_id, 
									   shooter.weapon.weapon_id)
	
	# Compute aim direction
	var aim_dir = (target.pos - shooter.pos).normalized()
	
	# Apply spread
	var sigma = context.compute_aim_sigma()
	var angle_offset = _sample_gaussian(0.0, sigma)
	aim_dir = aim_dir.rotated(angle_offset)
	
	# Raycast
	var ray_end = shooter.pos + aim_dir * (context.distance + 10.0)
	var hit_info = _raycast(shooter.pos, ray_end, target)
	
	if hit_info.hit_target:
		event.hit = true
		event.hit_zone = _determine_hit_zone(context)
		
		# Calculate damage
		if context.weapon_def and context.weapon_def.damage:
			event.damage = context.weapon_def.damage.get_damage_for_zone(
				event.hit_zone, context.distance)
		else:
			event.damage = 30.0
	
	return event

func _raycast(from: Vector2, to: Vector2, target: AgentState) -> Dictionary:
	##Perform raycast, returns hit information##
	var result = {"hit_target": false, "hit_wall": false, "hit_pos": to}
	
	# Check map occlusion first
	if map_data and not map_data.check_line_of_sight(from, to):
		result.hit_wall = true
		return result
	
	# Check if ray hits target (simplified circular hitbox)
	var target_radius = 0.5  # World units
	var closest_point = _closest_point_on_line(from, to, target.pos)
	var distance_to_target = closest_point.distance_to(target.pos)
	
	if distance_to_target < target_radius:
		result.hit_target = true
		result.hit_pos = closest_point
	
	return result

func _closest_point_on_line(line_start: Vector2, line_end: Vector2, point: Vector2) -> Vector2:
	##Find closest point on line segment to given point##
	var line = line_end - line_start
	var len_squared = line.length_squared()
	if len_squared == 0:
		return line_start
	var t = clampf((point - line_start).dot(line) / len_squared, 0.0, 1.0)
	return line_start + t * line

func _determine_hit_zone(context: DuelContext) -> int:
	##Determine which body zone was hit##
	var head_share = context.compute_head_share()
	var leg_share = 0.1  # 10% leg hits
	
	var roll = rng.randf()
	if roll < head_share:
		return DataTypes.HitZone.HEAD
	elif roll < head_share + (1 - head_share - leg_share):
		return DataTypes.HitZone.TORSO
	else:
		return DataTypes.HitZone.LEGS

func _sample_gaussian(mean: float, std_dev: float) -> float:
	##Sample from Gaussian distribution using Box-Muller transform##
	var u1 = maxf(0.0001, rng.randf())  # Avoid log(0)
	var u2 = rng.randf()
	var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + std_dev * z

func _clone_agent_state(state: AgentState) -> AgentState:
	##Create a copy of agent state for simulation##
	if not state:
		return AgentState.new()
	
	var clone = AgentState.new()
	clone.agent_id = state.agent_id
	clone.entity_id = state.entity_id
	clone.side = state.side
	clone.pos = state.pos
	clone.vel = state.vel
	clone.facing_rad = state.facing_rad
	clone.stance = state.stance
	clone.hp = state.hp
	clone.armor = state.armor
	clone.stress = state.stress
	clone.reaction_timer = state.reaction_timer
	
	if state.weapon:
		clone.weapon = WeaponState.from_dict(state.weapon.to_dict())
	if state.status:
		clone.status = StatusState.from_dict(state.status.to_dict())
	
	return clone

## Check smoke occlusion along ray
func check_smoke_occlusion(from: Vector2, to: Vector2, smoke_volumes: Array) -> float:
	##Calculate accumulated smoke density along a ray
	Returns 0..1 opacity (0 = clear, 1 = fully blocked)##
	var total_density = 0.0
	var ray_length = from.distance_to(to)
	
	for smoke in smoke_volumes:
		if not smoke is Dictionary:
			continue
		
		var smoke_pos = Vector2(smoke.get("x", 0), smoke.get("y", 0))
		var smoke_radius = smoke.get("radius", 4.5)
		var smoke_density = smoke.get("density", 1.0)
		
		# Find closest point on ray to smoke center
		var closest = _closest_point_on_line(from, to, smoke_pos)
		var dist_to_center = closest.distance_to(smoke_pos)
		
		if dist_to_center < smoke_radius:
			# Calculate path length through smoke
			var path_length = 2.0 * sqrt(smoke_radius * smoke_radius - dist_to_center * dist_to_center)
			var contribution = (path_length / smoke_radius) * smoke_density
			total_density += contribution
	
	return clampf(total_density, 0.0, 1.0)
