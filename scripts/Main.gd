extends Control

## Main game controller with HUD

@onready var viewer: Viewer2D
@onready var match_engine: MatchEngine
@onready var playback_controller: PlaybackController

# HUD elements
var time_label: Label
var speed_label: Label
var score_label: Label
var play_button: Button
var speed_up_button: Button
var speed_down_button: Button
var timeline_slider: HSlider
var save_replay_button: Button
var load_replay_button: Button

# Match state
var team_a_agents: Array[Agent] = []
var team_b_agents: Array[Agent] = []
var current_map: MapData

func _ready():
	# Setup UI
	_setup_ui()
	
	# Create match engine
	match_engine = MatchEngine.new()
	add_child(match_engine)
	
	# Create viewer
	viewer = Viewer2D.new()
	add_child(viewer)
	move_child(viewer, 0)  # Draw viewer first (behind UI)
	
	# Create playback controller
	playback_controller = PlaybackController.new()
	add_child(playback_controller)
	playback_controller.setup(match_engine)
	
	# Connect signals
	playback_controller.playback_state_changed.connect(_on_playback_state_changed)
	playback_controller.speed_changed.connect(_on_speed_changed)
	playback_controller.tick_changed.connect(_on_tick_changed)
	match_engine.tick_processed.connect(_on_tick_processed)
	
	# Start a match
	_start_new_match()

func _setup_ui():
	"""Setup HUD elements with accessibility improvements"""
	# Minimum touch target size for accessibility
	const MIN_TOUCH_TARGET: int = 48
	
	# Time label
	time_label = Label.new()
	time_label.position = Vector2(10, 10)
	time_label.add_theme_font_size_override("font_size", 24)
	add_child(time_label)
	
	# Speed label
	speed_label = Label.new()
	speed_label.position = Vector2(10, 40)
	speed_label.add_theme_font_size_override("font_size", 16)
	add_child(speed_label)
	
	# Score label
	score_label = Label.new()
	score_label.position = Vector2(10, 70)
	score_label.add_theme_font_size_override("font_size", 18)
	add_child(score_label)
	
	# Play/Pause button with accessibility
	play_button = _create_accessible_button("▶ Play", "Play or pause the match simulation (Spacebar)")
	play_button.position = Vector2(10, 650)
	play_button.custom_minimum_size = Vector2(90, MIN_TOUCH_TARGET)
	play_button.pressed.connect(_on_play_button_pressed)
	add_child(play_button)
	
	# Speed controls
	speed_down_button = _create_accessible_button("◀◀", "Decrease playback speed (- key)")
	speed_down_button.position = Vector2(110, 650)
	speed_down_button.custom_minimum_size = Vector2(MIN_TOUCH_TARGET, MIN_TOUCH_TARGET)
	speed_down_button.pressed.connect(_on_speed_down_pressed)
	add_child(speed_down_button)
	
	speed_up_button = _create_accessible_button("▶▶", "Increase playback speed (+ key)")
	speed_up_button.position = Vector2(165, 650)
	speed_up_button.custom_minimum_size = Vector2(MIN_TOUCH_TARGET, MIN_TOUCH_TARGET)
	speed_up_button.pressed.connect(_on_speed_up_pressed)
	add_child(speed_up_button)
	
	# Timeline slider with accessibility
	timeline_slider = HSlider.new()
	timeline_slider.position = Vector2(220, 655)
	timeline_slider.custom_minimum_size = Vector2(400, MIN_TOUCH_TARGET)
	timeline_slider.min_value = 0
	timeline_slider.max_value = 1000
	timeline_slider.value = 0
	timeline_slider.focus_mode = Control.FOCUS_ALL
	timeline_slider.tooltip_text = "Match timeline. Use Left/Right arrows to navigate."
	timeline_slider.value_changed.connect(_on_timeline_changed)
	add_child(timeline_slider)
	
	# Save/Load replay buttons
	save_replay_button = _create_accessible_button("💾 Save", "Save the current replay to a file")
	save_replay_button.position = Vector2(630, 650)
	save_replay_button.custom_minimum_size = Vector2(100, MIN_TOUCH_TARGET)
	save_replay_button.pressed.connect(_on_save_replay_pressed)
	add_child(save_replay_button)
	
	load_replay_button = _create_accessible_button("📂 Load", "Load a replay file")
	load_replay_button.position = Vector2(740, 650)
	load_replay_button.custom_minimum_size = Vector2(100, MIN_TOUCH_TARGET)
	load_replay_button.pressed.connect(_on_load_replay_pressed)
	add_child(load_replay_button)
	
	# Setup focus order for keyboard navigation
	_setup_focus_order()

func _create_accessible_button(text: String, tooltip: String) -> Button:
	"""Create a button with accessibility features"""
	var btn = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.focus_mode = Control.FOCUS_ALL
	
	# Custom styling for visible focus indicator
	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color(0.2, 0.4, 0.8, 0.3)
	focus_style.border_color = Color(0.3, 0.5, 1.0)
	focus_style.set_border_width_all(3)
	btn.add_theme_stylebox_override("focus", focus_style)
	
	return btn

func _setup_focus_order():
	"""Setup logical Tab navigation order"""
	var focus_order = [
		play_button,
		speed_down_button,
		speed_up_button,
		timeline_slider,
		save_replay_button,
		load_replay_button
	]
	
	for i in range(focus_order.size()):
		var current = focus_order[i]
		current.focus_mode = Control.FOCUS_ALL
		
		if i > 0:
			current.focus_neighbor_left = focus_order[i - 1].get_path()
			current.focus_previous = focus_order[i - 1].get_path()
		
		if i < focus_order.size() - 1:
			current.focus_neighbor_right = focus_order[i + 1].get_path()
			current.focus_next = focus_order[i + 1].get_path()
	
	# Set initial focus
	play_button.grab_focus()

func _start_new_match():
	"""Start a new match"""
	# Load map
	current_map = MapData.load_from_json("res://maps/training_ground.json")
	
	# Create agents
	team_a_agents.clear()
	team_b_agents.clear()
	
	for i in range(5):
		var agent_a = Agent.new()
		agent_a.agent_id = i
		agent_a.team = Agent.Team.TEAM_A
		agent_a.position = current_map.get_spawn_position(0) + Vector2(i * 3, 0)
		team_a_agents.append(agent_a)
		viewer.add_child(agent_a)
		
		var agent_b = Agent.new()
		agent_b.agent_id = i + 5
		agent_b.team = Agent.Team.TEAM_B
		agent_b.position = current_map.get_spawn_position(1) + Vector2(i * 3, 0)
		team_b_agents.append(agent_b)
		viewer.add_child(agent_b)
	
	# Setup viewer
	var all_agents: Array[Agent] = []
	all_agents.append_array(team_a_agents)
	all_agents.append_array(team_b_agents)
	viewer.setup(all_agents, current_map)
	
	# Start match
	var seed = randi()
	match_engine.start_match(seed, current_map, team_a_agents, team_b_agents)
	playback_controller.play()

func _process(_delta):
	"""Update HUD"""
	var current_tick = playback_controller.get_current_tick()
	var seconds = current_tick / 20.0
	time_label.text = "Time: %02d:%05.2f" % [int(seconds / 60), fmod(seconds, 60)]
	
	speed_label.text = "Speed: %.2fx" % playback_controller.playback_speed
	
	# Update score
	var team_a_alive = 0
	var team_b_alive = 0
	for agent in team_a_agents:
		if agent.is_alive():
			team_a_alive += 1
	for agent in team_b_agents:
		if agent.is_alive():
			team_b_alive += 1
	score_label.text = "Team A: %d | Team B: %d" % [team_a_alive, team_b_alive]
	
	# Update timeline
	if not timeline_slider.has_focus():
		timeline_slider.value = playback_controller.get_playback_progress() * 1000

func _on_play_button_pressed():
	playback_controller.toggle_play_pause()

func _on_speed_up_pressed():
	playback_controller.increase_speed()

func _on_speed_down_pressed():
	playback_controller.decrease_speed()

func _on_timeline_changed(value: float):
	if timeline_slider.has_focus():
		var progress = value / 1000.0
		var target_tick = int(progress * match_engine.event_log.get_match_duration())
		playback_controller.scrub_to_tick(target_tick)

func _on_playback_state_changed(is_playing: bool):
	play_button.text = "⏸ Pause" if is_playing else "▶ Play"

func _on_speed_changed(_speed: float):
	pass  # Already handled in _process

func _on_tick_changed(_tick: int):
	pass  # Already handled in _process

func _on_tick_processed(_tick: int):
	viewer.update_interpolation(0.0)

func _on_save_replay_pressed():
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "user://replay_" + timestamp + ".json"
	if match_engine.event_log.save_to_file(filename):
		print("Replay saved to: " + filename)
		save_replay_button.text = "✓ Saved!"
		# Reset button text after delay
		await get_tree().create_timer(2.0).timeout
		save_replay_button.text = "💾 Save"
	else:
		print("Failed to save replay!")
		save_replay_button.text = "✗ Failed"
		await get_tree().create_timer(2.0).timeout
		save_replay_button.text = "💾 Save"

func _on_load_replay_pressed():
	# For now, just load the most recent replay
	# In a full implementation, would show file dialog
	print("Load replay not fully implemented yet")

func _input(event):
	"""Handle input with respect to focused controls"""
	if event is InputEventKey and event.pressed:
		# Check if a control has focus that should handle its own input
		var focused = get_viewport().gui_get_focus_owner()
		if focused == timeline_slider:
			# Let timeline handle arrow keys itself
			if event.keycode in [KEY_LEFT, KEY_RIGHT]:
				return
		
		match event.keycode:
			KEY_SPACE:
				playback_controller.toggle_play_pause()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				playback_controller.scrub_backward()
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				playback_controller.scrub_forward()
				get_viewport().set_input_as_handled()
			KEY_EQUAL, KEY_PLUS:
				playback_controller.increase_speed()
				get_viewport().set_input_as_handled()
			KEY_MINUS:
				playback_controller.decrease_speed()
				get_viewport().set_input_as_handled()
