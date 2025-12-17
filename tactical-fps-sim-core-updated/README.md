# Tactical FPS Sim Core (Combat Logic Package)

This repo is a **ready-to-paste** combat simulation core for a tactical FPS esport org coach/manager sim.

What you get:
- Concrete **C# data schema** + runtime state for Agents/Weapons/Utility/Maps.
- Mirrored **TypeScript types** for UI tools/viewers.
- Two duel engines:
  1) **Raycast (hitscan)** for on-camera, geometry-accurate fights.
  2) **Fast TTK Monte Carlo** for off-camera/background fights.
- A complete utility catalogue for:
  - **CS-like grenades** (smoke/flash/HE/molotov/decoy)
  - **VAL-like abilities** (templates: smokes/flashes/mollies/reveal/suppress/walls/traps/mobility/heal)

## Quick start (Windows)
1. Install .NET 8 SDK
2. From `SimCore/`:
   ```powershell
   dotnet build
   ```

## Defs (JSON)
- All tunables live in `/Defs/*.json`.
- Use `tools/validate_defs.ps1` to sanity-check IDs & references.

## Notes on tuning
The provided numbers are **starter defaults**. They are intentionally editable and should be tuned to your specific game.


## Console runner

Build and run from the repo root:

```powershell
dotnet build .\TacticalFpsSim.sln

# CS-like economy + grenades (TTK duel engine)
dotnet run --project .\SimConsoleRunner -- --defs .\Defs --rules rules.cs --engine ttk --rounds 5 --seed 123

# VAL-like economy + signature refill (raycast duel engine)
dotnet run --project .\SimConsoleRunner -- --defs .\Defs --rules rules.val --engine raycast --rounds 5 --seed 123 --atk agent.val.duelist --def agent.val.sentinel
```

Notes:
- Round-start logic resets HP/armor, refills signature abilities, and runs an auto-buy to top up charges.
- The buy algorithm is intentionally simple; replace it with your manager AI/coach heuristics later.
