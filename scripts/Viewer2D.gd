extends Node2D
class_name Viewer2D

## Top-down 2D viewer with interpolation for smooth rendering

var agents: Array[Agent] = []
var map_data: MapData
var camera: Camera2D

# Interpolation state
var agent_visual_positions: Dictionary = {}  # agent_id -> Vector2
var interpolation_alpha: float = 0.0

# Rendering settings - improved for accessibility
var agent_radius: float = 6.0  # Doubled for visibility
# Accessible color scheme - colorblind-friendly
var team_a_color: Color = Color("#3B82F6")  # Blue-500
var team_b_color: Color = Color("#F97316")  # Orange-500 (better than red for colorblind)
var team_a_dark: Color = Color("#1E40AF")   # Darker blue for outlines
var team_b_dark: Color = Color("#C2410C")   # Darker orange for outlines
# Map elements with proper contrast
var map_background: Color = Color("#0F172A")  # Slate-900
var occluder_fill: Color = Color("#334155")   # Slate-700
var occluder_border: Color = Color("#64748B") # Slate-500
var zone_fill: Color = Color("#FDE047", 0.2)  # Yellow-300 at 20%
var zone_border: Color = Color("#FACC15")     # Yellow-400
var smoke_color: Color = Color("#94A3B8", 0.7) # Slate-400 at 70%

# Smoke visualization
var active_smokes: Array[Dictionary] = []  # {position, deploy_tick}

# Dirty flag for optimized redraw
var needs_redraw: bool = true

func _ready():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	center_camera()

func setup(match_agents: Array[Agent], match_map: MapData):
	# Setup viewer with agents and map
	agents = match_agents
	map_data = match_map
	
	# Initialize visual positions
	for agent in agents:
		agent_visual_positions[agent.agent_id] = agent.position
	
	center_camera()
	queue_redraw()

func center_camera():
	# Center camera on map
	if map_data:
		camera.position = Vector2(map_data.width / 2, map_data.height / 2)
		# Adjust zoom to fit map
		var screen_size = get_viewport_rect().size
		var zoom_x = screen_size.x / map_data.width
		var zoom_y = screen_size.y / map_data.height
		var zoom_level = min(zoom_x, zoom_y) * 0.8
		camera.zoom = Vector2(zoom_level, zoom_level)

func update_interpolation(alpha: float):
	# Update interpolation between simulation ticks
	interpolation_alpha = alpha
	
	# Interpolate agent positions
	for agent in agents:
		if agent.agent_id in agent_visual_positions:
			var current_visual = agent_visual_positions[agent.agent_id]
			var target = agent.position
			agent_visual_positions[agent.agent_id] = current_visual.lerp(target, 0.3)
	
	needs_redraw = true

func mark_dirty():
	needs_redraw = true

func notify_smoke_deployed(position: Vector2, tick: int):
	# Add smoke to visualization
	active_smokes.append({"position": position, "deploy_tick": tick})
	needs_redraw = true

func _get_health_color(ratio: float) -> Color:
	"""Get health bar color based on health ratio - colorblind accessible"""
	if ratio > 0.6:
		return Color("#22C55E")  # Green
	elif ratio > 0.3:
		return Color("#EAB308")  # Yellow/amber
	else:
		return Color("#EF4444")  # Red

func _draw():
	# Draw the tactical view
	if not map_data:
		return
	
	# Draw map background
	draw_rect(Rect2(0, 0, map_data.width, map_data.height), map_background)
	
	# Draw zones with improved contrast
	for zone in map_data.zones:
		var rect = Rect2(zone.x, zone.y, zone.width, zone.height)
		draw_rect(rect, zone_fill, true)
		draw_rect(rect, zone_border, false, 1.5)
	
	# Draw occluders with improved colors
	for occluder in map_data.occluders:
		var rect = Rect2(occluder.x, occluder.y, occluder.width, occluder.height)
		draw_rect(rect, occluder_fill, true)
		draw_rect(rect, occluder_border, false, 1.0)
	
	# Draw smoke
	for smoke in active_smokes:
		draw_circle(smoke.position, 5.0, smoke_color)
	
	# Draw agents with improved visibility and colorblind accessibility
	for agent in agents:
		if not agent.is_alive():
			continue
		
		var pos = agent_visual_positions.get(agent.agent_id, agent.position)
		var color = team_a_color if agent.team == Agent.Team.TEAM_A else team_b_color
		var dark_color = team_a_dark if agent.team == Agent.Team.TEAM_A else team_b_dark
		
		# Draw agent circle with outline
		draw_circle(pos, agent_radius, color)
		draw_arc(pos, agent_radius, 0, TAU, 32, dark_color, 1.5)
		
		# Add team shape indicator (colorblind accessible)
		if agent.team == Agent.Team.TEAM_A:
			# Circle with inner dot for Team A
			draw_circle(pos, agent_radius * 0.35, Color.WHITE)
		else:
			# Diamond shape overlay for Team B
			var diamond = PackedVector2Array([
				pos + Vector2(0, -agent_radius * 0.5),
				pos + Vector2(agent_radius * 0.5, 0),
				pos + Vector2(0, agent_radius * 0.5),
				pos + Vector2(-agent_radius * 0.5, 0)
			])
			draw_colored_polygon(diamond, Color.WHITE)
		
		# Draw direction indicator
		if agent.velocity.length() > 0.1:
			var direction = agent.velocity.normalized()
			var end_pos = pos + direction * (agent_radius + 4)
			draw_line(pos, end_pos, Color.WHITE, 2.0)
		
		# Draw health bar with improved sizing and colors
		var health_ratio = agent.health / agent.max_health
		var bar_width = agent_radius * 3
		var bar_height = 4.0
		var bar_pos = pos + Vector2(-bar_width / 2, -agent_radius - 8)
		# Background bar
		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color("#1F2937"))
		# Health fill with gradient color
		var health_color = _get_health_color(health_ratio)
		draw_rect(Rect2(bar_pos, Vector2(bar_width * health_ratio, bar_height)), health_color)
		# Border
		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color("#6B7280"), false, 1.0)
		
		# Draw flash indicator (more visible)
		if agent.is_flashed():
			draw_arc(pos, agent_radius + 3, 0, TAU, 32, Color.YELLOW, 2.0)

func _process(_delta):
	# Update visual state only when needed
	if needs_redraw:
		queue_redraw()
		needs_redraw = false
