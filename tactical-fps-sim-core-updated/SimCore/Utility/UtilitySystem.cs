using SimCore.Defs;
using SimCore.Geometry;
using SimCore.Combat;
using SimCore.Sim;

namespace SimCore.Utility;

public sealed class UtilitySystem
{
    private readonly DefDatabase _db;
    private readonly SmokeField _smoke;
    private readonly ActiveEffects _active;

    public UtilitySystem(DefDatabase db, SmokeField smoke, ActiveEffects active)
    {
        _db = db;
        _smoke = smoke;
        _active = active;
    }

    public void CastUtility(string utilityId, Vec2 center)
    {
        if (!_db.Utilities.TryGetValue(utilityId, out var util))
            throw new InvalidOperationException($"Unknown utility {utilityId}");

        foreach (var eff in util.Effects)
        {
            switch (eff.Kind)
            {
                case EffectKind.Smoke:
                    _smoke.Smokes.Add(new SmokeVolume
                    {
                        Center = center,
                        Radius = eff.Radius,
                        Falloff = eff.Falloff,
                        Remaining = eff.Duration
                    });
                    break;

                default:
                    _active.Add(util.Id, eff, center);
                    break;
            }
        }
    }

    public void ApplyEffectsToAgent(AgentState agent, MapRuntime map, float dt)
    {
        foreach (var e in _active.Effects)
        {
            float dx = agent.Pos.X - e.Center.X;
            float dy = agent.Pos.Y - e.Center.Y;
            float d = System.MathF.Sqrt(dx * dx + dy * dy);
            if (d > e.Spec.Radius) continue;

            if (e.Spec.RequiresLOS)
            {
                if (!Raycast2D.HasLineOfSight(map.Walls, agent.Pos.X, agent.Pos.Y, e.Center.X, e.Center.Y))
                    continue;
            }

            if (e.Spec.RequiresFacing)
            {
                // Facing check: agent must be looking roughly toward the effect center (flash cone).
                float vx = e.Center.X - agent.Pos.X;
                float vy = e.Center.Y - agent.Pos.Y;
                float vLen = System.MathF.Sqrt(vx * vx + vy * vy);
                if (vLen > 1e-4f)
                {
                    vx /= vLen; vy /= vLen;
                    float fx = System.MathF.Cos(agent.FacingRad);
                    float fy = System.MathF.Sin(agent.FacingRad);
                    float dot = fx * vx + fy * vy;
                    float halfAngleRad = (e.Spec.FacingAngleDeg * 0.5f) * (System.MathF.PI / 180f);
                    float cosThresh = System.MathF.Cos(halfAngleRad);
                    if (dot < cosThresh) continue;
                }
            }

            float factor = 1f;
            if (e.Spec.Falloff > 0f)
                factor = System.Math.Clamp(1f - (d / e.Spec.Radius) * e.Spec.Falloff, 0f, 1f);

            // Apply once-per-agent for instantaneous/status effects
            bool firstForAgent = e.AppliedToEntities.Add(agent.EntityId);

            switch (e.Spec.Kind)
            {
                case EffectKind.Explosion:
                    if (firstForAgent)
                    {
                        float dmg = e.Spec.DpsOrValue * factor;
                        Damage.Apply(ref agent.Hp, ref agent.Armor, dmg);
                        agent.Stress = System.MathF.Min(1f, agent.Stress + 0.25f * factor);
                    }
                    break;

                case EffectKind.FlashBlind:
                    if (firstForAgent)
                        agent.Status.FlashTimer = System.MathF.Max(agent.Status.FlashTimer, e.Spec.Duration);
                    break;

                case EffectKind.Concuss:
                    if (firstForAgent)
                        agent.Status.ConcussTimer = System.MathF.Max(agent.Status.ConcussTimer, e.Spec.Duration);
                    break;

                case EffectKind.Reveal:
                    if (firstForAgent)
                        agent.Status.RevealTimer = System.MathF.Max(agent.Status.RevealTimer, e.Spec.Duration);
                    break;

                case EffectKind.Suppress:
                    if (firstForAgent)
                        agent.Status.SuppressTimer = System.MathF.Max(agent.Status.SuppressTimer, e.Spec.Duration);
                    break;

                case EffectKind.Burn:
                    Damage.Apply(ref agent.Hp, ref agent.Armor, e.Spec.DpsOrValue * factor * dt);
                    agent.Status.BurnTimer = System.MathF.Max(agent.Status.BurnTimer, 0.15f);
                    agent.Stress = System.MathF.Min(1f, agent.Stress + 0.03f * dt);
                    break;

                case EffectKind.Heal:
                    agent.Hp = System.MathF.Min(agent.MaxHp, agent.Hp + e.Spec.DpsOrValue * factor * dt);
                    break;

                case EffectKind.Slow:
                    // Slow is treated as a status flag; movement system should read Status.SlowTimer.
                    agent.Status.SlowTimer = System.MathF.Max(agent.Status.SlowTimer, dt + 0.05f);
                    break;

                // The following are intentionally stubs in this combat package:
                // - Wall: should spawn a destructible nav-blocker instance.
                // - Trap: should spawn an armed trigger object that later creates status/damage effects.
                // - DecoySound: should generate periodic sound events for perception.
                case EffectKind.Wall:
                case EffectKind.Trap:
                case EffectKind.DecoySound:
                case EffectKind.Shield:
                case EffectKind.Knockback:
                default:
                    break;
            }
        }

        agent.Status.Tick(dt);
    }
}
