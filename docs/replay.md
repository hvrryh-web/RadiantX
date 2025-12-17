# Replay System

## Overview

The replay system records all match events for complete match reconstruction and analysis.

## Event Log

### Event Structure

All events share a common structure:

```gdscript
{
  "type": "event_type",
  "tick": int,
  ... # Event-specific data
}
```

### Event Types

#### Match Events

**match_start**
```json
{
  "type": "match_start",
  "tick": 0,
  "seed": 12345,
  "agents": 10
}
```

**match_end**
```json
{
  "type": "match_end",
  "tick": 1000
}
```

#### Combat Events

**hit**
```json
{
  "type": "hit",
  "tick": 523,
  "attacker_id": 2,
  "target_id": 7
}
```

**kill**
```json
{
  "type": "kill",
  "tick": 523,
  "attacker_id": 2,
  "target_id": 7
}
```

#### Tactical Events

**smoke_deployed**
```json
{
  "type": "smoke_deployed",
  "tick": 150,
  "agent_id": 3,
  "position": {"x": 45.5, "y": 32.1}
}
```

**flash_deployed**
```json
{
  "type": "flash_deployed",
  "tick": 200,
  "agent_id": 4,
  "position": {"x": 60.0, "y": 50.0}
}
```

## File Format

Replays are saved as JSON files:

```json
{
  "version": 1,
  "events": [
    {"type": "match_start", "tick": 0, "seed": 12345, "agents": 10},
    {"type": "hit", "tick": 100, "attacker_id": 1, "target_id": 6},
    ...
  ]
}
```

### Location

- **Save Directory**: `user://` (Godot user directory)
- **Naming**: `replay_YYYY-MM-DD_HH-MM-SS.json`
- **Windows Path**: `%APPDATA%\Godot\app_userdata\RadiantX\`

## Usage

### Saving a Replay

```gdscript
var filename = "user://replay_" + timestamp + ".json"
match_engine.event_log.save_to_file(filename)
```

**In-game:**
- Click "Save Replay" button
- Replay saved automatically with timestamp
- Console prints save location

### Loading a Replay

```gdscript
var event_log = EventLog.new()
if event_log.load_from_file(filename):
    playback_controller.load_replay(event_log)
```

**In-game:**
- Click "Load Replay" button
- Select replay file (future: file dialog)
- Playback switches to replay mode

## Replay Playback

### Controls

- **Play/Pause**: Space or button
- **Speed Control**: +/- keys or buttons
  - Speeds: 0.25x, 0.5x, 1x, 2x, 4x
- **Scrubbing**: Timeline slider or arrow keys
  - Left/Right: Jump 20 ticks (1 second)

### Modes

**Live Mode:**
- Real-time match simulation
- Can save replay after match

**Replay Mode:**
- Playback from event log
- Full scrubbing support
- Deterministic reconstruction

## Determinism Verification

### How It Works

1. Record match with seed S
2. Save event log
3. Start new match with same seed S
4. Compare events tick-by-tick

### Expected Results

With same seed:
- All events occur at same ticks
- All positions match exactly
- All decisions identical
- Complete determinism

### Testing

```gdscript
func test_determinism():
    var seed = 12345
    
    # Run match 1
    var events1 = run_match(seed)
    
    # Run match 2
    var events2 = run_match(seed)
    
    # Compare
    assert(events1.size() == events2.size())
    for i in range(events1.size()):
        assert(events1[i] == events2[i])
```

## Event Queries

### By Tick

```gdscript
var events = event_log.get_events_for_tick(500)
# Returns all events at tick 500
```

### By Range

```gdscript
var events = event_log.get_events_in_range(100, 200)
# Returns events from tick 100-200
```

### Match Info

```gdscript
var duration = event_log.get_match_duration()  # In ticks
var seed = event_log.get_match_seed()
```

## Performance

### Memory Usage
- Average event: ~100 bytes
- 1000 ticks: ~10-50 events = 1-5 KB
- Long match (10 min = 12000 ticks): ~50-300 KB

### Limits
- Max events: 100,000
- Beyond limit: Warning logged, no new events
- Typical match: 1,000-5,000 events

### Optimization
- Events stored in memory during match
- Written to disk only on save
- Loading replays creates new EventLog instance

## Analysis

Event logs enable:
- **Stats Tracking**: Kills, deaths, utility usage
- **Heatmaps**: Position tracking over time
- **Timing Analysis**: Engagement timings
- **Strategy Review**: Decision patterns

### Example Analysis

```gdscript
func analyze_kills(events: Array) -> Dictionary:
    var stats = {}
    for event in events:
        if event.type == "kill":
            var attacker = event.attacker_id
            stats[attacker] = stats.get(attacker, 0) + 1
    return stats
```

## Future Enhancements

- **Compression**: Gzip event logs for smaller files
- **Streaming**: Load replays without full memory load
- **Metadata**: Map name, date, player names
- **Highlights**: Auto-detect interesting moments
- **Export**: Convert to video or GIF
