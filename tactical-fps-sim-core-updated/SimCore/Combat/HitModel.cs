using SimCore.Defs;
using SimCore.Math;

namespace SimCore.Combat;

public static class HitModel
{
    public static float ComputeSigma(WeaponDef w, float speed, bool crouched, float recoil, float stress, TraitBlock traits)
    {
        float sigma = w.Spread.BaseSigma;
        sigma += speed * w.Spread.MoveSigmaAdd;
        sigma += recoil * 0.0035f; // recoil->sigma factor (tune)
        if (crouched) sigma *= w.Spread.CrouchMult;

        // Skill & composure
        sigma *= (1.15f - 0.65f * traits.Aim);
        sigma *= (1.0f + 0.75f * stress * (1f - traits.Composure));

        // First shot bonus if low recoil
        if (recoil < 0.05f) sigma += w.Spread.FirstShotBonus;

        return System.MathF.Max(0.0005f, sigma);
    }

    public static float RangeMult(WeaponDef w, float dist) => w.Damage.RangeMultiplier.Evaluate(dist);

    public static float ZoneMult(WeaponDef w, HitZone zone) => zone switch
    {
        HitZone.Head => w.Damage.HeadMult,
        HitZone.Legs => w.Damage.LegMult,
        _ => 1f
    };
}

public enum HitZone { Head, Torso, Legs }
