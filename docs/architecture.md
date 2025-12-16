# Architecture Overview

## System Design

RadiantX is built on a deterministic, tick-based simulation architecture designed for reproducible tactical FPS matches.

## Core Components

### 1. MatchEngine (scripts/MatchEngine.gd)
The heart of the simulation, running at 20 TPS (ticks per second).

**Responsibilities:**
- Maintain deterministic RNG with seeded generation
- Process agent beliefs and decisions each tick
- Handle tactical events (smoke, flashbangs)
- Process combat and line-of-sight checks
- Emit events for visualization and replay

**Key Features:**
- Fixed timestep simulation (50ms per tick)
- Seeded RNG ensures reproducibility
- Event logging for full match replay

### 2. Agent (scripts/Agent.gd)
Individual tactical agent with partial observability.

**Responsibilities:**
- Maintain belief state about other agents
- Make decisions based on partial information
- Handle movement and combat actions
- Process tactical utilities (smoke/flash)

**Partial Observability:**
- Agents only know what they can see
- Beliefs decay over time when not observed
- Communication delay simulated
- Vision blocked by smoke and occluders

### 3. MapData (scripts/MapData.gd)
Handles map geometry and line-of-sight calculations.

**Features:**
- JSON-based map format
- Zones for spawn points and objectives
- Occluders for blocking vision and bullets
- Line-of-sight raycast system

### 4. EventLog (scripts/EventLog.gd)
Records all match events for replay functionality.

**Capabilities:**
- Log all game events with timestamps
- Save/load replays to JSON
- Query events by tick or range
- Support deterministic replay

### 5. Viewer2D (scripts/Viewer2D.gd)
Top-down visualization with smooth interpolation.

**Features:**
- Interpolated rendering between ticks
- Color-coded teams
- Health bars and status indicators
- Smoke and flash visualization
- Camera controls

### 6. PlaybackController (scripts/PlaybackController.gd)
Manages playback state and controls.

**Features:**
- Play/pause functionality
- Variable speed (0.25x to 4x)
- Timeline scrubbing
- Live and replay modes

## Data Flow

```
User Input → PlaybackController → MatchEngine
                                      ↓
                                  Process Tick
                                      ↓
                    ┌─────────────────┴─────────────────┐
                    ↓                                   ↓
              Agent Updates                        EventLog
           (beliefs, decisions)                   (record events)
                    ↓                                   ↓
              Apply Actions                         Viewer2D
           (movement, combat)                    (visualization)
                    ↓
               Emit Signals
```

## Determinism

The system ensures determinism through:

1. **Seeded RNG**: All randomness uses a seeded RandomNumberGenerator
2. **Fixed Timestep**: Simulation always runs at 20 TPS
3. **Event Ordering**: Actions processed in consistent order
4. **No Floating Point Accumulation**: Uses discrete ticks

This allows:
- Exact replay of matches
- Testing and debugging
- Fair competition analysis

## Performance Considerations

- Fixed 20 TPS reduces CPU load
- Interpolation provides smooth visuals at any framerate
- Event log limited to 100k events to prevent memory issues
- Efficient line-of-sight calculations using rect intersections

## Extension Points

The architecture supports adding:
- New tactical utilities (grenades, equipment)
- Different agent behaviors (AI strategies)
- Additional map features (dynamic elements)
- Stats and analysis tools
- Network multiplayer (deterministic sync)
