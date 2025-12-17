using SimCore.Defs;
using SimCore.Geometry;
using SimCore.Utility;
using SimCore.Combat;
using SimCore.Math;

namespace SimCore.Sim;

public sealed class Simulator
{
    private readonly MatchConfig _cfg;
    private readonly DefDatabase _db;
    private readonly MapRuntime _map;
    private readonly SmokeField _smoke = new();
    private readonly ActiveEffects _active = new();
    private readonly UtilitySystem _utils;
    private readonly EventQueue _events = new();

    public Simulator(MatchConfig cfg, DefDatabase db)
    {
        _cfg = cfg;
        _db = db;
        _map = new MapRuntime(db.Maps[cfg.MapId]);
        _utils = new UtilitySystem(db, _smoke, _active);
    }

    public void EnqueueUtilityCast(float time, int casterId, string utilityId, Vec2 target)
        => _events.Enqueue(new UtilityCastEvent(time, casterId, utilityId, target));

    public void Tick(SimState state)
    {
        float dt = 1f / _cfg.TickRate;
        state.Time += dt;

        _smoke.Tick(dt);
        _active.Tick(dt);

        // Resolve due events
        while (_events.TryPeek(out var ev) && ev is not null && ev.Time <= state.Time)
        {
            _events.TryDequeue(out var deq);
            if (deq is UtilityCastEvent u)
            {
                _utils.CastUtility(u.UtilityId, u.TargetPos);
            }
        }

        // Apply continuous effects (burn/heal/slow)
        foreach (var a in state.Agents)
        {
            if (a.Hp <= 0) continue;
            _utils.ApplyEffectsToAgent(a, _map, dt);
            a.ReactionTimer = System.MathF.Max(0, a.ReactionTimer - dt);
            a.Weapon.FireCooldown = System.MathF.Max(0, a.Weapon.FireCooldown - dt);
        }
    }

    public IDuelEngine CreateRaycastDuelEngine() => new RaycastDuelEngine(_map, _smoke);
    public IDuelEngine CreateTtkDuelEngine() => new TtkDuelEngine();
}
