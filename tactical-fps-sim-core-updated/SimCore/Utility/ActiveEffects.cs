using SimCore.Defs;

namespace SimCore.Utility;

public sealed class ActiveEffect
{
    public required string SourceUtilityId { get; init; }
    public required EffectSpec Spec { get; init; }
    public required Vec2 Center { get; init; }
    public float Remaining { get; set; }

    // One-shot effects (explosion/flash/concuss/reveal/suppress) are applied once per agent.
    public HashSet<int> AppliedToEntities { get; } = new();
}

public sealed class ActiveEffects
{
    public readonly List<ActiveEffect> Effects = new();

    public void Add(string utilId, EffectSpec spec, Vec2 center)
    {
        // Ensure at least one tick for instantaneous effects (Duration == 0).
        float dur = spec.Duration <= 0 ? 0.05f : spec.Duration;

        Effects.Add(new ActiveEffect
        {
            SourceUtilityId = utilId,
            Spec = spec,
            Center = center,
            Remaining = dur
        });
    }

    public void Tick(float dt)
    {
        for (int i = Effects.Count - 1; i >= 0; i--)
        {
            Effects[i].Remaining -= dt;
            if (Effects[i].Remaining <= 0) Effects.RemoveAt(i);
        }
    }
}
