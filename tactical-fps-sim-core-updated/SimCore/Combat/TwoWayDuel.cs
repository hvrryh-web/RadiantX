using SimCore.Defs;
using SimCore.Math;

namespace SimCore.Combat;

public sealed record TwoWayDuelResult(
    TeamSide Winner,
    float WinnerTtk,
    float LoserTtk,
    bool Simultaneous,
    DuelResult AttackToDefend,
    DuelResult DefendToAttack
);

public static class TwoWayDuel
{
    // Resolves "both shoot each other" by running the engine in both directions and comparing TTK.
    // This is an approximation; you can later upgrade to a true simultaneous timeline.
    public static TwoWayDuelResult Resolve(
        IDuelEngine engine,
        DeterministicRng rng,
        DuelInput attackToDefend,
        DuelInput defendToAttack)
    {
        var rngA = new DeterministicRng(DeterministicRng.HashSeed("A2D", rng.NextU64()));
        var rngD = new DeterministicRng(DeterministicRng.HashSeed("D2A", rng.NextU64()));

        var a2d = engine.Resolve(rngA, attackToDefend);
        var d2a = engine.Resolve(rngD, defendToAttack);

        float aTtk = a2d.TargetKilled ? a2d.TimeToKill : float.PositiveInfinity;
        float dTtk = d2a.TargetKilled ? d2a.TimeToKill : float.PositiveInfinity;

        if (float.IsInfinity(aTtk) && float.IsInfinity(dTtk))
        {
            // Nobody kills within MaxTime; call it a "Defend holds" tie-breaker (tune as desired).
            return new TwoWayDuelResult(TeamSide.Defend, dTtk, aTtk, false, a2d, d2a);
        }

        if (System.MathF.Abs(aTtk - dTtk) < 0.03f) // simultaneous window
        {
            return new TwoWayDuelResult(TeamSide.Attack, aTtk, dTtk, true, a2d, d2a);
        }

        return (aTtk < dTtk)
            ? new TwoWayDuelResult(TeamSide.Attack, aTtk, dTtk, false, a2d, d2a)
            : new TwoWayDuelResult(TeamSide.Defend, dTtk, aTtk, false, a2d, d2a);
    }
}
