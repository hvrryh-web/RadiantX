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
	"""Setup HUD elements"""
	# Time label
	time_label = Label.new()
	time_label.position = Vector2(10, 10)
	time_label.add_theme_font_size_override("font_size", 20)
	add_child(time_label)
	
	# Speed label
	speed_label = Label.new()
	speed_label.position = Vector2(10, 40)
	add_child(speed_label)
	
	# Score label
	score_label = Label.new()
	score_label.position = Vector2(10, 70)
	add_child(score_label)
	
	# Play/Pause button
	play_button = Button.new()
	play_button.text = "Pause"
	play_button.position = Vector2(10, 650)
	play_button.size = Vector2(80, 40)
	play_button.pressed.connect(_on_play_button_pressed)
	add_child(play_button)
	
	# Speed controls
	speed_down_button = Button.new()
	speed_down_button.text = "<<"
	speed_down_button.position = Vector2(100, 650)
	speed_down_button.size = Vector2(50, 40)
	speed_down_button.pressed.connect(_on_speed_down_pressed)
	add_child(speed_down_button)
	
	speed_up_button = Button.new()
	speed_up_button.text = ">>"
	speed_up_button.position = Vector2(160, 650)
	speed_up_button.size = Vector2(50, 40)
	speed_up_button.pressed.connect(_on_speed_up_pressed)
	add_child(speed_up_button)
	
	# Timeline slider
	timeline_slider = HSlider.new()
	timeline_slider.position = Vector2(220, 660)
	timeline_slider.size = Vector2(400, 20)
	timeline_slider.min_value = 0
	timeline_slider.max_value = 1000
	timeline_slider.value = 0
	timeline_slider.value_changed.connect(_on_timeline_changed)
	add_child(timeline_slider)
	
	# Save/Load replay buttons
	save_replay_button = Button.new()
	save_replay_button.text = "Save Replay"
	save_replay_button.position = Vector2(630, 650)
	save_replay_button.size = Vector2(100, 40)
	save_replay_button.pressed.connect(_on_save_replay_pressed)
	add_child(save_replay_button)
	
	load_replay_button = Button.new()
	load_replay_button.text = "Load Replay"
	load_replay_button.position = Vector2(740, 650)
	load_replay_button.size = Vector2(100, 40)
	load_replay_button.pressed.connect(_on_load_replay_pressed)
	add_child(load_replay_button)

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
	play_button.text = "Pause" if is_playing else "Play"

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

func _on_load_replay_pressed():
	# For now, just load the most recent replay
	# In a full implementation, would show file dialog
	print("Load replay not fully implemented yet")

func _input(event):
	"""Handle input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				playback_controller.toggle_play_pause()
			KEY_LEFT:
				playback_controller.scrub_backward()
			KEY_RIGHT:
				playback_controller.scrub_forward()
			KEY_EQUAL, KEY_PLUS:
				playback_controller.increase_speed()
			KEY_MINUS:
				playback_controller.decrease_speed()
