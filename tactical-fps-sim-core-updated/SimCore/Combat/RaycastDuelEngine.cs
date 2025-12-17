using SimCore.Defs;
using SimCore.Geometry;
using SimCore.Math;

namespace SimCore.Combat;

// Geometry-respecting duel: samples shot angle error and raycasts against walls.
// Use this for "on-camera" duels where peeks and cover matter.
public sealed class RaycastDuelEngine : IDuelEngine
{
    private readonly MapRuntime _map;
    private readonly SmokeField _smoke;

    public RaycastDuelEngine(MapRuntime map, SmokeField smoke)
    {
        _map = map;
        _smoke = smoke;
    }

    public DuelResult Resolve(DeterministicRng rng, DuelInput input)
    {
        var w = input.Shooter.Weapon;
        float shotInterval = 60f / w.RoundsPerMinute;

        float hp = input.Target.Hp;
        float armor = input.Target.Armor;

        float t = input.Shooter.ReactionDelay(extraPenalty: input.Shooter.ReactionTimer);
        float recoil = 0f;

        int shots = 0;
        int hits = 0;

        // We need positions to raycast; in a full sim these come from AgentState.
        // For a pure duel unit-test, approximate shooter at origin and target on +X.
        float sx = 0f, sy = 0f;
        float tx = input.Distance, ty = 0f;

        while (hp > 0 && t < input.MaxTime)
        {
            shots++;

            // Smoke visibility gating
            float opacity = _smoke.IntegrateOpacity(new Vec2(sx, sy), new Vec2(tx, ty), samples: 8);
            float smokeMult = 1f - 0.85f * opacity; // heavy smoke => much harder to land
            float sigma = HitModel.ComputeSigma(w, input.ShooterSpeed, input.ShooterCrouched, recoil, input.Shooter.Stress, input.Shooter.Traits);
            sigma /= System.MathF.Max(0.2f, smokeMult);

            // Sample shot angle in radians around direction-to-target.
            float angErr = rng.NextNormal(0f, sigma);
            float dx = System.MathF.Cos(angErr);
            float dy = System.MathF.Sin(angErr);

            // Build a long ray segment
            float rayLen = input.Distance + 20f;
            float ex = sx + dx * rayLen;
            float ey = sy + dy * rayLen;

            // If wall hit occurs before reaching target distance, miss.
            float firstWallT = Raycast2D.FirstHitT(_map.Walls, sx, sy, ex, ey);

            // Target hit test: treat target as circle at (tx,ty) with radius scaled by exposure.
            float r = 0.30f * System.Math.Clamp(input.Exposure, 0f, 1f);
            bool hitTarget = IntersectCircle(sx, sy, ex, ey, tx, ty, r, out float tHit);

            if (hitTarget)
            {
                // Compare segment parameter: wall blocks if earlier.
                if (tHit < firstWallT)
                {
                    hits++;
                    var zone = ChooseZone(rng, input, sigma);
                    float dmg = w.Damage.BaseDamage * HitModel.RangeMult(w, input.Distance) * HitModel.ZoneMult(w, zone);
                    Damage.Apply(ref hp, ref armor, dmg);
                }
            }

            // recoil integration
            float recGain = w.Recoil.RecoilPerShot * (1.15f - 0.65f * input.Shooter.Traits.RecoilControl);
            recoil = System.MathF.Min(w.Recoil.MaxRecoil, recoil + recGain);
            recoil = System.MathF.Max(0f, recoil - w.Recoil.RecoveryPerSec * shotInterval);

            t += shotInterval;
        }

        return new DuelResult(hp <= 0, hp <= 0 ? t : float.PositiveInfinity, shots, hits);
    }

    private static HitZone ChooseZone(DeterministicRng rng, DuelInput input, float sigma)
    {
        // Similar headShare logic as TTK engine, but can incorporate exposure/stance.
        float headShare = 0.10f + 0.30f * input.Shooter.Traits.Aim;
        if (input.TargetCrouched) headShare *= 0.85f;
        headShare *= System.Math.Clamp(0.010f / System.MathF.Max(0.0005f, sigma), 0.5f, 1.1f);
        headShare = System.Math.Clamp(headShare, 0.08f, 0.50f);
        return rng.NextFloat01() < headShare ? HitZone.Head : HitZone.Torso;
    }

    private static bool IntersectCircle(
        float ax, float ay, float bx, float by,
        float cx, float cy, float r,
        out float t)
    {
        // Closest point on segment to circle center
        float dx = bx - ax, dy = by - ay;
        float fx = ax - cx, fy = ay - cy;

        float a = dx * dx + dy * dy;
        float b = 2f * (fx * dx + fy * dy);
        float c = (fx * fx + fy * fy) - r * r;

        float disc = b * b - 4f * a * c;
        if (disc < 0)
        {
            t = float.PositiveInfinity;
            return false;
        }
        disc = System.MathF.Sqrt(disc);

        float t1 = (-b - disc) / (2f * a);
        float t2 = (-b + disc) / (2f * a);

        t = (t1 >= 0f && t1 <= 1f) ? t1 : ((t2 >= 0f && t2 <= 1f) ? t2 : float.PositiveInfinity);
        return !float.IsInfinity(t);
    }
}
