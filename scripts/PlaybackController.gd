extends Node
class_name PlaybackController

## Controls match playback with play/pause/speed/scrub functionality

signal playback_state_changed(is_playing: bool)
signal speed_changed(new_speed: float)
signal tick_changed(tick: int)

enum PlaybackMode { LIVE, REPLAY }

var match_engine: MatchEngine
var is_playing: bool = false
var playback_speed: float = 1.0
var current_mode: PlaybackMode = PlaybackMode.LIVE

# Replay state
var replay_events: Array[Dictionary] = []
var replay_tick: int = 0
var max_replay_tick: int = 0

# Tick accumulator for fixed timestep
var tick_accumulator: float = 0.0

func _ready():
	pass

func setup(engine: MatchEngine):
	"""Setup controller with match engine"""
	match_engine = engine

func play():
	"""Start playback"""
	is_playing = true
	playback_state_changed.emit(true)

func pause():
	"""Pause playback"""
	is_playing = false
	playback_state_changed.emit(false)

func toggle_play_pause():
	"""Toggle between play and pause"""
	if is_playing:
		pause()
	else:
		play()

func set_speed(speed: float):
	"""Set playback speed (0.25x, 0.5x, 1x, 2x, 4x)"""
	playback_speed = clamp(speed, 0.25, 4.0)
	speed_changed.emit(playback_speed)

func increase_speed():
	"""Increase playback speed"""
	var speeds = [0.25, 0.5, 1.0, 2.0, 4.0]
	var current_index = speeds.find(playback_speed)
	if current_index < speeds.size() - 1:
		set_speed(speeds[current_index + 1])

func decrease_speed():
	"""Decrease playback speed"""
	var speeds = [0.25, 0.5, 1.0, 2.0, 4.0]
	var current_index = speeds.find(playback_speed)
	if current_index > 0:
		set_speed(speeds[current_index - 1])

func scrub_to_tick(tick: int):
	"""Scrub to a specific tick in replay"""
	if current_mode != PlaybackMode.REPLAY:
		return
	
	replay_tick = clamp(tick, 0, max_replay_tick)
	tick_changed.emit(replay_tick)

func scrub_forward(ticks: int = 20):
	"""Scrub forward by number of ticks"""
	scrub_to_tick(replay_tick + ticks)

func scrub_backward(ticks: int = 20):
	"""Scrub backward by number of ticks"""
	scrub_to_tick(replay_tick - ticks)

func load_replay(event_log: EventLog) -> bool:
	"""Load replay from event log"""
	replay_events = event_log.get_events()
	if replay_events.is_empty():
		return false
	
	current_mode = PlaybackMode.REPLAY
	max_replay_tick = event_log.get_match_duration()
	replay_tick = 0
	is_playing = false
	
	return true

func _process(delta):
	"""Process playback"""
	if not is_playing or not match_engine:
		return
	
	match current_mode:
		PlaybackMode.LIVE:
			_process_live(delta)
		PlaybackMode.REPLAY:
			_process_replay(delta)

func _process_live(delta):
	"""Process live match playback"""
	tick_accumulator += delta * playback_speed
	
	var tick_delta = MatchEngine.TICK_DELTA
	while tick_accumulator >= tick_delta:
		match_engine.process_tick()
		tick_accumulator -= tick_delta

func _process_replay(delta):
	"""Process replay playback"""
	if replay_tick >= max_replay_tick:
		pause()
		return
	
	tick_accumulator += delta * playback_speed
	
	var tick_delta = MatchEngine.TICK_DELTA
	while tick_accumulator >= tick_delta:
		replay_tick += 1
		tick_changed.emit(replay_tick)
		tick_accumulator -= tick_delta
		
		if replay_tick >= max_replay_tick:
			pause()
			break

func get_current_tick() -> int:
	"""Get current tick"""
	if current_mode == PlaybackMode.REPLAY:
		return replay_tick
	return match_engine.current_tick if match_engine else 0

func get_playback_progress() -> float:
	"""Get playback progress as ratio (0.0 to 1.0)"""
	if current_mode == PlaybackMode.REPLAY and max_replay_tick > 0:
		return float(replay_tick) / float(max_replay_tick)
	return 0.0
