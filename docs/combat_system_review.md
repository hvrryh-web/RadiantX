# RadiantX Combat System Review

**Reviewer**: Agent 007 - Elite Games Developer  
**Date**: 2025-12-17  
**Version**: 1.0

---

## Executive Summary

RadiantX demonstrates a **solid foundation** for a tactical FPS simulation with well-architected combat systems. The dual-engine approach (raycast vs TTK) is a clever Level-of-Detail strategy. The weapon profiles are realistic, the effect system covers most tactical needs, and the data-driven design allows for extensive tuning.

**Overall Grade**: B+ (Strong foundation with targeted improvements needed)

---

## 1. Combat System Design Assessment

### 1.1 Dual-Engine Approach (RaycastDuelEngine + TTKDuelEngine)

**Verdict: ✅ Excellent Design Choice**

The LOD-based duel resolution is a sophisticated approach that balances fidelity with performance:

| Engine | Use Case | Iterations | Fidelity |
|--------|----------|------------|----------|
| RaycastDuelEngine | On-camera, clutch moments | 1 (deterministic) | Full |
| TTKDuelEngine | Background fights | 32-256 (Monte Carlo) | Statistical |

**Strengths:**
- Intelligent viewport-based LOD switching
- Clutch detection (≤2 players alive = high LOD)
- Round impact estimation for mid-LOD decisions
- Gaussian aim model matches real player behavior

**Improvements Needed:**

#### 🔴 CRITICAL: Missing Bidirectional Duel Resolution
The current duel engines only simulate one shooter attacking one target. Real duels are **bidirectional** - both players shoot at each other simultaneously.

```gdscript
# Current: One-way duel
func simulate(context: DuelContext) -> DuelResult:
    # Only shooter attacks target

# Needed: Bidirectional duel
func simulate_bidirectional(context_a: DuelContext, context_b: DuelContext) -> DuelOutcome:
    # Both agents attack simultaneously, interleaved shots
```

#### 🟡 MEDIUM: First-Shot Advantage Not Implemented
The `SpreadProfile.first_shot_bonus` exists in data but isn't used in `DuelContext.compute_aim_sigma()`.

#### 🟡 MEDIUM: Armor Penetration Not Used in Duels
`PenetrationProfile` exists but raycast doesn't calculate wall penetration damage reduction.

---

### 1.2 DuelContext - Combat Computation Hub

**Verdict: ✅ Well-Designed**

The `DuelContext` properly encapsulates all combat modifiers:
- Distance-based accuracy (angular radius model)
- Movement penalties
- Stance modifiers (crouch bonus)
- Status effect penalties (flash, concussion)
- Trait-based skill modifiers
- Recoil accumulation

**Improvements Needed:**

#### 🟡 MEDIUM: Missing Cover System Integration
`cover_factor` exists but is never set or used in hit calculations.

#### 🟡 MEDIUM: Target Movement Penalty Missing
`target_speed` is tracked but doesn't affect hit probability. Moving targets should be harder to hit.

---

## 2. Weapon Profile Realism Assessment

### 2.1 Damage Values

**Verdict: ✅ Realistic (CS:GO-Accurate)**

| Weapon | Base Damage | Head Mult | 1-Hit Headshot? | Assessment |
|--------|-------------|-----------|-----------------|------------|
| AK-47  | 36          | 4.0x      | 144 (✅ kills)  | Accurate   |
| M4     | 33          | 4.0x      | 132 (✅ kills)  | Accurate   |
| AWP    | 115         | 4.0x      | 460 (overkill)  | Accurate   |
| Deagle | 63          | 4.0x      | 252 (✅ kills)  | Accurate   |
| SMG    | 26          | 4.0x      | 104 (✅ kills)  | Accurate   |

### 2.2 Rate of Fire

| Weapon | RPM | Real CS:GO | Assessment |
|--------|-----|------------|------------|
| AK-47  | 600 | 600 RPM    | ✅ Perfect |
| M4     | 666 | 666 RPM    | ✅ Perfect |
| AWP    | 41  | ~41 RPM    | ✅ Perfect |
| SMG    | 800 | ~800 RPM   | ✅ Perfect |

### 2.3 Damage Falloff Curves

**Verdict: ✅ Realistic**

The `rangeMultiplierKeys` curves properly model:
- Rifles maintaining damage at range (70-85% at 100m)
- SMGs dropping off aggressively (50% at 50m)
- Shotguns having extreme falloff (20% at 20m)
- AWP having no falloff (100% at all ranges)

### 2.4 Spread Profiles

**Verdict: ⚠️ Good but Missing Details**

**Strengths:**
- Base sigma values are reasonable (0.005-0.08 radians)
- Movement penalty properly modeled
- Crouch multiplier accurate

**Missing:**
- No running inaccuracy modeling (only move_sigma_add)
- No spray pattern data (recoil patterns are oversimplified)
- No ADS (aim down sights) vs hipfire differentiation

---

## 3. Utility/Ability System Review

### 3.1 Effect Coverage

**Verdict: ✅ Comprehensive (13 Effect Types)**

| Effect | Tactical Use | Implementation |
|--------|--------------|----------------|
| Smoke | Vision denial | ✅ Complete with density |
| FlashBlind | Entry denial | ✅ LOS + facing check |
| Concuss | Slow + disrupt | ✅ Duration-based |
| Slow | Area denial | ✅ Speed modifier |
| Burn | Area denial | ✅ DPS over time |
| Heal | Sustainability | ✅ HPS over time |
| Shield | Damage absorption | ✅ Armor add |
| Reveal | Intel gathering | ✅ Duration-based |
| Suppress | Ability denial | ✅ Prevents utility use |
| Knockback | Mobility | ✅ Force-based |
| Wall | Path blocking | ✅ Health-based |
| Trap | Alert system | ✅ Trigger-based |
| DecoySound | Misdirection | ✅ Audio simulation |

### 3.2 CS Grenades Assessment

**Verdict: ✅ Accurate to Source Material**

| Grenade | Duration | Radius | Assessment |
|---------|----------|--------|------------|
| Smoke | 18s | 4.5 units | CS:GO: ~18s, accurate |
| Flash | 2.5s max | 12 units | CS:GO: 2-3s, accurate |
| HE | Instant | 8 units | CS:GO: ~7m, accurate |
| Molotov | 7s | 3.5 units | CS:GO: 7s, accurate |

### 3.3 Valorant-Style Abilities

**Verdict: ✅ Good Coverage**

The 11 ability templates cover all agent archetypes:
- Controller: Smoke, Incendiary
- Initiator: Flash, Concuss, Reveal
- Duelist: Satchel (knockback), Suppress
- Sentinel: Trap, Wall
- Support: Heal, Shield

**Missing Ability Types:**
- Teleport/Dash (mobility abilities)
- Clone/Decoy (AI-controlled entities)
- Resurrection (revival mechanics)
- Ultimate abilities (high-impact, limited use)

---

## 4. Simulation Accuracy Assessment

### 4.1 20 TPS Engine Integration

**Verdict: ⚠️ Incomplete Integration**

The `MatchEngine.gd` (20 TPS) and the new duel engines (`RaycastDuelEngine`, `TTKDuelEngine`) are **not yet integrated**.

**Current State:**
```gdscript
# MatchEngine.gd - Old combat system (simplified)
func _calculate_hit_chance(attacker: Agent, target: Agent) -> float:
    var distance = attacker.position.distance_to(target.position)
    var base_chance = 0.3
    var distance_factor = clamp(1.0 - (distance / 50.0), 0.1, 1.0)
    return base_chance * distance_factor * flash_factor
```

**Needed:**
```gdscript
# Should use DuelResolver with full weapon/agent defs
func _process_combat():
    var duel_resolver = DuelResolver.new()
    duel_resolver.set_map(map_data)
    
    for engagement in active_engagements:
        var context = DuelContext.new(attacker_state, target_state)
        context.weapon_def = get_weapon_def(attacker.equipped_weapon)
        var result = duel_resolver.resolve_duel(context, ...)
```

### 4.2 Agent.gd vs AgentState.gd Duality

**Verdict: ⚠️ Architecture Needs Unification**

There are **two parallel agent systems**:

1. `Agent.gd` (Node2D) - Original, used by MatchEngine
2. `AgentState.gd` (RefCounted) - New, used by duel engines

These need to be unified or bridged.

---

## 5. Identified Gameplay Gaps

### Priority 1: Critical (Required for Functional Combat)

| Gap | Description | Impact |
|-----|-------------|--------|
| **Duel Engine Integration** | MatchEngine doesn't use new duel engines | Combat is simplified |
| **Bidirectional Duels** | Only one-way shooting simulated | Unrealistic exchanges |
| **Agent State Bridge** | Agent.gd ↔ AgentState.gd disconnect | Systems don't communicate |

### Priority 2: High (Core Tactical Features)

| Gap | Description | Impact |
|-----|-------------|--------|
| **Recoil Patterns** | Only accumulation, no spray patterns | No spray control skill |
| **Peeking/Angles** | No angle advantage modeling | Missing core FPS mechanic |
| **Trade Fragging** | No refrag timing simulation | Team tactics limited |
| **Economy System** | No buy phase/money | Missing strategic depth |

### Priority 3: Medium (Enhanced Realism)

| Gap | Description | Impact |
|-----|-------------|--------|
| **Tagging** | No movement slow on hit | Missing combat feedback |
| **Wallbang Calculation** | Penetration defined but unused | Tactical depth |
| **Sound Propagation** | No footstep/gunfire audio model | Intel limited |
| **Bomb/Objective** | No defuse timer/plant mechanics | Missing win conditions |

### Priority 4: Polish (Advanced Features)

| Gap | Description | Impact |
|-----|-------------|--------|
| **Spray Transfer** | No target switching penalty | Unrealistic multi-kills |
| **Counter-Strafing** | No instant stop accuracy recovery | Missing skill expression |
| **Crouch Spam** | No repeated crouch penalty | Exploitable |

---

## 6. Prioritized Actionable Improvements

### 🔴 Priority 1: Must Have (Next Sprint)

#### 1.1 Integrate DuelResolver with MatchEngine
Create a bridge between the simulation tick and the duel resolution system.

```gdscript
# In MatchEngine.gd
var duel_resolver: DuelResolver
var data_loader: DataLoader

func _ready():
    duel_resolver = DuelResolver.new()
    data_loader = DataLoader.new()
    # Load weapon/agent definitions
    
func _process_combat():
    for attacker in agents:
        if not attacker.is_alive() or not attacker.current_target:
            continue
        
        var context = _build_duel_context(attacker, attacker.current_target)
        var result = duel_resolver.resolve_duel(context, count_alive(ATTACK), count_alive(DEFEND))
        _apply_duel_result(result)
```

#### 1.2 Implement Bidirectional Duel Resolution
Add mutual combat simulation.

```gdscript
# New file: scripts/Sim/MutualDuel.gd
class_name MutualDuel

func resolve(agent_a: AgentState, agent_b: AgentState, 
             weapon_a: WeaponDef, weapon_b: WeaponDef) -> Dictionary:
    # Interleave shots based on reaction times and fire rates
    # Return {winner_id, loser_id, time_to_resolution, events[]}
```

#### 1.3 Bridge Agent.gd and AgentState.gd
Create adapter to synchronize the two systems.

```gdscript
# In Agent.gd
func to_agent_state() -> AgentState:
    var state = AgentState.new()
    state.pos = position
    state.hp = health
    state.facing_rad = velocity.angle() if velocity.length() > 0 else 0
    # ... map all fields
    return state

func apply_agent_state(state: AgentState):
    health = state.hp
    position = state.pos
    # ... sync back
```

### 🟡 Priority 2: Should Have (Next Month)

#### 2.1 Implement First-Shot Bonus
```gdscript
# In DuelContext.compute_aim_sigma()
if shooter_state and shooter_state.weapon:
    if shooter_state.weapon.last_fired_at < 0 or time - shooter_state.weapon.last_fired_at > 0.5:
        sigma += weapon_def.spread.first_shot_bonus  # Negative = tighter spread
```

#### 2.2 Add Target Movement Penalty
```gdscript
# In DuelContext.compute_hit_probability()
var target_move_factor = 1.0 - (target_speed * 0.02)  # 2% per unit/s
return base_probability * clampf(target_move_factor, 0.5, 1.0)
```

#### 2.3 Implement Cover System
```gdscript
# In DuelContext
func set_cover_from_map(map: MapData, shooter_pos: Vector2, target_pos: Vector2):
    cover_factor = map.get_cover_at(target_pos, shooter_pos)
    exposure = 1.0 - cover_factor
```

#### 2.4 Add Tagging (Slow on Hit)
```gdscript
# In AgentState
var tag_slow_factor: float = 1.0

func apply_tag(weapon_def: WeaponDef):
    # Heavier weapons tag more
    tag_slow_factor = 0.5  # 50% move speed
    tag_timer = 0.4  # 400ms recovery
```

### 🟢 Priority 3: Nice to Have (Future)

#### 3.1 Spray Pattern System
Replace simple recoil accumulation with learnable spray patterns.

```gdscript
# New: SprayPattern.gd
class_name SprayPattern

var pattern_points: Array[Vector2]  # Offset per shot
var current_shot: int = 0

func get_offset_for_shot(shot_index: int) -> Vector2:
    if shot_index >= pattern_points.size():
        return pattern_points[-1] * (1 + (shot_index - pattern_points.size()) * 0.1)
    return pattern_points[shot_index]
```

#### 3.2 Economy System
```gdscript
# New: scripts/Economy/EconomyManager.gd
class_name EconomyManager

var team_money: Dictionary = {DataTypes.TeamSide.ATTACK: [], DataTypes.TeamSide.DEFEND: []}
const ROUND_WIN_BONUS = 3250
const ROUND_LOSS_BASE = 1400
const ROUND_LOSS_INCREMENT = 500
```

#### 3.3 Objective System (Bomb Plant/Defuse)
```gdscript
# New: scripts/Objectives/BombSite.gd
class_name BombSite

var site_id: String
var bounds: Rect2
var is_planted: bool = false
var plant_timer: float = 0.0
var defuse_timer: float = 0.0

const PLANT_TIME = 3.0
const DEFUSE_TIME = 5.0  # 10.0 without kit
const EXPLOSION_TIME = 40.0
```

---

## 7. Quick Wins (Minimal Effort, High Impact)

### 7.1 Fix Unused First-Shot Bonus (5 minutes)
In `DuelContext.gd:compute_aim_sigma()`, add:
```gdscript
# After line 51
if shooter_state and shooter_state.weapon and shooter_state.weapon.recoil == 0:
    sigma += weapon_def.spread.first_shot_bonus
```

### 7.2 Add Target Movement Modifier (5 minutes)
In `DuelContext.gd:compute_hit_probability()`, add:
```gdscript
# After line 113
var move_penalty = 1.0 - clampf(target_speed * 0.015, 0.0, 0.3)
return (1.0 - exp(-(r_ang * r_ang) / (2.0 * sigma * sigma))) * move_penalty
```

### 7.3 Use Cover Factor in Exposure (2 minutes)
In `DuelContext.gd:_init()`, add:
```gdscript
exposure = 1.0 - cover_factor
```

---

## 8. Recommended Implementation Order

```
Week 1: Foundation
├── 1.1 Integrate DuelResolver ← START HERE
├── 1.3 Bridge Agent ↔ AgentState
└── Test integration

Week 2: Core Combat
├── 1.2 Bidirectional Duels
├── Quick Wins (7.1, 7.2, 7.3)
└── Test combat feel

Week 3: Tactical Depth
├── 2.4 Tagging system
├── 2.2 Target movement penalty
└── 2.3 Cover system

Week 4: Polish
├── 2.1 First-shot bonus
├── Sound propagation basics
└── Balance tuning
```

---

## 9. Conclusion

RadiantX has a **strong technical foundation** with well-thought-out data structures and a clever dual-engine approach. The main gap is **integration** - the new sophisticated duel systems aren't yet connected to the tick-based match engine.

**Immediate Priority**: Connect `DuelResolver` to `MatchEngine._process_combat()` and bridge the agent systems. This single change will unlock the full potential of the combat simulation.

**Estimated Time to Full Combat Integration**: 2-3 developer days

---

*Report generated by Agent 007 - Elite Games Developer*  
*"Great games are built on solid code, but code exists to serve gameplay."*
