# Backend Architecture Review: RadiantX

**Review Date:** December 2024  
**Reviewer:** Agent 006 - Backend Architecture & Infrastructure Savant

## Executive Summary

RadiantX demonstrates solid foundational architecture for a deterministic tactical FPS simulation. The new Data and Sim modules introduce a well-structured separation of concerns. However, several integration gaps and architectural improvements are needed before the new systems can be considered production-ready.

**Overall Assessment:** 🟡 Good foundation with critical integration gaps

---

## Architecture Analysis

### 1. Data Flow Assessment

#### Current State
```
                     ┌──────────────────────────┐
                     │       DataLoader         │
                     │   (Singleton Pattern)    │
                     └───────────┬──────────────┘
                                 │ loads
                    ┌────────────┼────────────────┐
                    ▼            ▼                ▼
              AgentDef      WeaponDef        UtilityDef
              (static)      (static)         (static)
                                 
                    ╳ NO CONNECTION ╳
                                 
              ┌────────────────────────────────────┐
              │           MatchEngine              │
              │  (uses old Agent class directly)   │
              └────────────────────────────────────┘
                                 │
                                 ▼
                           Agent.gd
                    (hardcoded values, no Defs)
```

#### Issues Identified
1. **No Bridge Between Systems**: The new `Data/` and `Sim/` modules are completely disconnected from `MatchEngine.gd` and `Agent.gd`
2. **Dual State Models**: `Agent.gd` has its own state model vs. `AgentState.gd` in Data module
3. **Hardcoded Combat Values**: `Agent.get_damage()` returns hardcoded `25.0` instead of using `WeaponDef`

### 2. Scalability Evaluation

#### Strengths
- ✅ Fixed 20 TPS tick rate limits CPU load predictably
- ✅ LOD-based duel resolution (`DuelResolver`) enables variable fidelity
- ✅ TTK Monte Carlo engine supports batch simulation
- ✅ Event log has size limit (100k events)

#### Scalability Concerns
| Component | Issue | Impact | Priority |
|-----------|-------|--------|----------|
| `_process_combat()` | O(n²) nested loop over all agents | High latency at 50+ agents | 🔴 High |
| `update_beliefs()` | O(n) per agent, O(n²) total | Same as above | 🔴 High |
| `check_line_of_sight()` | O(occluders) per raycast | Scales poorly with map complexity | 🟡 Medium |
| `DataLoader` | Loads all JSON at startup | Memory bloat with large datasets | 🟡 Medium |
| `EventLog.get_events_for_tick()` | O(n) linear scan | Slow for large replays | 🟢 Low |

### 3. Data Layer Design Review

#### Separation of Concerns: ✅ Correct

The pattern of separating definitions (`*Def.gd`) from runtime state (`*State.gd`) is architecturally sound:

```
Definition (Immutable)          Runtime State (Mutable)
─────────────────────          ──────────────────────
AgentDef                   →   AgentState
  - id                          - entity_id
  - base_hp                     - hp (current)
  - traits                      - stress
  - loadout_*_ids               - weapon: WeaponState

WeaponDef                  →   WeaponState
  - magazine_size               - ammo_in_mag
  - damage profile              - fire_cooldown
  - recoil profile              - recoil (accumulated)

UtilityDef                 →   UtilityState
  - max_charges                 - charges (current)
  - cooldown                    - cooldown_timer
```

#### Issues in Data Layer
1. **Missing max_hp reference**: `AgentState.heal()` has no upper bound
2. **No factory pattern**: Creating `AgentState` from `AgentDef` is manual
3. **Circular dependency risk**: `WeaponState.update()` requires `WeaponDef` parameter

### 4. Infrastructure Patterns Assessment

#### Missing Patterns

| Pattern | Current State | Recommendation |
|---------|---------------|----------------|
| **Service Registry** | ❌ None | Add for accessing DataLoader, active engines |
| **Object Pooling** | ❌ None | Pool `DuelContext`, `DuelResult`, `SimEvent` objects |
| **State Snapshots** | ⚠️ Partial | Formalize for rollback/replay |
| **Async Processing** | ❌ None | Consider for batch TTK simulations |
| **Caching** | ❌ None | Cache LOS calculations, computed aim sigma |

#### Singleton Concerns
`DataLoader` uses a static singleton pattern that's fragile in Godot:
```gdscript
static var _instance: DataLoader = null
static func get_instance() -> DataLoader:
    if _instance == null:
        _instance = DataLoader.new()
    return _instance
```
**Problem**: Instance created by `_ready()` vs `get_instance()` can differ.

---

## Critical Integration Issues

### Issue 1: MatchEngine Doesn't Use New Data System

**Current**: `MatchEngine.gd` line 163-174 uses hardcoded hit chance calculations:
```gdscript
func _calculate_hit_chance(attacker: Agent, target: Agent) -> float:
    var distance = attacker.position.distance_to(target.position)
    var base_chance = 0.3  # HARDCODED
    var distance_factor = clamp(1.0 - (distance / 50.0), 0.1, 1.0)
    ...
```

**Required**: Should use `DuelContext.compute_hit_probability()` which integrates:
- Weapon spread profiles
- Agent traits (aim, recoil control)
- Status effects (flash, concuss)
- Stance modifiers

### Issue 2: Agent.gd Has Duplicate State Model

`Agent.gd` duplicates what `AgentState.gd` provides:

| Agent.gd | AgentState.gd | Conflict |
|----------|---------------|----------|
| `health: float` | `hp: float` | Duplicate field |
| `is_flashed_until: int` | `status.flash_timer: float` | Different types! |
| `beliefs: Dictionary` | Not present | Missing in new model |
| `get_damage() -> 25.0` | Uses WeaponDef | Hardcoded vs data-driven |

### Issue 3: No Duel Engine Integration

`MatchEngine._process_combat()` doesn't use the new duel engines:
```gdscript
# Current: Simple roll against hit_chance
if rng.randf() < hit_chance:
    target.take_damage(attacker.get_damage(), current_tick)

# Should be: Use DuelResolver for proper simulation
var context = DuelContext.new(attacker_state, target_state)
context.weapon_def = DataLoader.get_instance().get_weapon(weapon_id)
var result = duel_resolver.resolve_duel(context, alive_a, alive_b)
```

---

## Prioritized Improvement Roadmap

### 🔴 Priority 1: Critical Integration (Required for functional system)

#### 1.1 Create AgentBridge Class
**Purpose**: Bridge between old `Agent.gd` and new `AgentState`/`AgentDef`

```gdscript
# scripts/AgentBridge.gd
class_name AgentBridge
extends RefCounted

var agent_def: AgentDef
var agent_state: AgentState
var legacy_agent: Agent  # For gradual migration

static func create_from_def(def: AgentDef, entity_id: int) -> AgentBridge:
    var bridge = AgentBridge.new()
    bridge.agent_def = def
    bridge.agent_state = AgentState.new(def, entity_id)
    # Initialize weapon state from loadout
    if def.loadout_weapon_ids.size() > 0:
        var weapon_def = DataLoader.get_instance().get_weapon(def.loadout_weapon_ids[0])
        if weapon_def:
            bridge.agent_state.weapon = WeaponState.new(weapon_def)
    return bridge

func sync_to_legacy(agent: Agent):
    agent.health = agent_state.hp
    agent.position = agent_state.pos
    # ... etc

func sync_from_legacy(agent: Agent):
    agent_state.hp = agent.health
    agent_state.pos = agent.position
    # ... etc
```

#### 1.2 Integrate DuelResolver into MatchEngine
**File**: `scripts/MatchEngine.gd`

```gdscript
# Add these member variables:
var duel_resolver: DuelResolver
var data_loader: DataLoader

func _ready():
    rng = RandomNumberGenerator.new()
    event_log = EventLog.new()
    add_child(event_log)
    
    # Initialize new systems
    data_loader = DataLoader.get_instance()
    data_loader.load_all()
    duel_resolver = DuelResolver.new()

func _process_combat():
    # ... existing LOS checks ...
    
    # Replace simple hit roll with DuelResolver
    var context = _create_duel_context(attacker, target)
    var result = duel_resolver.resolve_duel(context, _count_alive(Team.TEAM_A), _count_alive(Team.TEAM_B))
    
    if result.winner_id == attacker.entity_id:
        target.take_damage(result.damage_dealt, current_tick)
        _log_duel_result(result)
```

#### 1.3 Fix AgentState.heal() Bounds
**File**: `scripts/Data/AgentState.gd`

```gdscript
var max_hp: float = 100.0  # Add this field

func _init(agent_def: AgentDef = null, id: int = 0):
    status = StatusState.new()
    weapon = WeaponState.new()
    
    if agent_def:
        agent_id = agent_def.id
        entity_id = id
        hp = agent_def.base_hp
        max_hp = agent_def.base_hp  # Store max
        armor = agent_def.base_armor

func heal(amount: float):
    hp = minf(hp + amount, max_hp)  # Bound to max_hp
```

### 🟡 Priority 2: Scalability Improvements

#### 2.1 Spatial Partitioning for Combat
**Purpose**: Reduce O(n²) agent-pair checks to O(n log n)

```gdscript
# scripts/SpatialGrid.gd
class_name SpatialGrid
extends RefCounted

var cell_size: float = 10.0
var cells: Dictionary = {}  # Vector2i -> Array[Agent]

func update_agent(agent: Agent, old_pos: Vector2):
    var old_cell = _pos_to_cell(old_pos)
    var new_cell = _pos_to_cell(agent.position)
    if old_cell != new_cell:
        _remove_from_cell(old_cell, agent)
        _add_to_cell(new_cell, agent)

func get_nearby_agents(pos: Vector2, radius: float) -> Array[Agent]:
    var result: Array[Agent] = []
    var cell_radius = int(ceil(radius / cell_size))
    var center_cell = _pos_to_cell(pos)
    
    for dx in range(-cell_radius, cell_radius + 1):
        for dy in range(-cell_radius, cell_radius + 1):
            var cell = center_cell + Vector2i(dx, dy)
            if cells.has(cell):
                result.append_array(cells[cell])
    return result
```

#### 2.2 LOS Cache with Invalidation
```gdscript
# Add to MatchEngine
var los_cache: Dictionary = {}  # "from_x,from_y,to_x,to_y" -> bool
var los_cache_tick: int = -1

func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
    # Invalidate cache each tick (positions change)
    if current_tick != los_cache_tick:
        los_cache.clear()
        los_cache_tick = current_tick
    
    var key = "%d,%d,%d,%d" % [int(from.x), int(from.y), int(to.x), int(to.y)]
    if los_cache.has(key):
        return los_cache[key]
    
    var result = map_data.check_line_of_sight(from, to) if map_data else true
    los_cache[key] = result
    return result
```

#### 2.3 Object Pooling for SimEvents
```gdscript
# scripts/ObjectPool.gd
class_name ObjectPool
extends RefCounted

var _pools: Dictionary = {}  # class_name -> Array

func acquire(cls: GDScript) -> RefCounted:
    var pool_key = cls.resource_path
    if not _pools.has(pool_key):
        _pools[pool_key] = []
    
    var pool = _pools[pool_key]
    if pool.is_empty():
        return cls.new()
    return pool.pop_back()

func release(obj: RefCounted):
    var pool_key = obj.get_script().resource_path
    if not _pools.has(pool_key):
        _pools[pool_key] = []
    _pools[pool_key].append(obj)
```

### 🟢 Priority 3: Infrastructure Enhancements

#### 3.1 Service Locator Pattern
```gdscript
# scripts/Services.gd
class_name Services
extends Node

static var _instance: Services

var data_loader: DataLoader
var object_pool: ObjectPool
var spatial_grid: SpatialGrid

static func get_instance() -> Services:
    return _instance

func _ready():
    _instance = self
    data_loader = DataLoader.new()
    data_loader.load_all()
    add_child(data_loader)
    
    object_pool = ObjectPool.new()
    spatial_grid = SpatialGrid.new()
```

#### 3.2 EventLog Index for O(1) Tick Lookup
```gdscript
# Modify EventLog.gd
var events: Array[Dictionary] = []
var _tick_index: Dictionary = {}  # tick -> start_index

func log_event(event: Dictionary):
    if events.size() >= max_events:
        push_warning("Event log reached maximum size")
        return
    
    var tick = event.get("tick", -1)
    if tick >= 0 and not _tick_index.has(tick):
        _tick_index[tick] = events.size()
    
    events.append(event)

func get_events_for_tick(tick: int) -> Array[Dictionary]:
    if not _tick_index.has(tick):
        return []
    
    var start = _tick_index[tick]
    var result: Array[Dictionary] = []
    for i in range(start, events.size()):
        if events[i].get("tick", -1) != tick:
            break
        result.append(events[i])
    return result
```

#### 3.3 State Snapshot System
```gdscript
# scripts/StateSnapshot.gd
class_name StateSnapshot
extends RefCounted

var tick: int
var agent_states: Array[Dictionary] = []
var active_effects: Array[Dictionary] = []

static func capture(engine: MatchEngine) -> StateSnapshot:
    var snap = StateSnapshot.new()
    snap.tick = engine.current_tick
    for agent in engine.agents:
        snap.agent_states.append(agent.get_state())
    return snap

func apply(engine: MatchEngine):
    engine.current_tick = tick
    for i in range(mini(agent_states.size(), engine.agents.size())):
        engine.agents[i].set_state(agent_states[i])
```

---

## Testing Recommendations

### Unit Tests Required
1. **AgentState roundtrip**: `to_dict()` → `from_dict()` preserves all fields
2. **DuelContext hit probability**: Verify formula against expected ranges
3. **WeaponDef parsing**: All JSON weapons load without errors
4. **DuelResolver LOD switching**: Correct engine selected for each scenario

### Integration Tests Required
1. **MatchEngine + DataLoader**: Match uses loaded weapon stats
2. **TTK Monte Carlo**: Results statistically consistent (±5% over 1000 runs)
3. **Replay determinism**: Same seed → identical event logs

### Performance Benchmarks
| Scenario | Target | Measurement |
|----------|--------|-------------|
| 10v10 match, 100 ticks | <50ms total | Profile `process_tick()` |
| 1000 TTK simulations | <100ms | Profile `TTKDuelEngine.simulate()` |
| LOS check, 100 occluders | <0.1ms per call | Profile `check_line_of_sight()` |

---

## Implementation Order

1. **Week 1**: Priority 1.1-1.3 (Critical integration)
2. **Week 2**: Priority 2.1-2.2 (Scalability core)
3. **Week 3**: Priority 3.1-3.3 (Infrastructure)
4. **Week 4**: Testing and performance validation

---

## Appendix: File-by-File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `scripts/MatchEngine.gd` | **Modify** | Integrate DuelResolver, DataLoader |
| `scripts/Agent.gd` | **Refactor** | Remove hardcoded values, use AgentDef |
| `scripts/Data/AgentState.gd` | **Modify** | Add max_hp, bound heal() |
| `scripts/AgentBridge.gd` | **Create** | Bridge legacy to new state |
| `scripts/SpatialGrid.gd` | **Create** | Spatial partitioning |
| `scripts/ObjectPool.gd` | **Create** | Object pooling |
| `scripts/Services.gd` | **Create** | Service locator |
| `scripts/EventLog.gd` | **Modify** | Add tick indexing |
| `scripts/StateSnapshot.gd` | **Create** | Snapshot/rollback |

---

*End of Architecture Review*
