extends Node

## Determinism test to verify matches are reproducible with same seed

var test_results: Dictionary = {}

func _ready():
	print("=== RadiantX Determinism Test ===")
	run_tests()

func run_tests():
	"""Run all determinism tests"""
	test_same_seed_same_results()
	test_different_seed_different_results()
	test_replay_consistency()
	
	print("\n=== Test Results ===")
	var passed = 0
	var failed = 0
	for test_name in test_results:
		var result = test_results[test_name]
		print("%s: %s" % [test_name, "PASS" if result else "FAIL"])
		if result:
			passed += 1
		else:
			failed += 1
	
	print("\nTotal: %d passed, %d failed" % [passed, failed])
	
	if failed == 0:
		print("\n✓ All determinism tests passed!")
	else:
		print("\n✗ Some tests failed")

func test_same_seed_same_results():
	"""Test that same seed produces same results"""
	print("\nTest: Same seed produces same results")
	
	var seed = 12345
	var events1 = run_match_simulation(seed, 100)
	var events2 = run_match_simulation(seed, 100)
	
	var matches = compare_event_logs(events1, events2)
	test_results["same_seed_same_results"] = matches
	
	if matches:
		print("  ✓ Event logs match perfectly")
	else:
		print("  ✗ Event logs differ")
		print("    Events 1: %d, Events 2: %d" % [events1.size(), events2.size()])

func test_different_seed_different_results():
	"""Test that different seeds produce different results"""
	print("\nTest: Different seeds produce different results")
	
	var events1 = run_match_simulation(12345, 100)
	var events2 = run_match_simulation(54321, 100)
	
	var differs = not compare_event_logs(events1, events2)
	test_results["different_seed_different_results"] = differs
	
	if differs:
		print("  ✓ Event logs differ as expected")
	else:
		print("  ✗ Event logs are identical (should differ)")

func test_replay_consistency():
	"""Test that replays can be loaded and match original"""
	print("\nTest: Replay consistency")
	
	var seed = 99999
	var original_events = run_match_simulation(seed, 50)
	
	# Save to temporary file
	var temp_file = "user://test_replay.json"
	var event_log = EventLog.new()
	for event in original_events:
		event_log.log_event(event)
	
	var saved = event_log.save_to_file(temp_file)
	if not saved:
		test_results["replay_consistency"] = false
		print("  ✗ Failed to save replay")
		return
	
	# Load back
	var loaded_log = EventLog.new()
	var loaded = loaded_log.load_from_file(temp_file)
	if not loaded:
		test_results["replay_consistency"] = false
		print("  ✗ Failed to load replay")
		return
	
	var loaded_events = loaded_log.get_events()
	var matches = compare_event_logs(original_events, loaded_events)
	test_results["replay_consistency"] = matches
	
	if matches:
		print("  ✓ Replay matches original")
	else:
		print("  ✗ Replay differs from original")

func run_match_simulation(seed: int, ticks: int) -> Array[Dictionary]:
	"""Run a simplified match simulation and return events"""
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	
	var events: Array[Dictionary] = []
	
	# Start event
	events.append({
		"type": "match_start",
		"tick": 0,
		"seed": seed
	})
	
	# Simulate some events
	var agent_positions = []
	for i in range(10):
		agent_positions.append(Vector2(rng.randf() * 100, rng.randf() * 100))
	
	for tick in range(1, ticks):
		# Move agents
		for i in range(agent_positions.size()):
			var direction = Vector2(rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized()
			agent_positions[i] += direction * 0.5
		
		# Random combat events
		if rng.randf() < 0.1:  # 10% chance
			events.append({
				"type": "hit",
				"tick": tick,
				"attacker_id": rng.randi() % 5,
				"target_id": 5 + (rng.randi() % 5)
			})
		
		# Random utility usage
		if rng.randf() < 0.05:  # 5% chance
			events.append({
				"type": "smoke_deployed",
				"tick": tick,
				"agent_id": rng.randi() % 10,
				"position": {"x": rng.randf() * 100, "y": rng.randf() * 100}
			})
	
	# End event
	events.append({
		"type": "match_end",
		"tick": ticks
	})
	
	return events

func compare_event_logs(events1: Array[Dictionary], events2: Array[Dictionary]) -> bool:
	"""Compare two event logs for equality"""
	if events1.size() != events2.size():
		return false
	
	for i in range(events1.size()):
		var e1 = events1[i]
		var e2 = events2[i]
		
		# Compare all keys
		if e1.size() != e2.size():
			return false
		
		for key in e1:
			if not e2.has(key):
				return false
			
			# Compare values
			var v1 = e1[key]
			var v2 = e2[key]
			
			if typeof(v1) != typeof(v2):
				return false
			
			if typeof(v1) == TYPE_DICTIONARY:
				# Compare dictionary recursively
				if not compare_dictionaries(v1, v2):
					return false
			elif v1 != v2:
				return false
	
	return true

func compare_dictionaries(d1: Dictionary, d2: Dictionary) -> bool:
	"""Compare two dictionaries"""
	if d1.size() != d2.size():
		return false
	
	for key in d1:
		if not d2.has(key):
			return false
		if d1[key] != d2[key]:
			return false
	
	return true
