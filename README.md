# RadiantX - Tactical FPS Coach Simulator

A deterministic, simulation-heavy tactical FPS manager for offline Windows play, built with Godot 4 and GDScript.

## Features

- **Deterministic 20 TPS Match Engine**: Seeded RNG for reproducible matches
- **5v5 Tactical Gameplay**: Full team simulation with AI agents
- **Partial Observability**: Belief systems and communication delay simulation
- **Map System**: JSON-based maps with zones and occluders
- **Tactical Mechanics**: Smoke grenades, flashbangs, vision occlusion
- **Event Log & Replay**: Full match recording with save/load
- **Top-Down Viewer**: Smooth interpolated 2D visualization
- **Playback Controls**: Play/pause, speed control, timeline scrubbing
- **Determinism Verification**: Built-in tests to ensure consistency

## Requirements

- Godot 4.0 or higher
- Windows (primary target platform)

## Getting Started

### Quick Start

See the [Quick Start Guide](docs/quick_start.md) for detailed installation and usage instructions.

### Opening the Project

1. Install Godot 4.x from [godotengine.org](https://godotengine.org/)
2. Clone this repository
3. Open the project in Godot by selecting the `project.godot` file

### Running a Match

1. Run the main scene (F5)
2. Use the playback controls to play/pause, adjust speed, or scrub through the timeline
3. Watch the top-down tactical view of the 5v5 match

### Map Format

Maps are defined in JSON format with the following structure:

```json
{
  "name": "Example Map",
  "width": 100,
  "height": 100,
  "zones": [
    {"id": "spawn_a", "x": 10, "y": 10, "width": 20, "height": 20},
    {"id": "spawn_b", "x": 70, "y": 70, "width": 20, "height": 20}
  ],
  "occluders": [
    {"x": 45, "y": 30, "width": 10, "height": 40}
  ]
}
```

See `maps/` directory for examples.

## Architecture

### Core Components

- **MatchEngine**: Handles tick-based simulation at 20 TPS with deterministic RNG
- **Agent**: Individual player entity with beliefs and communication
- **MapData**: Loads and manages map geometry and zones
- **EventLog**: Records all events for replay functionality
- **Viewer2D**: Top-down visualization with interpolation
- **PlaybackController**: Manages playback controls and timeline

### Determinism

The engine uses seeded random number generation to ensure matches are reproducible:
- Same seed + same inputs = same results
- Replays can be verified by re-running with the same seed
- Automated tests verify determinism

## Testing

Run determinism tests:
```bash
# Tests are run automatically via CI
# Manual test: Run test scene in Godot
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Map Format Specification](docs/map_format.md)
- [Agent Behavior](docs/agents.md)
- [Replay System](docs/replay.md)
- [Custom AI Agents](docs/custom-agents.md)

## License

MIT License - See LICENSE file for details

## Contributing

This is an offline, Windows-focused simulation game. Contributions should maintain:
- Deterministic behavior
- Offline functionality
- Windows compatibility
