using SimCore.Defs;
using SimCore.Math;

namespace SimCore.Combat;

public sealed record DuelInput(
    AgentRuntime Shooter,
    AgentRuntime Target,
    float Distance,
    float Exposure,       // 0..1 fraction visible/hittable
    float ShooterSpeed,
    float TargetSpeed,
    bool ShooterCrouched,
    bool TargetCrouched,
    float MaxTime = 3.5f  // cap for sims
);

public sealed record DuelResult(
    bool TargetKilled,
    float TimeToKill,
    int ShotsFired,
    int Hits,
    float WinProbHint = 0 // for multi-way resolution if you extend
);

public interface IDuelEngine
{
    DuelResult Resolve(DeterministicRng rng, DuelInput input);
}

public sealed class AgentRuntime
{
    public required TraitBlock Traits { get; init; }
    public required WeaponDef Weapon { get; init; }
    public float Hp;
    public float Armor;
    public float Stress;
    public float ReactionTimer;

    public float ReactionDelay(float extraPenalty = 0f)
    {
        float baseRt = Lerp(0.18f, 0.45f, 1f - Traits.Reaction);
        float stressPenalty = 0.15f * Stress * (1f - Traits.Composure);
        return baseRt + stressPenalty + extraPenalty;
    }

    private static float Lerp(float a, float b, float t) => a + (b - a) * System.Math.Clamp(t, 0f, 1f);
}
