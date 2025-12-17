namespace SimCore.Combat;

public static class Damage
{
    public static void Apply(ref float hp, ref float armor, float raw)
    {
        // Simple armor model (tunable):
        // armor absorbs 35% until depleted.
        float mit = armor > 0 ? 0.35f : 0f;
        float toHp = raw * (1f - mit);
        float toArmor = raw * mit;

        hp -= toHp;
        armor = System.MathF.Max(0, armor - toArmor);
    }
}
