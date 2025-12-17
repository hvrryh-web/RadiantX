# Backend Architecture & Infrastructure Review

## RadiantX - Tactical FPS Coach Simulator

**Review Date:** 2025-12-17  
**Reviewer:** Agent 006 - Backend Architecture & Infrastructure  
**Repository:** RadiantX  
**Technology Stack:** Godot 4, GDScript, JSON-based data

---

## Executive Summary

RadiantX is a well-structured deterministic tactical FPS simulation with solid foundational architecture. The 20 TPS tick-based engine provides a good balance between accuracy and performance. However, there are several areas where reliability, scalability, and infrastructure could be strengthened.

**Overall Assessment:** 🟢 Good foundation with room for improvement

| Category | Rating | Notes |
|----------|--------|-------|
| Architecture | ⭐⭐⭐⭐ | Clean separation of concerns |
| Determinism | ⭐⭐⭐⭐ | Solid design, minor edge cases |
| Error Handling | ⭐⭐ | Needs significant improvement |
| Testing | ⭐⭐ | Basic coverage, needs expansion |
| CI/CD | ⭐⭐⭐ | Structure validation only |
| Performance | ⭐⭐⭐ | Good for current scale |
| Documentation | ⭐⭐⭐⭐ | Comprehensive |

---

## 1. Architecture Analysis

### 1.1 Component Design ✅

**Strengths:**
- Clear separation between simulation (`MatchEngine`), visualization (`Viewer2D`), and playback (`PlaybackController`)
- Event-driven architecture using Godot signals
- Single responsibility principle mostly followed
- Resource-based `MapData` is memory-efficient

**Architecture Diagram:**
```
┌─────────────────────────────────────────────────────────────┐
│                          Main.gd                            │
│                    (Orchestration Layer)                    │
└─────────────────────────────────────────────────────────────┘
           │              │                 │
           ▼              ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
│MatchEngine  │  │PlaybackCtrl  │  │     Viewer2D         │
│(Simulation) │  │  (Control)   │  │  (Visualization)     │
└──────────────┘  └──────────────┘  └──────────────────────┘
      │                                      │
      ▼                                      │
┌──────────────┐                             │
│  EventLog    │ ────────────────────────────┘
│  (Replay)    │
└──────────────┘
      │
      ▼
┌──────────────┐
│   Agent[]    │ ◄──── MapData (LOS checks)
│ (Entities)   │
└──────────────┘
```

### 1.2 Identified Architectural Issues

#### Issue A1: Tight Coupling in Main.gd
**Severity:** Medium  
**Location:** `scripts/Main.gd:118-151`

The `_start_new_match()` function directly creates agents and adds them as children of the viewer, creating tight coupling between the UI layer and the simulation.

```gdscript
# Current: Agents added to viewer (wrong layer)
viewer.add_child(agent_a)  # Line 133

# Problem: Visualization layer owns simulation entities
```

**Recommendation:**
```gdscript
# Create a dedicated entity container
var entity_container: Node

func _start_new_match():
    # Clear previous entities
    for child in entity_container.get_children():
        child.queue_free()
    
    # Create agents in entity container (simulation layer)
    for i in range(5):
        var agent_a = Agent.new()
        # ... setup
        entity_container.add_child(agent_a)
    
    # Viewer references agents, doesn't own them
    viewer.setup(all_agents, current_map)
```

---

#### Issue A2: Missing State Machine Pattern
**Severity:** Low  
**Location:** `scripts/Agent.gd:115-148`

The `make_decision()` function uses implicit state transitions without a formal state machine, making behavior hard to extend and debug.

**Recommendation:**
Consider implementing a simple state machine pattern:

```gdscript
# State pattern for cleaner transitions
func make_decision(current_tick: int, rng: RandomNumberGenerator):
    match current_state:
        State.IDLE:
            _decide_idle(current_tick, rng)
        State.MOVING:
            _decide_moving(current_tick, rng)
        State.ATTACKING:
            _decide_attacking(current_tick, rng)
        State.TAKING_COVER:
            _decide_cover(current_tick, rng)

func _decide_idle(current_tick: int, rng: RandomNumberGenerator):
    var known_enemies = _get_known_enemies()
    if known_enemies.size() > 0:
        _transition_to(State.ATTACKING)
    elif rng.randf() < 0.1:
        _transition_to(State.MOVING)
```

---

#### Issue A3: Incomplete Replay State Restoration
**Severity:** High  
**Location:** `scripts/MatchEngine.gd:183-188`

The `set_replay_state()` function doesn't fully restore match state:
- Missing: `is_flashed_until`, `smoke_positions`, `beliefs`, `last_seen`
- Missing: RNG state restoration
- Missing: Pending action states

**Current (incomplete):**
```gdscript
func set_replay_state(state: Dictionary):
    current_tick = state.tick
    for i in range(agents.size()):
        if i < state.agents.size():
            agents[i].set_state(state.agents[i])  # Doesn't restore beliefs!
```

**Recommended fix in Agent.gd:**
```gdscript
func get_state() -> Dictionary:
    return {
        "id": agent_id,
        "team": team,
        "position": {"x": position.x, "y": position.y},
        "velocity": {"x": velocity.x, "y": velocity.y},
        "health": health,
        "state": current_state,
        "is_flashed_until": is_flashed_until,  # ADD
        "smoke_positions": smoke_positions.map(func(p): return {"x": p.x, "y": p.y}),  # ADD
        "beliefs": beliefs.duplicate(true),  # ADD
        "last_seen": last_seen.duplicate()  # ADD
    }

func set_state(state: Dictionary):
    agent_id = state.id
    team = state.team
    position = Vector2(state.position.x, state.position.y)
    velocity = Vector2(state.velocity.x, state.velocity.y)
    health = state.health
    current_state = state.state
    is_flashed_until = state.get("is_flashed_until", 0)  # ADD
    # Restore smoke positions
    smoke_positions.clear()
    for sp in state.get("smoke_positions", []):
        smoke_positions.append(Vector2(sp.x, sp.y))
    # Restore beliefs
    beliefs = state.get("beliefs", {}).duplicate(true)
    last_seen = state.get("last_seen", {}).duplicate()
```

---

## 2. Determinism Analysis

### 2.1 Current Determinism Guarantees ✅

**Well-implemented:**
- Seeded `RandomNumberGenerator` for all random decisions
- Fixed 20 TPS tick rate
- Consistent agent processing order (array iteration)
- No reliance on wall-clock time during simulation

### 2.2 Determinism Risks ⚠️

#### Issue D1: Dictionary Iteration Order
**Severity:** High  
**Location:** `scripts/Agent.gd:121-127`

GDScript dictionaries maintain insertion order, but `beliefs` dictionary keys are agent IDs which may be added in non-deterministic order based on visibility checks.

```gdscript
# Current: Order depends on when agents become visible
for agent_id in beliefs:  # Non-deterministic order?
    var belief = beliefs[agent_id]
```

**Fix:**
```gdscript
# Sort keys for deterministic iteration
var sorted_agent_ids = beliefs.keys()
sorted_agent_ids.sort()
for agent_id in sorted_agent_ids:
    var belief = beliefs[agent_id]
```

---

#### Issue D2: Floating-Point Position Drift
**Severity:** Medium  
**Location:** `scripts/Agent.gd:157-159`

Continuous floating-point operations can accumulate errors over long matches:

```gdscript
position += velocity * delta  # Accumulates error over time
```

**Mitigation options:**
1. Use fixed-point arithmetic (complex)
2. Periodically snap to grid
3. Round to fixed precision:

```gdscript
func apply_action(current_tick: int, delta: float):
    match current_state:
        State.MOVING, State.ATTACKING:
            var direction = (target_position - position).normalized()
            velocity = direction * move_speed
            position += velocity * delta
            # Snap to 4 decimal places to prevent drift
            position = Vector2(
                snapped(position.x, 0.0001),
                snapped(position.y, 0.0001)
            )
            position_changed.emit(position)
```

---

#### Issue D3: Uninitialized RNG in Agent
**Severity:** High  
**Location:** `scripts/Agent.gd:43-52`

While `reset()` receives a seed, the agent doesn't use it for its own RNG. However, decisions use the engine's RNG, so this is actually safe. Still, the seed parameter is misleading.

```gdscript
func reset(seed: int):  # seed parameter unused!
    health = max_health
    # ...
```

**Recommendation:** Either use the seed or remove the parameter:
```gdscript
func reset():  # Remove unused parameter
    health = max_health
    # ...
```

Or if agents need their own RNG:
```gdscript
var agent_rng: RandomNumberGenerator

func reset(seed: int):
    agent_rng = RandomNumberGenerator.new()
    agent_rng.seed = seed
    # ...
```

---

## 3. Error Handling Assessment

### 3.1 Current State: ⚠️ Insufficient

Error handling is minimal throughout the codebase. Most functions assume success without defensive programming.

### 3.2 Critical Issues

#### Issue E1: File I/O Without Proper Error Recovery
**Severity:** High  
**Location:** `scripts/EventLog.gd:42-56`, `scripts/MapData.gd:15-38`

File operations return boolean success but callers don't always handle failures:

```gdscript
# EventLog.gd - Good: returns bool
func save_to_file(file_path: String) -> bool:

# Main.gd - Bad: ignores return value
func _on_save_replay_pressed():
    if match_engine.event_log.save_to_file(filename):
        print("Replay saved to: " + filename)
    # Missing: else branch, no user notification on failure!
```

**Recommended improvements:**

```gdscript
# Add Result type pattern
class_name Result

var success: bool
var error_message: String
var data: Variant

static func ok(data: Variant = null) -> Result:
    var r = Result.new()
    r.success = true
    r.data = data
    return r

static func err(message: String) -> Result:
    var r = Result.new()
    r.success = false
    r.error_message = message
    return r
```

```gdscript
# EventLog with better error handling
func save_to_file(file_path: String) -> Result:
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if not file:
        var error_code = FileAccess.get_open_error()
        return Result.err("Failed to open file: %s (error %d)" % [file_path, error_code])
    
    var data = {
        "version": 1,
        "events": events
    }
    
    file.store_string(JSON.stringify(data, "\t"))
    var write_error = file.get_error()
    file.close()
    
    if write_error != OK:
        return Result.err("Write error: %d" % write_error)
    
    return Result.ok(file_path)
```

---

#### Issue E2: Missing Null Checks
**Severity:** High  
**Location:** Multiple files

Several functions assume objects exist without checking:

```gdscript
# MatchEngine.gd:137 - target could be freed/null
var target = attacker.get_current_target()
if target and target.is_alive():  # Good check here

# But Agent.gd:134 - current_target set but never validated
var target = attacker.get_current_target()
# get_current_target() returns null by default, but could reference freed object
```

**Recommendation:** Use `is_instance_valid()`:
```gdscript
func get_current_target() -> Agent:
    if is_instance_valid(current_target):
        return current_target
    return null
```

---

#### Issue E3: No JSON Schema Validation
**Severity:** Medium  
**Location:** `scripts/MapData.gd:15-65`

Map loading doesn't validate the JSON structure beyond checking for key existence:

```gdscript
# Current: No type checking
map.width = data.get("width", 100.0)  # What if width is a string?
```

**Recommendation:**
```gdscript
static func load_from_json(json_path: String) -> MapData:
    # ... file loading ...
    
    var data = json.data
    
    # Validate required fields and types
    var validation_errors = []
    
    if not data is Dictionary:
        push_error("Map data must be a JSON object")
        return MapData.new()
    
    if not data.has("width") or not data.width is float and not data.width is int:
        validation_errors.append("'width' must be a number")
    
    if not data.has("height") or not data.height is float and not data.height is int:
        validation_errors.append("'height' must be a number")
    
    if not data.has("zones") or not data.zones is Array:
        validation_errors.append("'zones' must be an array")
    
    if validation_errors.size() > 0:
        for err in validation_errors:
            push_error("Map validation: " + err)
        return MapData.new()
    
    # Continue with loading...
```

---

## 4. Performance Analysis

### 4.1 Current Performance Profile

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Tick processing | O(n²) | Agents check all other agents |
| LOS calculation | O(n × o) | n=agents, o=occluders |
| Event lookup by tick | O(e) | e=total events (linear scan) |
| Belief decay | O(n) | Per agent per tick |

### 4.2 Performance Bottlenecks

#### Issue P1: O(n²) Visibility Checks
**Severity:** Low (for 10 agents), High (for scaling)  
**Location:** `scripts/Agent.gd:54-78`

Each agent checks visibility to all other agents every tick:
- 10 agents × 10 checks × 20 TPS = 2,000 checks/second ✅
- 100 agents × 100 checks × 20 TPS = 200,000 checks/second ⚠️

**Optimization for larger agent counts:**
```gdscript
# Spatial partitioning for large agent counts
class_name SpatialGrid

var cell_size: float = 10.0
var grid: Dictionary = {}  # {cell_key: Array[Agent]}

func get_nearby_agents(pos: Vector2, radius: float) -> Array[Agent]:
    var results: Array[Agent] = []
    var min_cell = _get_cell(pos - Vector2(radius, radius))
    var max_cell = _get_cell(pos + Vector2(radius, radius))
    
    for x in range(min_cell.x, max_cell.x + 1):
        for y in range(min_cell.y, max_cell.y + 1):
            var key = _cell_key(x, y)
            if key in grid:
                results.append_array(grid[key])
    
    return results
```

---

#### Issue P2: Linear Event Search
**Severity:** Low  
**Location:** `scripts/EventLog.gd:25-39`

Querying events by tick uses linear search:

```gdscript
func get_events_for_tick(tick: int) -> Array[Dictionary]:
    var tick_events: Array[Dictionary] = []
    for event in events:  # O(n) every query
        if event.get("tick", -1) == tick:
            tick_events.append(event)
    return tick_events
```

**Optimization:**
```gdscript
# Add tick-indexed lookup
var events_by_tick: Dictionary = {}  # {tick: Array[event_indices]}

func log_event(event: Dictionary):
    if events.size() >= max_events:
        push_warning("Event log reached maximum size")
        return
    
    var index = events.size()
    events.append(event)
    
    var tick = event.get("tick", -1)
    if not tick in events_by_tick:
        events_by_tick[tick] = []
    events_by_tick[tick].append(index)

func get_events_for_tick(tick: int) -> Array[Dictionary]:
    var tick_events: Array[Dictionary] = []
    if tick in events_by_tick:
        for index in events_by_tick[tick]:
            tick_events.append(events[index])
    return tick_events  # Now O(k) where k = events at tick
```

---

#### Issue P3: Unnecessary Redraw Every Frame
**Severity:** Low  
**Location:** `scripts/Viewer2D.gd:123-125`

```gdscript
func _process(_delta):
    queue_redraw()  # Redraws every frame even when nothing changed
```

**Optimization:**
```gdscript
var needs_redraw: bool = false

func mark_dirty():
    needs_redraw = true

func _process(_delta):
    if needs_redraw:
        queue_redraw()
        needs_redraw = false
```

---

## 5. Scalability Assessment

### 5.1 Current Limits

| Resource | Current Limit | Notes |
|----------|---------------|-------|
| Agents | 10 | Works well |
| Events | 100,000 | Hardcoded in EventLog |
| Map size | 100x100 | Training ground |
| Tick rate | 20 TPS | Fixed |
| Match duration | ~83 min | Before event limit |

### 5.2 Scaling Considerations

#### For Larger Agent Counts (20+)
- Implement spatial partitioning (see P1)
- Consider octree for LOS checks
- Batch belief updates

#### For Longer Matches
- Implement event log rotation/streaming
- Consider binary format instead of JSON
- Implement checkpoint saves

#### For Network Play (Future)
- Current architecture supports deterministic lockstep
- Need to add input serialization
- Consider rollback netcode for latency tolerance

---

## 6. Infrastructure & CI/CD Review

### 6.1 Current CI/CD Pipeline

**File:** `.github/workflows/ci.yml`

**Current checks:**
- ✅ Project structure validation
- ✅ JSON file validation
- ✅ GDScript file presence check
- ✅ Documentation presence check
- ✅ License verification

**Missing:**
- ❌ GDScript linting (syntax/style)
- ❌ Automated tests execution
- ❌ Code coverage
- ❌ Build verification
- ❌ Version tagging

### 6.2 Recommended CI/CD Improvements

#### Improvement I1: Add GDScript Linting
```yaml
- name: Install gdtoolkit
  run: pip install gdtoolkit

- name: Lint GDScript files
  run: |
    gdlint scripts/*.gd
    gdformat --check scripts/*.gd
```

#### Improvement I2: Add Godot CLI Testing
```yaml
- name: Setup Godot
  uses: chickensoft-games/setup-godot@v1
  with:
    version: 4.2.0
    
- name: Run tests
  run: |
    godot --headless --script tests/test_determinism.gd --quit
```

#### Improvement I3: Add Build Verification
```yaml
- name: Export Windows build
  run: |
    godot --headless --export-release "Windows Desktop" build/radiantx.exe
    
- name: Verify export
  run: test -f build/radiantx.exe
```

#### Improvement I4: Add Release Workflow
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        
      - name: Build
        run: godot --headless --export-release "Windows Desktop" build/RadiantX.exe
        
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/RadiantX.exe
```

---

## 7. Testing Assessment

### 7.1 Current Test Coverage

**Existing tests:** `tests/test_determinism.gd`
- ✅ Same seed produces same results
- ✅ Different seeds produce different results  
- ✅ Replay file save/load consistency

**Missing test categories:**
- ❌ Unit tests for individual components
- ❌ Integration tests for component interactions
- ❌ Edge case tests (boundary conditions)
- ❌ Performance/stress tests
- ❌ Regression tests

### 7.2 Recommended Test Additions

#### Test T1: Agent Behavior Tests
```gdscript
# tests/test_agent.gd
extends Node

func test_agent_takes_damage():
    var agent = Agent.new()
    agent.reset()
    assert(agent.health == 100.0)
    
    agent.take_damage(25.0, 0)
    assert(agent.health == 75.0)
    
    agent.take_damage(100.0, 1)
    assert(agent.health == 0.0)
    assert(not agent.is_alive())

func test_agent_flashed_state():
    var agent = Agent.new()
    agent.reset()
    assert(not agent.is_flashed())
    
    agent.notify_flashed(0, 10.0)  # Distance 10
    assert(agent.is_flashed())
    
    agent.is_flashed_until = 0  # Simulate time passing
    assert(not agent.is_flashed())

func test_belief_decay():
    var agent = Agent.new()
    agent.reset()
    
    # Add a belief
    agent.beliefs[1] = {
        "position": Vector2(50, 50),
        "health": 100.0,
        "state": Agent.State.IDLE,
        "confidence": 1.0
    }
    agent.last_seen[1] = 0
    
    # Simulate 20 ticks without seeing
    for tick in range(1, 21):
        var expected_confidence = max(0.0, 1.0 - (tick * 0.05))
        # Would need to call update_beliefs() with mock data
```

#### Test T2: Line-of-Sight Tests
```gdscript
# tests/test_map_los.gd
extends Node

func test_los_clear():
    var map = MapData.new()
    map.occluders = []
    
    assert(map.check_line_of_sight(Vector2(0, 0), Vector2(100, 100)))

func test_los_blocked():
    var map = MapData.new()
    map.occluders = [{
        "x": 40,
        "y": 40,
        "width": 20,
        "height": 20
    }]
    
    assert(not map.check_line_of_sight(Vector2(0, 0), Vector2(100, 100)))

func test_los_edge_cases():
    var map = MapData.new()
    map.occluders = [{"x": 50, "y": 50, "width": 10, "height": 10}]
    
    # Same point
    assert(map.check_line_of_sight(Vector2(0, 0), Vector2(0, 0)))
    
    # Point inside occluder
    assert(not map.check_line_of_sight(Vector2(0, 0), Vector2(55, 55)))
```

#### Test T3: Event Log Stress Test
```gdscript
# tests/test_eventlog_stress.gd
extends Node

func test_event_limit():
    var log = EventLog.new()
    
    # Fill to limit
    for i in range(100001):
        log.log_event({"type": "test", "tick": i})
    
    assert(log.events.size() == 100000)  # Should stop at limit

func test_large_replay_save_load():
    var log = EventLog.new()
    
    # Add 10000 events
    for i in range(10000):
        log.log_event({
            "type": "test",
            "tick": i,
            "data": {"x": randf() * 100, "y": randf() * 100}
        })
    
    # Save and load
    var path = "user://stress_test.json"
    assert(log.save_to_file(path))
    
    var loaded = EventLog.new()
    assert(loaded.load_from_file(path))
    assert(loaded.events.size() == 10000)
```

---

## 8. Security Considerations

### 8.1 Current Assessment: Low Risk (Offline Game)

As an offline, single-player Windows application, the attack surface is minimal.

### 8.2 Potential Concerns

#### S1: Malicious Replay Files
**Risk:** Low  
**Vector:** User loads crafted replay JSON

**Current vulnerability:**
```gdscript
# MapData.gd - Values used without bounds checking
map.width = data.get("width", 100.0)  # Could be negative or huge
```

**Mitigation:**
```gdscript
map.width = clamp(data.get("width", 100.0), 10.0, 10000.0)
map.height = clamp(data.get("height", 100.0), 10.0, 10000.0)
```

#### S2: Path Traversal in File Operations
**Risk:** Low  
**Vector:** Crafted file paths

The current implementation uses Godot's `user://` prefix which is sandboxed, but explicit validation is recommended:

```gdscript
func save_to_file(file_path: String) -> bool:
    # Validate path is in allowed directory
    if not file_path.begins_with("user://"):
        push_error("Invalid save path: must use user:// directory")
        return false
    
    # Prevent directory traversal
    if ".." in file_path:
        push_error("Invalid path: directory traversal not allowed")
        return false
```

---

## 9. Prioritized Improvement Recommendations

### Priority 1: Critical (Fix Immediately)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| A3 | Incomplete replay state restoration | Agent.gd, MatchEngine.gd | Broken replay scrubbing |
| D1 | Non-deterministic dictionary iteration | Agent.gd:121 | Potential desync |
| E1 | Silent file operation failures | Main.gd:203-207 | Lost replays |

### Priority 2: High (Fix Soon)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| E2 | Missing null/validity checks | Multiple | Potential crashes |
| E3 | No JSON schema validation | MapData.gd | Cryptic errors |
| D2 | Floating-point drift | Agent.gd:159 | Long match desync |

### Priority 3: Medium (Plan for Next Sprint)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| A1 | Tight coupling in Main.gd | Main.gd:118-151 | Maintainability |
| P2 | Linear event search | EventLog.gd | Slow replay queries |
| I1-4 | CI/CD improvements | .github/workflows | Automation |
| T1-3 | Test coverage gaps | tests/ | Quality assurance |

### Priority 4: Low (Nice to Have)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| A2 | Missing state machine pattern | Agent.gd | Code organization |
| P1 | O(n²) visibility (future) | Agent.gd | Scaling to 20+ agents |
| P3 | Unnecessary redraws | Viewer2D.gd | Minor performance |

---

## 10. Implementation Roadmap

### Phase 1: Critical Fixes (1-2 days)
1. Fix replay state serialization (A3)
2. Sort dictionary keys for determinism (D1)
3. Add user feedback for file operations (E1)

### Phase 2: Reliability (3-5 days)
1. Add null checks and validation (E2, E3)
2. Implement position snapping (D2)
3. Clean up unused parameters (D3)
4. Add input validation for map loading

### Phase 3: Infrastructure (1 week)
1. Add GDScript linting to CI
2. Add automated test execution
3. Create release workflow
4. Expand test coverage

### Phase 4: Optimization (As needed)
1. Add tick-indexed event lookup
2. Implement spatial partitioning (if scaling)
3. Optimize redraw cycle

---

## Conclusion

RadiantX has a solid architectural foundation for a deterministic tactical simulation. The component separation is clean, the tick-based engine design is sound, and the documentation is comprehensive.

The primary areas needing attention are:
1. **Error handling** - Currently too optimistic
2. **Determinism edge cases** - Dictionary ordering and float precision
3. **Replay robustness** - Full state serialization
4. **CI/CD maturity** - Add actual testing and building

With the recommended improvements, RadiantX will be production-ready for its target use case of offline Windows tactical simulation.

---

*Review conducted by Agent 006 - Backend Architecture & Infrastructure Savant*
