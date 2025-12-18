extends RefCounted
class_name DuelResolver

## High-level duel resolver that switches between engines based on LOD
## Uses raycast for on-camera/important duels, TTK for background resolution

enum LODLevel { LOW, MEDIUM, HIGH }

var raycast_engine: RaycastDuelEngine
var ttk_engine: TTKDuelEngine
var map_data: MapData

# Configuration
var high_lod_threshold: float = 0.3  # Switch to raycast if win probability impact > this
var spectator_viewport: Rect2 = Rect2(0, 0, 100, 100)
var clutch_threshold: int = 2  # Players alive threshold for clutch detection

func _init():
	raycast_engine = RaycastDuelEngine.new()
	ttk_engine = TTKDuelEngine.new()

func set_seed(seed: int):
	raycast_engine.set_seed(seed)
	ttk_engine.set_seed(seed)

func set_map(map: MapData):
	map_data = map
	raycast_engine.set_map(map)

func set_spectator_viewport(viewport: Rect2):
	spectator_viewport = viewport

func resolve_duel(context: DuelContext, 
				   alive_attackers: int = 5, 
				   alive_defenders: int = 5) -> DuelResult:
	##Resolve a duel using appropriate engine based on LOD##
	var lod = _determine_lod(context, alive_attackers, alive_defenders)
	
	match lod:
		LODLevel.HIGH:
			return raycast_engine.simulate(context)
		LODLevel.MEDIUM:
			# Use raycast but with simplified calculation
			return raycast_engine.simulate(context)
		LODLevel.LOW:
			# Use TTK engine and convert to single result
			var summary = ttk_engine.simulate(context, 32)
			return _summary_to_result(summary, context)

func _determine_lod(context: DuelContext, 
					 alive_attackers: int, 
					 alive_defenders: int) -> LODLevel:
	##Determine which LOD level to use for this duel##
	
	# Check if in spectator viewport
	if _is_in_viewport(context):
		return LODLevel.HIGH
	
	# Check for clutch situation
	if _is_clutch(alive_attackers, alive_defenders):
		return LODLevel.HIGH
	
	# Check round impact
	var impact = _estimate_round_impact(context, alive_attackers, alive_defenders)
	if impact > high_lod_threshold:
		return LODLevel.MEDIUM
	
	return LODLevel.LOW

func _is_in_viewport(context: DuelContext) -> bool:
	##Check if duel is within spectator viewport##
	if not context.shooter_state or not context.target_state:
		return false
	
	return spectator_viewport.has_point(context.shooter_state.pos) or \
		   spectator_viewport.has_point(context.target_state.pos)

func _is_clutch(alive_attackers: int, alive_defenders: int) -> bool:
	##Check if this is a clutch situation##
	return alive_attackers <= clutch_threshold or alive_defenders <= clutch_threshold

func _estimate_round_impact(context: DuelContext, 
							 alive_attackers: int, 
							 alive_defenders: int) -> float:
	##Estimate how much this duel affects round outcome##
	var total_alive = alive_attackers + alive_defenders
	if total_alive <= 2:
		return 1.0  # Very high impact
	
	# Simple impact model: fewer players = higher impact
	var base_impact = 2.0 / float(total_alive)
	
	# Adjust for player importance (could use skill ratings)
	return clampf(base_impact, 0.0, 1.0)

func _summary_to_result(summary: Dictionary, context: DuelContext) -> DuelResult:
	##Convert TTK engine summary to DuelResult##
	var result = DuelResult.new()
	
	# Use median TTK
	result.ttk = summary.get("median_ttk", INF)
	
	# Determine winner based on probability
	var win_prob = summary.get("win_probability", 0.5)
	if ttk_engine.rng.randf() < win_prob:
		result.winner_id = summary.get("shooter_id", -1)
		result.loser_id = summary.get("target_id", -1)
	else:
		result.winner_id = -1
		result.loser_id = -1
	
	# Estimate shots/hits from accuracy
	var avg_accuracy = summary.get("avg_accuracy", 0.3)
	var target_hp = context.target_state.hp if context.target_state else 100.0
	var avg_damage = 30.0
	if context.weapon_def and context.weapon_def.damage:
		avg_damage = context.weapon_def.damage.base_damage
	
	var estimated_hits = int(ceil(target_hp / avg_damage))
	result.hits = estimated_hits
	result.shots_fired = int(ceil(estimated_hits / avg_accuracy)) if avg_accuracy > 0 else estimated_hits * 3
	result.damage_dealt = target_hp if result.winner_id != -1 else 0.0
	result.headshots = int(result.hits * summary.get("avg_headshot_rate", 0.15))
	
	return result

## Batch resolution for multiple duels
func resolve_batch(contexts: Array, alive_attackers: int = 5, alive_defenders: int = 5) -> Array:
	##Resolve multiple duels efficiently##
	var results = []
	
	# Sort by importance (high LOD first)
	var sorted_contexts = contexts.duplicate()
	sorted_contexts.sort_custom(func(a, b): 
		return _determine_lod(a, alive_attackers, alive_defenders) > \
			   _determine_lod(b, alive_attackers, alive_defenders))
	
	for context in sorted_contexts:
		results.append(resolve_duel(context, alive_attackers, alive_defenders))
	
	return results

## Quick win probability check without full simulation
## Returns: 1 if A wins, -1 if B wins, 0 if uncertain
func quick_compare(context_a: DuelContext, context_b: DuelContext) -> int:
	var prob_a = ttk_engine.quick_win_probability(context_a)
	var prob_b = ttk_engine.quick_win_probability(context_b)
	
	if prob_a > prob_b + 0.1:
		return 1
	elif prob_b > prob_a + 0.1:
		return -1
	return 0
