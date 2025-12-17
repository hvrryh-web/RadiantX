# Contributing to RadiantX

Thank you for your interest in contributing to RadiantX!

## Project Philosophy

RadiantX is designed as an **offline, Windows-focused, deterministic tactical FPS simulation tool**. All contributions should align with these core principles:

1. **Determinism First**: All simulation logic must be deterministic
2. **Offline Capable**: No required internet connectivity
3. **Windows Primary**: Optimize for Windows, though cross-platform is welcome
4. **Simulation Heavy**: Focus on tactical depth, not graphics

## How to Contribute

### Reporting Issues

- Use GitHub Issues
- Include Godot version
- Describe expected vs actual behavior
- Include steps to reproduce
- Attach replay files if relevant

### Suggesting Features

Features should enhance tactical simulation:
- New tactical utilities (grenades, equipment)
- Improved agent AI
- Analysis tools
- Map editor
- Performance improvements

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Follow coding standards**
   - Use GDScript for all game logic
   - Follow Godot naming conventions
   - Add comments for complex logic
   - Keep functions small and focused

4. **Maintain determinism**
   - Use seeded RNG only
   - Avoid floating point accumulation
   - Test with same seed multiple times

5. **Update documentation**
   - Add docs for new features
   - Update existing docs if behavior changes
   - Include code examples

6. **Test your changes**
   - Run determinism tests
   - Test with different seeds
   - Verify replays work correctly

7. **Submit a pull request**
   - Describe what changed and why
   - Reference any related issues
   - Include before/after behavior

## Coding Standards

### GDScript Style

```gdscript
# Use snake_case for variables and functions
var agent_health: float = 100.0

func calculate_damage(attacker: Agent, target: Agent) -> float:
	# Use tabs for indentation
	var base_damage = 25.0
	return base_damage

# Use PascalCase for classes
class_name MatchEngine

# Document public functions
func start_match(seed: int):
	"""Start a new match with given seed"""
	pass
```

### File Organization

```
scripts/        # Core game logic
scenes/         # Godot scene files
maps/           # Map JSON files
docs/           # Documentation
tests/          # Test scripts
assets/         # Images, sounds (future)
```

## Testing

### Determinism Tests

Always run determinism tests before submitting:

```bash
# In Godot, run tests/test_determinism.tscn
# All tests should pass
```

### Manual Testing

1. Run a full match
2. Save replay
3. Load replay and verify it matches
4. Test with different seeds
5. Verify UI updates correctly

## Documentation

Update relevant docs:
- `docs/architecture.md` - System design changes
- `docs/map_format.md` - Map format changes
- `docs/agents.md` - Agent behavior changes
- `docs/replay.md` - Replay system changes
- `README.md` - User-facing changes

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Open a GitHub Issue with the "question" label.

## Recognition

Contributors will be acknowledged in release notes and the README.

Thank you for helping make RadiantX better!
