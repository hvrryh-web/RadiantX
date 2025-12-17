using SimCore.Defs;
using SimCore.Combat;
using SimCore.Math;
using SimCore.Sim;

namespace SimCore.Economy;

/// <summary>
/// A lightweight "match loop" for console demos and unit testing.
/// This is intentionally not a full tactical round simulator; it
/// exercises:
/// - economy (credits, buy)
/// - round-start refills
/// - duel resolution (TTK or raycast)
/// - round rewards and kill rewards
/// </summary>
public sealed class RoundRunner
{
    private readonly MatchConfig _cfg;
    private readonly DefDatabase _db;
    private readonly RulesetDef _rules;

    public RoundRunner(MatchConfig cfg, DefDatabase db)
    {
        _cfg = cfg;
        _db = db;
        _rules = db.Rulesets[cfg.RulesetId];
    }

    public RoundSummary RunDuelRound(
        int roundIndex,
        string attackerAgentId,
        string defenderAgentId,
        string engineMode,
        float distance = 18f,
        float exposure = 0.8f)
    {
        var atkDef = _db.Agents[attackerAgentId];
        var defDef = _db.Agents[defenderAgentId];

        var atk = new AgentState { EntityId = 1, AgentId = attackerAgentId };
        var def = new AgentState { EntityId = 2, AgentId = defenderAgentId };

        EconomySystem.InitializeAgentState(atk, atkDef, _rules, _db);
        EconomySystem.InitializeAgentState(def, defDef, _rules, _db);

        EconomySystem.RoundStart(atk, atkDef, _rules, _db);
        EconomySystem.RoundStart(def, defDef, _rules, _db);

        EquipBestAffordableWeapon(atk, atkDef);
        EquipBestAffordableWeapon(def, defDef);

        var sim = new Simulator(_cfg, _db);
        var duelEngine = SelectEngine(sim, engineMode);

        var rng = new DeterministicRng(DeterministicRng.HashSeed(_cfg.Seed, roundIndex));

        var atkRuntime = ToRuntime(atk, atkDef);
        var defRuntime = ToRuntime(def, defDef);

        var input = new DuelInput(
            Shooter: atkRuntime,
            Target: defRuntime,
            Distance: distance,
            Exposure: exposure,
            ShooterSpeed: 0.0f,
            TargetSpeed: 0.0f,
            ShooterCrouched: false,
            TargetCrouched: false,
            MaxTime: 4.0f
        );

        var res = duelEngine.Resolve(rng, input);
        bool attackersWon = res.TargetKilled;

        if (attackersWon)
        {
            EconomySystem.AwardKillCredits(atk, _rules);
            EconomySystem.ApplyRoundEndRewards(new[] { atk }, wonRound: true, _rules);
            EconomySystem.ApplyRoundEndRewards(new[] { def }, wonRound: false, _rules);
        }
        else
        {
            EconomySystem.ApplyRoundEndRewards(new[] { atk }, wonRound: false, _rules);
            EconomySystem.ApplyRoundEndRewards(new[] { def }, wonRound: true, _rules);
        }

        return new RoundSummary
        {
            RoundIndex = roundIndex,
            EngineMode = engineMode,
            Distance = distance,
            Exposure = exposure,
            Attacker = SummarizeAgent(atk, atkDef),
            Defender = SummarizeAgent(def, defDef),
            AttackerKilledDefender = attackersWon,
            TimeToKill = res.TimeToKill,
            ShotsFired = res.ShotsFired,
            Hits = res.Hits
        };
    }

    private IDuelEngine SelectEngine(Simulator sim, string engineMode)
    {
        return engineMode.ToLowerInvariant() switch
        {
            "raycast" => sim.CreateRaycastDuelEngine(),
            "ttk" => sim.CreateTtkDuelEngine(),
            _ => sim.CreateTtkDuelEngine()
        };
    }

    private void EquipBestAffordableWeapon(AgentState agent, AgentDef def)
    {
        foreach (var wid in def.LoadoutWeaponIds)
        {
            if (!_db.Weapons.TryGetValue(wid, out var w)) continue;
            if (w.CreditCost <= 0 || agent.Credits >= w.CreditCost)
            {
                if (w.CreditCost > 0) agent.Credits -= w.CreditCost;
                agent.Weapon.WeaponId = wid;
                agent.Weapon.AmmoInMag = w.MagazineSize;
                return;
            }
        }

        var fallback = _db.Weapons.Values.OrderBy(w => w.CreditCost).First();
        agent.Weapon.WeaponId = fallback.Id;
        agent.Weapon.AmmoInMag = fallback.MagazineSize;
    }

    private AgentRuntime ToRuntime(AgentState s, AgentDef def)
    {
        var w = _db.Weapons[s.Weapon.WeaponId];
        return new AgentRuntime
        {
            Traits = def.Traits,
            Weapon = w,
            Hp = s.Hp,
            Armor = s.Armor,
            Stress = s.Stress,
            ReactionTimer = s.ReactionTimer
        };
    }

    private static AgentSummary SummarizeAgent(AgentState s, AgentDef def)
    {
        return new AgentSummary
        {
            AgentId = def.Id,
            Name = def.DisplayName,
            WeaponId = s.Weapon.WeaponId,
            Credits = s.Credits,
            Utilities = s.Utilities.Values
                .OrderBy(u => u.UtilityId)
                .Select(u => (u.UtilityId, u.Charges))
                .ToArray()
        };
    }
}

public sealed class RoundSummary
{
    public int RoundIndex { get; init; }
    public string EngineMode { get; init; } = "ttk";
    public float Distance { get; init; }
    public float Exposure { get; init; }
    public AgentSummary Attacker { get; init; } = new();
    public AgentSummary Defender { get; init; } = new();
    public bool AttackerKilledDefender { get; init; }
    public float TimeToKill { get; init; }
    public int ShotsFired { get; init; }
    public int Hits { get; init; }
}

public sealed class AgentSummary
{
    public string AgentId { get; init; } = "";
    public string Name { get; init; } = "";
    public string WeaponId { get; init; } = "";
    public int Credits { get; init; }
    public (string UtilityId, int Charges)[] Utilities { get; init; } = Array.Empty<(string, int)>();
}
