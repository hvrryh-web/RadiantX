extends Resource
class_name MapData

## Map data with zones and occluders for tactical gameplay

var map_name: String = ""
var width: float = 100.0
var height: float = 100.0
var zones: Array[Dictionary] = []
var occluders: Array[Dictionary] = []

func _init():
	pass

static func load_from_json(json_path: String) -> MapData:
	"""Load map from JSON file"""
	var map = MapData.new()
	
	if not FileAccess.file_exists(json_path):
		push_error("Map file not found: " + json_path)
		return map
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Failed to open map file: " + json_path)
		return map
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return map
	
	var data = json.data
	
	map.map_name = data.get("name", "Unnamed Map")
	map.width = data.get("width", 100.0)
	map.height = data.get("height", 100.0)
	
	# Load zones
	if data.has("zones"):
		for zone_data in data.zones:
			map.zones.append({
				"id": zone_data.get("id", ""),
				"x": zone_data.get("x", 0.0),
				"y": zone_data.get("y", 0.0),
				"width": zone_data.get("width", 10.0),
				"height": zone_data.get("height", 10.0)
			})
	
	# Load occluders
	if data.has("occluders"):
		for occluder_data in data.occluders:
			map.occluders.append({
				"x": occluder_data.get("x", 0.0),
				"y": occluder_data.get("y", 0.0),
				"width": occluder_data.get("width", 10.0),
				"height": occluder_data.get("height", 10.0)
			})
	
	return map

func check_line_of_sight(from: Vector2, to: Vector2) -> bool:
	"""Check if there's line of sight between two points (not blocked by occluders)"""
	for occluder in occluders:
		if _line_intersects_rect(from, to, occluder):
			return false
	return true

func _line_intersects_rect(line_start: Vector2, line_end: Vector2, rect: Dictionary) -> bool:
	"""Check if line segment intersects with rectangle"""
	var rx = rect.x
	var ry = rect.y
	var rw = rect.width
	var rh = rect.height
	
	# Check if line intersects any of the four edges of the rectangle
	var corners = [
		Vector2(rx, ry),
		Vector2(rx + rw, ry),
		Vector2(rx + rw, ry + rh),
		Vector2(rx, ry + rh)
	]
	
	# Check intersection with each edge
	for i in range(4):
		var edge_start = corners[i]
		var edge_end = corners[(i + 1) % 4]
		if _lines_intersect(line_start, line_end, edge_start, edge_end):
			return true
	
	# Also check if either endpoint is inside the rectangle
	if _point_in_rect(line_start, rect) or _point_in_rect(line_end, rect):
		return true
	
	return false

func _lines_intersect(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
	"""Check if two line segments intersect"""
	var d = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
	if abs(d) < 0.0001:
		return false
	
	var t = ((p3.x - p1.x) * (p4.y - p3.y) - (p3.y - p1.y) * (p4.x - p3.x)) / d
	var u = ((p3.x - p1.x) * (p2.y - p1.y) - (p3.y - p1.y) * (p2.x - p1.x)) / d
	
	return t >= 0 and t <= 1 and u >= 0 and u <= 1

func _point_in_rect(point: Vector2, rect: Dictionary) -> bool:
	"""Check if point is inside rectangle"""
	return point.x >= rect.x and point.x <= rect.x + rect.width and point.y >= rect.y and point.y <= rect.y + rect.height

func get_zone_by_id(zone_id: String) -> Dictionary:
	"""Get zone by ID"""
	for zone in zones:
		if zone.id == zone_id:
			return zone
	return {}

func get_spawn_position(team: int) -> Vector2:
	"""Get spawn position for team"""
	var zone_id = "spawn_a" if team == 0 else "spawn_b"
	var zone = get_zone_by_id(zone_id)
	if zone.is_empty():
		return Vector2(10 if team == 0 else 90, 10 if team == 0 else 90)
	return Vector2(zone.x + zone.width / 2, zone.y + zone.height / 2)
