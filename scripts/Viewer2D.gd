extends Node2D
class_name Viewer2D

## Top-down 2D viewer with interpolation for smooth rendering

var agents: Array[Agent] = []
var map_data: MapData
var camera: Camera2D

# Interpolation state
var agent_visual_positions: Dictionary = {}  # agent_id -> Vector2
var interpolation_alpha: float = 0.0

# Rendering settings
var agent_radius: float = 3.0
var team_a_color: Color = Color.BLUE
var team_b_color: Color = Color.RED
var occluder_color: Color = Color.DIM_GRAY
var zone_color: Color = Color(1.0, 1.0, 1.0, 0.2)
var smoke_color: Color = Color(0.7, 0.7, 0.7, 0.5)

# Smoke visualization
var active_smokes: Array[Dictionary] = []  # {position, deploy_tick}

func _ready():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	center_camera()

func setup(match_agents: Array[Agent], match_map: MapData):
	"""Setup viewer with agents and map"""
	agents = match_agents
	map_data = match_map
	
	# Initialize visual positions
	for agent in agents:
		agent_visual_positions[agent.agent_id] = agent.position
	
	center_camera()
	queue_redraw()

func center_camera():
	"""Center camera on map"""
	if map_data:
		camera.position = Vector2(map_data.width / 2, map_data.height / 2)
		# Adjust zoom to fit map
		var screen_size = get_viewport_rect().size
		var zoom_x = screen_size.x / map_data.width
		var zoom_y = screen_size.y / map_data.height
		var zoom_level = min(zoom_x, zoom_y) * 0.8
		camera.zoom = Vector2(zoom_level, zoom_level)

func update_interpolation(alpha: float):
	"""Update interpolation between simulation ticks"""
	interpolation_alpha = alpha
	
	# Interpolate agent positions
	for agent in agents:
		if agent.agent_id in agent_visual_positions:
			var current_visual = agent_visual_positions[agent.agent_id]
			var target = agent.position
			agent_visual_positions[agent.agent_id] = current_visual.lerp(target, 0.3)
	
	queue_redraw()

func notify_smoke_deployed(position: Vector2, tick: int):
	"""Add smoke to visualization"""
	active_smokes.append({"position": position, "deploy_tick": tick})

func _draw():
	"""Draw the tactical view"""
	if not map_data:
		return
	
	# Draw map background
	draw_rect(Rect2(0, 0, map_data.width, map_data.height), Color(0.1, 0.1, 0.1))
	
	# Draw zones
	for zone in map_data.zones:
		var rect = Rect2(zone.x, zone.y, zone.width, zone.height)
		draw_rect(rect, zone_color, false, 1.0)
	
	# Draw occluders
	for occluder in map_data.occluders:
		var rect = Rect2(occluder.x, occluder.y, occluder.width, occluder.height)
		draw_rect(rect, occluder_color, true)
		draw_rect(rect, Color.WHITE, false, 1.0)
	
	# Draw smoke
	for smoke in active_smokes:
		draw_circle(smoke.position, 5.0, smoke_color)
	
	# Draw agents
	for agent in agents:
		if not agent.is_alive():
			continue
		
		var pos = agent_visual_positions.get(agent.agent_id, agent.position)
		var color = team_a_color if agent.team == Agent.Team.TEAM_A else team_b_color
		
		# Draw agent circle
		draw_circle(pos, agent_radius, color)
		
		# Draw direction indicator
		if agent.velocity.length() > 0.1:
			var direction = agent.velocity.normalized()
			var end_pos = pos + direction * (agent_radius + 3)
			draw_line(pos, end_pos, color, 2.0)
		
		# Draw health bar
		var health_ratio = agent.health / agent.max_health
		var bar_width = agent_radius * 2
		var bar_height = 2.0
		var bar_pos = pos + Vector2(-bar_width / 2, -agent_radius - 5)
		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.RED)
		draw_rect(Rect2(bar_pos, Vector2(bar_width * health_ratio, bar_height)), Color.GREEN)
		
		# Draw flash indicator
		if agent.is_flashed():
			draw_circle(pos, agent_radius + 2, Color(1, 1, 0, 0.3))

func _process(_delta):
	"""Update visual state"""
	queue_redraw()
