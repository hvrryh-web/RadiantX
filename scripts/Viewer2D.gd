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

# Status effect colors
var flash_color: Color = Color(1.0, 1.0, 0.0, 0.3)      # Yellow
var concuss_color: Color = Color(0.8, 0.5, 1.0, 0.4)    # Purple
var slow_color: Color = Color(0.3, 0.7, 1.0, 0.4)       # Cyan
var burn_color: Color = Color(1.0, 0.4, 0.1, 0.5)       # Orange
var reveal_color: Color = Color(1.0, 1.0, 1.0, 0.6)     # White
var suppress_color: Color = Color(0.2, 0.2, 0.2, 0.5)   # Dark

# Utility effect colors
var fire_zone_color: Color = Color(1.0, 0.3, 0.0, 0.4)  # Fire/molotov
var slow_zone_color: Color = Color(0.2, 0.6, 1.0, 0.3)  # Slow field

# Accessibility settings
var colorblind_mode: bool = false

# Active effects visualization
var active_smokes: Array[Dictionary] = []  # {position, deploy_tick, radius}
var active_fires: Array[Dictionary] = []   # {position, deploy_tick, radius}
var active_walls: Array[Dictionary] = []   # {start, end, hp}

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
	
	queue_redraw()

func notify_smoke_deployed(position: Vector2, tick: int, radius: float = 5.0):
	## Add smoke to visualization
	active_smokes.append({"position": position, "deploy_tick": tick, "radius": radius})

func notify_fire_deployed(position: Vector2, tick: int, radius: float = 3.5):
	## Add fire zone to visualization
	active_fires.append({"position": position, "deploy_tick": tick, "radius": radius})

func toggle_colorblind_mode():
	## Toggle color-blind friendly mode
	colorblind_mode = not colorblind_mode
	queue_redraw()

func _draw():
	# Draw the tactical view
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
	
	# Draw fire zones (under smoke)
	for fire in active_fires:
		var radius = fire.get("radius", 3.5)
		var pulse = (sin(Time.get_ticks_msec() / 150.0) + 1) / 2
		var fire_col = fire_zone_color * (0.7 + pulse * 0.3)
		draw_circle(fire.position, radius, fire_col)
		# Inner brighter core
		draw_circle(fire.position, radius * 0.5, Color(1.0, 0.6, 0.0, 0.6))
	
	# Draw smoke with soft edges
	for smoke in active_smokes:
		var radius = smoke.get("radius", 5.0)
		# Outer soft edge
		draw_circle(smoke.position, radius * 1.2, Color(smoke_color.r, smoke_color.g, smoke_color.b, 0.2))
		# Main smoke
		draw_circle(smoke.position, radius, smoke_color)
		# Inner denser core
		draw_circle(smoke.position, radius * 0.6, Color(smoke_color.r, smoke_color.g, smoke_color.b, 0.7))
	
	# Draw agents
	for agent in agents:
		_draw_agent(agent)

func _draw_agent(agent: Agent):
	## Draw a single agent with all status effects
	if not agent.is_alive():
		_draw_dead_agent(agent)
		return
	
	var pos = agent_visual_positions.get(agent.agent_id, agent.position)
	var color = team_a_color if agent.team == Agent.Team.TEAM_A else team_b_color
	
	# Draw agent shape (colorblind mode uses different shapes per team)
	if colorblind_mode:
		_draw_agent_colorblind(pos, color, agent.team)
	else:
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
	
	# Draw status effect indicators
	_draw_status_effects(agent, pos)

func _draw_agent_colorblind(pos: Vector2, color: Color, team: int):
	## Draw agent with shape-based team differentiation for colorblind users
	if team == Agent.Team.TEAM_A:
		# Team A: Triangle pointing right
		var points = PackedVector2Array([
			pos + Vector2(-agent_radius, -agent_radius),
			pos + Vector2(agent_radius, 0),
			pos + Vector2(-agent_radius, agent_radius)
		])
		draw_colored_polygon(points, color)
		# Add team letter
		# Note: Text drawing would require font, using simple indicator instead
		draw_line(pos + Vector2(-1, -1), pos + Vector2(1, 1), Color.WHITE, 1.0)
	else:
		# Team B: Square
		var half = agent_radius * 0.85
		draw_rect(Rect2(pos - Vector2(half, half), Vector2(half * 2, half * 2)), color)
		# Add team indicator
		draw_line(pos + Vector2(-1, 0), pos + Vector2(1, 0), Color.WHITE, 1.0)

func _draw_status_effects(agent: Agent, pos: Vector2):
	## Draw all active status effects on an agent
	var effect_offset = 0.0
	
	# Flash indicator (yellow glow)
	if agent.is_flashed():
		draw_circle(pos, agent_radius + 2 + effect_offset, flash_color)
		effect_offset += 1.0
	
	# Check for extended status effects if agent has status tracking
	# Note: This checks the old Agent.gd properties. For full integration,
	# would need to bridge with AgentState.status
	
	# Concuss indicator (purple spiral/arc)
	if _agent_has_status(agent, "concuss"):
		var arc_color = concuss_color
		draw_arc(pos, agent_radius + 3 + effect_offset, 0, TAU * 0.75, 12, arc_color, 2.0)
		effect_offset += 1.0
	
	# Slow indicator (cyan ring)
	if _agent_has_status(agent, "slow"):
		draw_circle(pos, agent_radius + 1, slow_color)
	
	# Burn indicator (pulsing orange)
	if _agent_has_status(agent, "burn"):
		var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1) / 2
		var burn_col = burn_color * (0.5 + pulse * 0.5)
		draw_circle(pos, agent_radius + 2, burn_col)
	
	# Reveal indicator (white outline visible through walls)
	if _agent_has_status(agent, "reveal"):
		draw_arc(pos, agent_radius + 4, 0, TAU, 16, reveal_color, 2.0)
	
	# Suppress indicator (dark overlay)
	if _agent_has_status(agent, "suppress"):
		draw_circle(pos, agent_radius, suppress_color)

func _agent_has_status(agent: Agent, status_name: String) -> bool:
	## Check if agent has a specific status effect
	## Currently Agent.gd only tracks flash state
	## Other statuses require AgentBridge integration (see AgentBridge.gd)
	match status_name:
		"flash":
			return agent.is_flashed()
		"concuss", "slow", "burn", "reveal", "suppress":
			# These require AgentState integration via AgentBridge
			# Return false until bridge is connected in MatchEngine
			return false
		_:
			return false

func _draw_dead_agent(agent: Agent):
	## Draw indicator for dead agent
	var pos = agent_visual_positions.get(agent.agent_id, agent.position)
	var color = team_a_color if agent.team == Agent.Team.TEAM_A else team_b_color
	color.a = 0.3  # Fade out
	
	# Draw X marker
	var size = agent_radius
	draw_line(pos + Vector2(-size, -size), pos + Vector2(size, size), color, 2.0)
	draw_line(pos + Vector2(-size, size), pos + Vector2(size, -size), color, 2.0)

func _process(_delta):
	# Update visual state
	queue_redraw()
