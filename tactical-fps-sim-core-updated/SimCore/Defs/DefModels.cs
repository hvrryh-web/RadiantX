using System.Text.Json.Serialization;

namespace SimCore.Defs;

public readonly record struct Vec2(float X, float Y);

public sealed class MatchConfig
{
    public int TickRate { get; init; } = 20;
    public int Seed { get; init; } = 12345;
    public string RulesetId { get; init; } = "rules.cs";
    public string MapId { get; init; } = "map.sample.box";
}

public sealed class RulesetDef
{
    public string Id { get; init; } = "";
    public UtilityFamily UtilityFamily { get; init; }
    public int MaxGrenades { get; init; } = 4;
    public bool UsesAbilityEconomy { get; init; } = false;

    // --- Economy / round flow (sample defaults; tune per ruleset) ---
    public int RoundStartCredits { get; init; } = 800;
    public int MaxCredits { get; init; } = 9000;
    public int RoundWinCredits { get; init; } = 3000;
    public int RoundLossCredits { get; init; } = 1900;
    public int KillCredits { get; init; } = 200;

    // Loss-streak bonuses added to RoundLossCredits. Index 0 => first loss, etc.
    // Defaults are illustrative; tune to your ruleset (CS/VAL differ).
    public int[] LossStreakBonuses { get; init; } = new[] { 0, 500, 500, 500 };

    // Whether HP/armor is reset each round (typical tactical FPS behavior)
    public bool ResetHpEachRound { get; init; } = true;
    public bool ResetArmorEachRound { get; init; } = true;

    // VAL-like signature refill (applies when UtilityFamily == VAL_Ability)
    public bool RefillSignatureEachRound { get; init; } = true;
    public int DefaultSignatureRoundStartCharges { get; init; } = 1;
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum UtilityFamily { CS_Grenade, VAL_Ability }


[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TeamSide { Attack, Defend }

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum FireMode { Semi, Burst, Auto }

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum CastType { ThrowArc, FireProjectile, InstantAOE, PlaceMarker, Beam, Self }

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum EffectKind
{
    Smoke, FlashBlind, Concuss, Slow, Burn, Heal, Shield,
    Reveal, Suppress, Knockback, Wall, Trap, DecoySound,
    Explosion
}

public sealed class TraitBlock
{
    // 0..1 normalized
    public float Aim { get; init; }
    public float RecoilControl { get; init; }
    public float Reaction { get; init; }
    public float Movement { get; init; }
    public float GameSense { get; init; }
    public float Composure { get; init; }
    public float Teamwork { get; init; }
    public float Utility { get; init; }
    public float Discipline { get; init; }
    public float Aggression { get; init; }
}

public sealed class AgentDef
{
    public string Id { get; init; } = "";
    public string DisplayName { get; init; } = "";
    public float BaseHp { get; init; } = 100;
    public float BaseArmor { get; init; } = 0;
    public TraitBlock Traits { get; init; } = new();
    public string[] LoadoutWeaponIds { get; init; } = Array.Empty<string>();
    public string[] LoadoutUtilityIds { get; init; } = Array.Empty<string>();
}

public sealed class WeaponDef
{
    public string Id { get; init; } = "";
    public FireMode FireMode { get; init; }
    public int CreditCost { get; init; } = 0;
    public int MagazineSize { get; init; }
    public float RoundsPerMinute { get; init; }
    public float ReloadTime { get; init; }
    public DamageProfile Damage { get; init; } = new();
    public SpreadProfile Spread { get; init; } = new();
    public RecoilProfile Recoil { get; init; } = new();
    public PenetrationProfile Penetration { get; init; } = new();
}

public sealed class DamageProfile
{
    public float BaseDamage { get; init; }
    public float HeadMult { get; init; } = 4.0f;
    public float LegMult { get; init; } = 0.75f;
    public Curve RangeMultiplier { get; init; } = new();
}

public sealed class SpreadProfile
{
    public float BaseSigma { get; init; } // radians
    public float CrouchMult { get; init; } = 0.85f;
    public float MoveSigmaAdd { get; init; }
    public float JumpSigmaAdd { get; init; }
    public float FirstShotBonus { get; init; }
}

public sealed class RecoilProfile
{
    public float RecoilPerShot { get; init; }
    public float MaxRecoil { get; init; }
    public float RecoveryPerSec { get; init; }
}

public sealed class PenetrationProfile
{
    public bool CanPenetrate { get; init; }
    public float PenPower { get; init; }
    public float DamageLossPerUnit { get; init; }
}

public sealed class UtilityDef
{
    public string Id { get; init; } = "";
    public UtilityFamily Family { get; init; }
    public CastType CastType { get; init; }
    public float EquipTime { get; init; }
    public float CastTime { get; init; }
    public int MaxCharges { get; init; } = 1;
    public float Cooldown { get; init; } = 0;
    public int CreditCost { get; init; } = 0;

    // Round-start refill hooks (primarily for VAL-like abilities, but generic).
    // - If IsSignature == true and ruleset.RefillSignatureEachRound, charges are set to at least:
    //   max(RoundStartCharges, ruleset.DefaultSignatureRoundStartCharges).
    // - If IsSignature == false, charges are set to at least RoundStartCharges.
    public bool IsSignature { get; init; } = false;
    public int RoundStartCharges { get; init; } = 0;
    public ThrowBallistics? Throw { get; init; }
    public ProjectileDef? Projectile { get; init; }
    public EffectSpec[] Effects { get; init; } = Array.Empty<EffectSpec>();
}

public sealed class ThrowBallistics
{
    public float Speed { get; init; }
    public float Gravity { get; init; }
    public float FuseTime { get; init; }
    public bool DetonateOnRest { get; init; }
}

public sealed class ProjectileDef
{
    public float Speed { get; init; }
    public float Gravity { get; init; }
    public float MaxLife { get; init; }
    public bool Bounces { get; init; }
    public float BounceDamp { get; init; }
}

public sealed class EffectSpec
{
    public EffectKind Kind { get; init; }
    public float Duration { get; init; }
    public float Radius { get; init; }
    public float DpsOrValue { get; init; }
    public float Falloff { get; init; }
    public bool RequiresLOS { get; init; }
    public bool RequiresFacing { get; init; }
    public float FacingAngleDeg { get; init; }
}

public sealed class MapDef
{
    public string Id { get; init; } = "";
    public string Name { get; init; } = "";
    public WallSeg[] Walls { get; init; } = Array.Empty<WallSeg>();
}

public sealed class WallSeg
{
    public float Ax { get; init; }
    public float Ay { get; init; }
    public float Bx { get; init; }
    public float By { get; init; }
}