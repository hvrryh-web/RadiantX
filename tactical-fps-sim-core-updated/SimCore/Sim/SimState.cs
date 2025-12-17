using SimCore.Defs;
using SimCore.Combat;

namespace SimCore.Sim;

public sealed class AgentState
{
    public int EntityId { get; init; }
    public string AgentId { get; init; } = "";
    public TeamSide Side { get; init; } = TeamSide.Attack;

    // Cached from AgentDef for buy-phase/autobuy convenience.
    public string[] LoadoutWeaponIds { get; init; } = Array.Empty<string>();
    public string[] LoadoutUtilityIds { get; init; } = Array.Empty<string>();

    public float MaxArmor;

    public Dictionary<string, UtilityState> Utilities { get; } = new();

    // Economy
    public int Credits;

    public Vec2 Pos;
    public Vec2 Vel;
    public float FacingRad;
    public float Hp;
    public float Armor;
    public float MaxHp;
    public float Stress;
    public float ReactionTimer;
    public WeaponState Weapon = new();
    public StatusState Status = new();
}

public sealed class UtilityState
{
    public string UtilityId = "";
    public int Charges;
    public float CooldownTimer;
}

public sealed class WeaponState
{
    public string WeaponId = "";
    public int AmmoInMag;
    public float FireCooldown;
    public float ReloadTimer;
    public float Recoil;
}

public sealed class SimState
{
    public float Time;
    public readonly List<AgentState> Agents = new();
}