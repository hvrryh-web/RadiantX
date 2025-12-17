extends RefCounted
class_name TTKDuelEngine

## Fast time-to-kill simulation engine
## Uses probabilistic hit model for quick Monte Carlo simulation
## Best for off-camera fights and season simulations

var rng: RandomNumberGenerator

func _init():
	rng = RandomNumberGenerator.new()

func set_seed(seed: int):
	rng.seed = seed

func simulate(context: DuelContext, num_iterations: int = 64) -> Dictionary:
	"""Run Monte Carlo simulation and return TTK distribution"""
	var results = []
	
	for i in range(num_iterations):
		var result = _simulate_single(context, i)
		results.append(result)
	
	return _summarize_results(results, context)

func _simulate_single(context: DuelContext, iteration: int) -> DuelResult:
	## Simulate a single duel iteration
	var result = DuelResult.new()
	
	# Advance RNG state naturally - don't modify seed during simulation
	# Each iteration will get different values from the RNG stream
	var _skip = rng.randi()  # Advance RNG for this iteration
	
	var target_hp = context.target_state.hp if context.target_state else 100.0
	var time = context.compute_reaction_time()
	var shot_interval = context.get_shot_interval()
	var max_ammo = context.weapon_def.magazine_size if context.weapon_def else 30
	var ammo = context.shooter_state.weapon.ammo_in_mag if context.shooter_state and context.shooter_state.weapon else max_ammo
	var recoil = context.shooter_state.weapon.recoil if context.shooter_state and context.shooter_state.weapon else 0.0
	
	while target_hp > 0 and time < context.max_duel_time:
		# Check ammo
		if ammo <= 0:
			# Reload
			var reload_time = context.weapon_def.reload_time if context.weapon_def else 2.5
			time += reload_time
			ammo = max_ammo
			recoil = 0
			continue
		
		# Compute hit probability with current recoil
		var p_hit = context.compute_hit_probability()
		var head_share = context.compute_head_share()
		
		# Adjust for accumulated recoil
		var recoil_penalty = 1.0 - recoil * 0.3
		p_hit *= maxf(0.3, recoil_penalty)
		
		result.shots_fired += 1
		ammo -= 1
		
		# Roll for hit
		if rng.randf() < p_hit:
			result.hits += 1
			
			# Roll for zone
			var zone = DataTypes.HitZone.TORSO
			if rng.randf() < head_share:
				zone = DataTypes.HitZone.HEAD
				result.headshots += 1
			
			# Calculate damage
			var damage = 30.0  # Default
			if context.weapon_def and context.weapon_def.damage:
				damage = context.weapon_def.damage.get_damage_for_zone(zone, context.distance)
			
			result.damage_dealt += damage
			target_hp -= damage
		
		# Update recoil
		if context.weapon_def and context.weapon_def.recoil:
			recoil = minf(recoil + context.weapon_def.recoil.recoil_per_shot, 
						  context.weapon_def.recoil.max_recoil)
			# Slight recovery between shots
			recoil = maxf(0, recoil - context.weapon_def.recoil.recovery_per_sec * shot_interval)
		
		time += shot_interval
	
	result.ttk = time if target_hp <= 0 else INF
	if target_hp <= 0:
		result.winner_id = context.shooter_state.entity_id if context.shooter_state else 0
		result.loser_id = context.target_state.entity_id if context.target_state else 0
	
	return result

func _summarize_results(results: Array, context: DuelContext) -> Dictionary:
	"""Summarize Monte Carlo results into statistics"""
	var ttks = []
	var wins = 0
	var total_shots = 0
	var total_hits = 0
	var total_headshots = 0
	
	for result in results:
		if result.ttk < INF:
			ttks.append(result.ttk)
			wins += 1
		total_shots += result.shots_fired
		total_hits += result.hits
		total_headshots += result.headshots
	
	ttks.sort()
	
	var summary = {
		"shooter_id": context.shooter_state.entity_id if context.shooter_state else -1,
		"target_id": context.target_state.entity_id if context.target_state else -1,
		"iterations": results.size(),
		"wins": wins,
		"win_probability": float(wins) / float(results.size()) if results.size() > 0 else 0.0,
		"avg_ttk": _average(ttks),
		"median_ttk": _percentile(ttks, 0.5),
		"p10_ttk": _percentile(ttks, 0.1),
		"p90_ttk": _percentile(ttks, 0.9),
		"avg_accuracy": float(total_hits) / float(total_shots) if total_shots > 0 else 0.0,
		"avg_headshot_rate": float(total_headshots) / float(total_hits) if total_hits > 0 else 0.0
	}
	
	return summary

func _average(values: Array) -> float:
	if values.is_empty():
		return INF
	var sum = 0.0
	for v in values:
		sum += v
	return sum / values.size()

func _percentile(sorted_values: Array, p: float) -> float:
	if sorted_values.is_empty():
		return INF
	var index = int(p * (sorted_values.size() - 1))
	return sorted_values[index]

func quick_win_probability(context: DuelContext) -> float:
	"""Quick approximation of win probability without full simulation"""
	var p_hit = context.compute_hit_probability()
	var shot_interval = context.get_shot_interval()
	var target_hp = context.target_state.hp if context.target_state else 100.0
	
	# Estimate average damage per shot
	var avg_damage = 30.0
	if context.weapon_def and context.weapon_def.damage:
		var head_share = context.compute_head_share()
		var head_dmg = context.weapon_def.damage.get_damage_for_zone(DataTypes.HitZone.HEAD, context.distance)
		var body_dmg = context.weapon_def.damage.get_damage_for_zone(DataTypes.HitZone.TORSO, context.distance)
		avg_damage = head_share * head_dmg + (1 - head_share) * body_dmg
	
	# Expected shots to kill
	var expected_damage_per_shot = p_hit * avg_damage
	if expected_damage_per_shot <= 0:
		return 0.0
	
	var expected_shots = target_hp / expected_damage_per_shot
	var expected_ttk = context.compute_reaction_time() + expected_shots * shot_interval
	
	# Simple win probability based on whether we can kill before max time
	# Scale factor of 2 accounts for variance in hit probability over multiple shots
	const WIN_PROB_SCALE_FACTOR = 2.0
	if expected_ttk < context.max_duel_time:
		return minf(1.0, p_hit * WIN_PROB_SCALE_FACTOR)
	return 0.0
