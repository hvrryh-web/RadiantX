extends Node
class_name EventLog

## Event logging system for match replay functionality

var events: Array[Dictionary] = []
var max_events: int = 100000  # Limit to prevent memory issues

func clear():
	"""Clear all logged events"""
	events.clear()

func log_event(event: Dictionary):
	"""Log an event"""
	if events.size() >= max_events:
		push_warning("Event log reached maximum size, not logging further events")
		return
	
	events.append(event)

func get_events() -> Array[Dictionary]:
	"""Get all logged events"""
	return events

func get_events_for_tick(tick: int) -> Array[Dictionary]:
	"""Get all events that occurred at a specific tick"""
	var tick_events: Array[Dictionary] = []
	for event in events:
		if event.get("tick", -1) == tick:
			tick_events.append(event)
	return tick_events

func get_events_in_range(start_tick: int, end_tick: int) -> Array[Dictionary]:
	"""Get all events within a tick range"""
	var range_events: Array[Dictionary] = []
	for event in events:
		var tick = event.get("tick", -1)
		if tick >= start_tick and tick <= end_tick:
			range_events.append(event)
	return range_events

func save_to_file(file_path: String) -> bool:
	"""Save event log to file for replay"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: " + file_path)
		return false
	
	var data = {
		"version": 1,
		"events": events
	}
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_from_file(file_path: String) -> bool:
	"""Load event log from file"""
	if not FileAccess.file_exists(file_path):
		push_error("Replay file not found: " + file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open replay file: " + file_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Failed to parse replay JSON: " + json.get_error_message())
		return false
	
	var data = json.data
	
	if not data.has("events"):
		push_error("Invalid replay file format")
		return false
	
	events = []
	for event in data.events:
		events.append(event)
	
	return true

func get_match_duration() -> int:
	"""Get the duration of the match in ticks"""
	if events.is_empty():
		return 0
	
	var max_tick = 0
	for event in events:
		var tick = event.get("tick", 0)
		if tick > max_tick:
			max_tick = tick
	
	return max_tick

func get_match_seed() -> int:
	"""Get the match seed from the log"""
	for event in events:
		if event.get("type", "") == "match_start":
			return event.get("seed", 0)
	return 0
