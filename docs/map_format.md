# Map Format Specification

## Overview

Maps are defined in JSON format with zones and occluders for tactical gameplay.

## Format

```json
{
  "name": "Map Name",
  "width": 100,
  "height": 100,
  "zones": [ ... ],
  "occluders": [ ... ]
}
```

## Fields

### Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Display name of the map |
| width | number | Yes | Map width in units |
| height | number | Yes | Map height in units |
| zones | array | Yes | Array of zone objects |
| occluders | array | Yes | Array of occluder objects |

### Zone Object

Zones define special areas like spawn points and objectives.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Unique identifier (e.g., "spawn_a", "objective_1") |
| x | number | Yes | X position of top-left corner |
| y | number | Yes | Y position of top-left corner |
| width | number | Yes | Zone width |
| height | number | Yes | Zone height |

**Reserved IDs:**
- `spawn_a` - Team A spawn point
- `spawn_b` - Team B spawn point

### Occluder Object

Occluders block line of sight and bullets.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| x | number | Yes | X position of top-left corner |
| y | number | Yes | Y position of top-left corner |
| width | number | Yes | Occluder width |
| height | number | Yes | Occluder height |

## Example Map

```json
{
  "name": "Training Ground",
  "width": 100,
  "height": 100,
  "zones": [
    {
      "id": "spawn_a",
      "x": 10,
      "y": 10,
      "width": 15,
      "height": 15
    },
    {
      "id": "spawn_b",
      "x": 75,
      "y": 75,
      "width": 15,
      "height": 15
    },
    {
      "id": "objective_a",
      "x": 40,
      "y": 40,
      "width": 10,
      "height": 10
    }
  ],
  "occluders": [
    {
      "x": 45,
      "y": 20,
      "width": 10,
      "height": 30
    },
    {
      "x": 20,
      "y": 45,
      "width": 30,
      "height": 10
    }
  ]
}
```

## Design Guidelines

### Map Size
- Recommended: 100x100 to 200x200 units
- Larger maps require more computation for LOS checks

### Spawn Zones
- Must include `spawn_a` and `spawn_b`
- Place far apart to avoid early contact
- Size should accommodate 5 agents (15x15 recommended)

### Occluders
- Use for walls, buildings, large obstacles
- Create tactical opportunities (cover, flanking)
- Avoid completely blocking critical paths
- Consider sight lines and engagement ranges

### Zone Placement
- Objectives should be contestable from multiple angles
- Create natural choke points
- Allow for tactical utility usage

## Validation

Maps are validated when loaded:
- All required fields must be present
- Numeric values must be positive
- Spawn zones must exist
- Width/height define playable area

## Loading

Maps are loaded from the `maps/` directory:

```gdscript
var map = MapData.load_from_json("res://maps/training_ground.json")
```
