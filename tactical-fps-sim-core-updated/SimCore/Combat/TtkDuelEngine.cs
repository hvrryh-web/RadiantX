using SimCore.Defs;
using SimCore.Math;

namespace SimCore.Combat;

// Fast duel solver: no geometry. Shot-by-shot Monte Carlo with analytic p_hit.
public sealed class TtkDuelEngine : IDuelEngine
{
    public int Samples { get; init; } = 128;

    public DuelResult Resolve(DeterministicRng rng, DuelInput input)
    {
        int killCount = 0;
        float tSum = 0f;
        int shotsSum = 0;
        int hitsSum = 0;

        // Precompute
        var w = input.Shooter.Weapon;
        float shotInterval = 60f / w.RoundsPerMinute;
        float baseRadius = 0.30f; // target radius in world units (tune to your map scale)

        ulong baseSeed = rng.NextU64();

        for (int i = 0; i < Samples; i++)
        {
            var simRng = new DeterministicRng(DeterministicRng.HashSeed("ttk", baseSeed, i));
            float hp = input.Target.Hp;
            float armor = input.Target.Armor;
            float recoil = 0f;
            float t = input.Shooter.ReactionDelay(extraPenalty: input.Shooter.ReactionTimer);

            int shots = 0;
            int hits = 0;

            while (hp > 0 && t < input.MaxTime)
            {
                float sigma = HitModel.ComputeSigma(w, input.ShooterSpeed, input.ShooterCrouched, recoil, input.Shooter.Stress, input.Shooter.Traits);
                float rWorld = baseRadius * System.Math.Clamp(input.Exposure, 0f, 1f);
                float rAng = System.MathF.Atan2(rWorld, System.MathF.Max(0.1f, input.Distance));

                float pHit = 1f - System.MathF.Exp(-(rAng * rAng) / (2f * sigma * sigma));
                pHit = System.Math.Clamp(pHit, 0f, 1f);

                shots++;

                if (simRng.NextFloat01() < pHit)
                {
                    hits++;
                    float headShare = ComputeHeadShare(input, sigma);
                    var zone = simRng.NextFloat01() < headShare ? HitZone.Head : HitZone.Torso;

                    float dmg = w.Damage.BaseDamage * HitModel.RangeMult(w, input.Distance) * HitModel.ZoneMult(w, zone);
                    Damage.Apply(ref hp, ref armor, dmg);
                }

                // recoil integration
                float recGain = w.Recoil.RecoilPerShot * (1.15f - 0.65f * input.Shooter.Traits.RecoilControl);
                recoil = System.MathF.Min(w.Recoil.MaxRecoil, recoil + recGain);
                recoil = System.MathF.Max(0f, recoil - w.Recoil.RecoveryPerSec * shotInterval);

                t += shotInterval;
            }

            if (hp <= 0)
            {
                killCount++;
                tSum += t;
                shotsSum += shots;
                hitsSum += hits;
            }
        }

        if (killCount == 0)
        {
            return new DuelResult(false, float.PositiveInfinity, ShotsFired: 0, Hits: 0, WinProbHint: 0f);
        }

        float meanTtk = tSum / killCount;
        return new DuelResult(
            TargetKilled: true,
            TimeToKill: meanTtk,
            ShotsFired: shotsSum / killCount,
            Hits: hitsSum / killCount,
            WinProbHint: killCount / (float)Samples
        );
    }

    private static float ComputeHeadShare(DuelInput input, float sigma)
    {
        // Higher aim, lower sigma, closer distance => more headshare.
        float aim = input.Shooter.Traits.Aim;
        float distFactor = System.Math.Clamp(1f - (input.Distance / 45f), 0.1f, 1f);
        float sigmaFactor = System.Math.Clamp(0.012f / System.MathF.Max(0.0005f, sigma), 0.4f, 1.2f);
        float raw = 0.10f + 0.35f * aim * distFactor * sigmaFactor;
        return System.Math.Clamp(raw, 0.08f, 0.55f);
    }
}
