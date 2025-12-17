using SimCore.Defs;
using SimCore.Math;
using SimCore.Combat;

namespace SimCore.Sim;

// Minimal snippet you can call from any console app to sanity-check duel engines.
public static class QuickStartExample
{
    public static void Run(string defsFolder)
    {
        var db = new DefDatabase();
        db.LoadFromFolder(defsFolder);

        var shooterDef = db.Agents["agent.sample.entry"];
        var targetDef  = db.Agents["agent.sample.anchor"];

        var shooter = new AgentRuntime
        {
            Traits = shooterDef.Traits,
            Weapon = db.Weapons["weapon.rifle.ak_like"],
            Hp = shooterDef.BaseHp,
            Armor = shooterDef.BaseArmor,
            Stress = 0.10f,
            ReactionTimer = 0f
        };

        var target = new AgentRuntime
        {
            Traits = targetDef.Traits,
            Weapon = db.Weapons["weapon.rifle.m4_like"],
            Hp = targetDef.BaseHp,
            Armor = targetDef.BaseArmor,
            Stress = 0.05f,
            ReactionTimer = 0f
        };

        var rng = new DeterministicRng(DeterministicRng.HashSeed("match", 12345));

        var input = new DuelInput(
            Shooter: shooter,
            Target: target,
            Distance: 22f,
            Exposure: 0.75f,
            ShooterSpeed: 1.2f,
            TargetSpeed: 0.4f,
            ShooterCrouched: false,
            TargetCrouched: true
        );

        var ttk = new TtkDuelEngine { Samples = 128 };
        var ttkRes = ttk.Resolve(rng, input);

        Console.WriteLine($"TTK: killed={ttkRes.TargetKilled} winProb~{ttkRes.WinProbHint:0.00} meanTTK={ttkRes.TimeToKill:0.00}s shots~{ttkRes.ShotsFired} hits~{ttkRes.Hits}");
    }
}
