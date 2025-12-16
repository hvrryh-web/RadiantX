# Agent Behavior

## Overview

Agents are autonomous tactical units with partial observability, belief systems, and decision-making capabilities.

## Agent Properties

### Physical Attributes
- **Health**: 100 HP (max)
- **Move Speed**: 5 units/tick
- **Vision Range**: 50 units
- **Position**: 2D coordinates on map

### Teams
- **Team A**: Blue color
- **Team B**: Red color

## Partial Observability

Agents don't have perfect information about the match state.

### Belief System

Each agent maintains beliefs about other agents:

```gdscript
beliefs = {
  agent_id: {
    "position": Vector2,
    "health": float,
    "state": State,
    "confidence": float  # 0.0 to 1.0
  }
}
```

### Belief Updates

**When agent can see another:**
- Belief updated with accurate information
- Confidence set to 1.0
- Last seen tick recorded

**When agent cannot see another:**
- Confidence decays at 5% per tick
- Belief removed when confidence reaches 0
- Agent "forgets" unseen enemies

### Vision Rules

An agent can see another if:
1. Target is within vision range (50 units)
2. Agent is not flashed
3. No smoke blocks the line of sight
4. No map occluders block the line of sight

## Decision Making

Each tick, agents make decisions based on their beliefs.

### States

- **IDLE**: No action
- **MOVING**: Moving to target position
- **ATTACKING**: Engaging enemy
- **TAKING_COVER**: Seeking cover (future)

### Decision Algorithm

```
1. Update beliefs about all other agents
2. Filter beliefs by confidence (> 0.3)
3. Identify enemies (different team)
4. If enemies known:
   - Select random enemy target
   - Move towards enemy
   - Consider tactical utilities
5. If no enemies known:
   - Random exploration (10% chance)
   - Stay in position
```

### Tactical Utility Usage

**Smoke Grenades:**
- 5% chance per tick when attacking
- Deployed near agent's position
- Blocks vision for all agents
- Radius: 5 units

**Flashbangs:**
- 3% chance per tick when attacking
- Thrown at enemy position
- Affects agents within 20 units
- Duration scales with distance

## Combat

### Hit Chance Calculation

```
base_chance = 0.3 (30%)
distance_factor = 1.0 - (distance / 50.0)  # Max range
flash_factor = 0.1 if flashed else 1.0

final_chance = base_chance × distance_factor × flash_factor
```

### Damage
- **Base Damage**: 25 HP per hit
- **Shots per Second**: Varies by tick and hit chance
- **Time to Kill**: ~4 hits = 100 HP

### Line of Sight

Combat requires unobstructed line of sight:
- Blocked by map occluders
- Smoke does not block bullets (only vision)
- No friendly fire

## Communication

### Comm Delay
- Information has 2-tick delay (100ms)
- Simulates radio/voice communication lag
- Currently simplified in implementation

### Information Sharing
- Agents on same team can share beliefs
- Smoke/flash notifications propagate
- Future: explicit callout system

## Status Effects

### Flashed
- Duration: 10 ticks × (1 - distance/20)
- Effect: Vision disabled (cannot update beliefs)
- Combat penalty: 90% hit chance reduction

### In Smoke
- Effect: Vision blocked through smoke
- No movement penalty
- Must navigate around or through

## AI Behavior Patterns

Current implementation uses simple random decision-making. Future improvements:

### Planned Behaviors
- **Aggressive**: Push towards enemies
- **Defensive**: Hold positions
- **Support**: Use utilities strategically
- **Flanking**: Take alternate routes

### Learning
- Agents could learn optimal positions
- Coordinate team tactics
- Adapt to enemy strategies

## Determinism

Agent behavior is fully deterministic:
- All decisions use seeded RNG
- Same seed = same decisions
- Reproducible for testing and replay

## Performance

- Belief updates: O(n) per agent per tick
- Decision making: O(1) per agent per tick
- Vision checks: O(n × occluders) per agent per tick

For 10 agents at 20 TPS: ~200 decisions/second
