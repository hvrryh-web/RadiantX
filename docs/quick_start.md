# Quick Start Guide

## Installation

1. **Install Godot 4.x**
   - Download from [godotengine.org](https://godotengine.org/download)
   - Choose the stable version for Windows

2. **Clone the Repository**
   ```bash
   git clone https://github.com/hvrryh-web/RadiantX.git
   cd RadiantX
   ```

3. **Open in Godot**
   - Launch Godot
   - Click "Import"
   - Browse to the RadiantX folder
   - Select `project.godot`
   - Click "Import & Edit"

## First Run

1. **Run the Main Scene**
   - Press F5 or click the "Play" button (▶)
   - The match will start automatically

2. **What You'll See**
   - Top-down view of a 100x100 unit map
   - 5 blue agents (Team A) vs 5 red agents (Team B)
   - Agents moving and engaging in combat
   - Gray rectangles are walls/occluders

## Controls

### Playback
- **Space**: Play/Pause
- **+/-**: Speed up/down (0.25x to 4x)
- **Left/Right Arrow**: Scrub backward/forward (1 second jumps)
- **Timeline Slider**: Click to jump to any point

### Buttons
- **Pause/Play**: Toggle playback
- **<< / >>**: Decrease/increase speed
- **Save Replay**: Save current match to file
- **Load Replay**: Load a saved replay (basic implementation)

## Understanding the View

### Colors
- **Blue circles**: Team A agents
- **Red circles**: Team B agents
- **Green bar above agent**: Health
- **Gray rectangles**: Walls (block line of sight and bullets)
- **Light gray circles**: Smoke grenades
- **Yellow glow**: Flashed agent

### Agent Behavior
Agents use partial observability - they only know what they can see:
- Agents will move toward known enemies
- When no enemies are visible, they explore randomly
- Occasionally deploy smoke or flashbangs
- 5% chance to use smoke, 3% chance to flash

## Creating Custom Maps

1. **Create JSON File**
   Create a new file in `maps/` folder:
   ```json
   {
     "name": "My Custom Map",
     "width": 150,
     "height": 150,
     "zones": [
       {"id": "spawn_a", "x": 10, "y": 10, "width": 15, "height": 15},
       {"id": "spawn_b", "x": 125, "y": 125, "width": 15, "height": 15}
     ],
     "occluders": [
       {"x": 70, "y": 40, "width": 10, "height": 50}
     ]
   }
   ```

2. **Load in Main.gd**
   Edit `scripts/Main.gd`, find `_start_new_match()`, change:
   ```gdscript
   current_map = MapData.load_from_json("res://maps/your_map_name.json")
   ```

3. **Run and Test**
   Press F5 to see your custom map

## Testing Determinism

1. **Run Test Scene**
   - In Godot, navigate to `tests/test_determinism.tscn`
   - Right-click → "Run This Scene"

2. **Check Console Output**
   - Should see "All determinism tests passed!"
   - Verifies same seed produces same results

## Saving and Loading Replays

### Saving
1. Let a match run for a while
2. Click "Save Replay" button
3. File saved to `user://replay_TIMESTAMP.json`

### Finding Replays
- **Windows**: `%APPDATA%\Godot\app_userdata\RadiantX\`
- Look for `replay_*.json` files

### Manual Replay Loading
To load a specific replay, modify `Main.gd`:
```gdscript
func _on_load_replay_pressed():
    var event_log = EventLog.new()
    if event_log.load_from_file("user://replay_2024-12-16_10-30-00.json"):
        playback_controller.load_replay(event_log)
        playback_controller.play()
```

## Performance

- Runs at 20 TPS (ticks per second)
- Smooth 60 FPS rendering with interpolation
- Low CPU usage (~5-10% on modern systems)
- Memory: ~50-100 MB for typical match

## Troubleshooting

### "Map file not found"
- Check that map file exists in `maps/` folder
- Verify path in `Main.gd` is correct
- Make sure JSON is valid

### Agents not moving
- Check that match has started (should auto-start)
- Press Space to ensure not paused
- Verify playback speed isn't 0x

### No graphics visible
- Ensure Viewer2D is properly initialized
- Check that agents were added as children
- Verify camera is positioned correctly

## Next Steps

1. **Experiment with Maps**: Create different layouts
2. **Analyze Replays**: Study agent behavior patterns
3. **Modify Agent AI**: Change decision-making in `Agent.gd`
4. **Add Features**: Extend with new tactical utilities
5. **Performance Tuning**: Optimize for larger battles

## Resources

- [Full Documentation](docs/architecture.md)
- [Map Format](docs/map_format.md)
- [Agent Behavior](docs/agents.md)
- [Replay System](docs/replay.md)

## Community

This is an offline, single-player simulation tool for tactical analysis and learning.
Perfect for:
- Understanding tactical FPS concepts
- Testing strategies
- Learning game development
- Experimenting with AI behavior

Enjoy your tactical simulations!
