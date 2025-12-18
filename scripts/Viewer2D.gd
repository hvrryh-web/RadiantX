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
const AGENT_RADIUS: float = 6.0  # Doubled from 3.0 for visibility
var agent_radius: float = AGENT_RADIUS

# Accessible color palette - colorblind-friendly
const COLOR_TEAM_A: String = "#3B82F6"       # Blue-500
const COLOR_TEAM_B: String = "#F97316"       # Orange-500 (better than red for colorblind)
const COLOR_TEAM_A_DARK: String = "#1E40AF"  # Darker blue for outlines
const COLOR_TEAM_B_DARK: String = "#C2410C"  # Darker orange for outlines
const COLOR_MAP_BG: String = "#0F172A"       # Slate-900
const COLOR_OCCLUDER_FILL: String = "#334155"  # Slate-700
const COLOR_OCCLUDER_BORDER: String = "#64748B" # Slate-500
const COLOR_ZONE_BORDER: String = "#FACC15"  # Yellow-400
const COLOR_SMOKE: String = "#94A3B8"        # Slate-400
const COLOR_HEALTH_HIGH: String = "#22C55E"  # Green
const COLOR_HEALTH_MED: String = "#EAB308"   # Yellow
const COLOR_HEALTH_LOW: String = "#EF4444"   # Red

var team_a_color: Color = Color(COLOR_TEAM_A)
var team_b_color: Color = Color(COLOR_TEAM_B)
var team_a_dark: Color = Color(COLOR_TEAM_A_DARK)
var team_b_dark: Color = Color(COLOR_TEAM_B_DARK)
var map_background: Color = Color(COLOR_MAP_BG)
var occluder_fill: Color = Color(COLOR_OCCLUDER_FILL)
var occluder_border: Color = Color(COLOR_OCCLUDER_BORDER)
var zone_fill: Color = Color("#FDE047", 0.2)  # Yellow-300 at 20%
var zone_border: Color = Color(COLOR_ZONE_BORDER)
var smoke_color: Color = Color(COLOR_SMOKE, 0.7)

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
		return Color(COLOR_HEALTH_HIGH)
	elif ratio > 0.3:
		return Color(COLOR_HEALTH_MED)
	else:
		return Color(COLOR_HEALTH_LOW)
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
	# Update visual state only when needed
	if needs_redraw:
		queue_redraw()
		needs_redraw = false
