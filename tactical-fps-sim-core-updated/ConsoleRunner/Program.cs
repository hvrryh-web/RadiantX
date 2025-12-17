using SimCore.Defs;
using SimCore.Math;
using SimCore.Combat;
using SimCore.Sim;
using SimCore.Geometry;

static string GetArg(string[] args, string name, string def)
{
    var idx = Array.IndexOf(args, name);
    return (idx >= 0 && idx + 1 < args.Length) ? args[idx + 1] : def;
}

static int GetArgInt(string[] args, string name, int def)
{
    if (int.TryParse(GetArg(args, name, def.ToString()), out var v)) return v;
    return def;
}

static string GetArgLower(string[] args, string name, string def) => GetArg(args, name, def).Trim().ToLowerInvariant();

var defs = GetArg(args, "--defs", Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "Defs")));
var rulesetId = GetArg(args, "--rules", "rules.cs");
var mode = GetArgLower(args, "--mode", "ttk"); // ttk | raycast
var seed = (ulong)GetArgInt(args, "--seed", 12345);
var rounds = GetArgInt(args, "--rounds", 3);
var samples = GetArgInt(args, "--samples", 128);

Console.WriteLine($"Defs: {defs}");
Console.WriteLine($"Ruleset: {rulesetId}  Mode: {mode}  Seed: {seed}  Rounds: {rounds}");

var db = new DefDatabase();
db.LoadFromFolder(defs);

if (!db.Rulesets.TryGetValue(rulesetId, out var ruleset))
{
    Console.WriteLine($"ERROR: Missing ruleset {rulesetId}");
    return;
}

var match = new MatchState();

// Create two agents based on ruleset family.
AgentDef aDef, dDef;
if (ruleset.UtilityFamily == UtilityFamily.VAL_Ability)
{
    aDef = db.Agents["agent.val.sample.duelist"];
    dDef = db.Agents["agent.val.sample.controller"];
}
else
{
    aDef = db.Agents["agent.sample.entry"];
    dDef = db.Agents["agent.sample.anchor"];
}

var atk = BuildAgentState(entityId: 1, side: TeamSide.Attack, aDef);
var def = BuildAgentState(entityId: 2, side: TeamSide.Defend, dDef);

match.Sim.Agents.Add(atk);
match.Sim.Agents.Add(def);

// Prepare map + smoke for raycast engine
var mapDef = db.Maps["map.sample.box"];
var mapRuntime = new MapRuntime(mapDef);
var smoke = new SmokeField();

IDuelEngine engine = mode == "raycast"
    ? new RaycastDuelEngine(mapRuntime, smoke)
    : new TtkDuelEngine { Samples = samples };

RoundResult? last = null;

for (int r = 0; r < rounds; r++)
{
    match.RoundIndex = r;

    RoundSystem.ApplyRoundStart(match, db, ruleset, last);

    // Simple buy phase
    foreach (var ag in match.Sim.Agents)
        BuySystem.EnsureRoundLoadout(ag, db, ruleset);

    Console.WriteLine($"\n=== ROUND {r + 1} ===");
    foreach (var ag in match.Sim.Agents)
        Console.WriteLine($"{ag.Side,-6} {ag.AgentId,-28} credits={ag.Credits} weapon={ag.Weapon.WeaponId}");

    // Build duel runtime from equipped weapons
    var atkRt = ToRuntime(atk, db);
    var defRt = ToRuntime(def, db);

    // Simple duel context (top-down sim): fixed distance/exposure, slight movement.
    var a2d = new DuelInput(atkRt, defRt, Distance: 22f, Exposure: 0.75f, ShooterSpeed: 1.2f, TargetSpeed: 0.4f, ShooterCrouched: false, TargetCrouched: true);
    var d2a = new DuelInput(defRt, atkRt, Distance: 22f, Exposure: 0.60f, ShooterSpeed: 0.6f, TargetSpeed: 1.0f, ShooterCrouched: true, TargetCrouched: false);

    var rng = new DeterministicRng(DeterministicRng.HashSeed("round", seed, r));
    var res = TwoWayDuel.Resolve(engine, rng, a2d, d2a);

    Console.WriteLine($"Duel result: winner={res.Winner} simultaneous={res.Simultaneous}");
    Console.WriteLine($"  A->D: kill={res.AttackToDefend.TargetKilled} ttk={res.AttackToDefend.TimeToKill:0.00}s shots={res.AttackToDefend.ShotsFired} hits={res.AttackToDefend.Hits}");
    Console.WriteLine($"  D->A: kill={res.DefendToAttack.TargetKilled} ttk={res.DefendToAttack.TimeToKill:0.00}s shots={res.DefendToAttack.ShotsFired} hits={res.DefendToAttack.Hits}");

    last = new RoundResult(res.Winner);

    // Between rounds, keep credits for economy progression; combat state resets in ApplyRoundStart.
}

static AgentState BuildAgentState(int entityId, TeamSide side, AgentDef def)
{
    var st = new AgentState
    {
        EntityId = entityId,
        Side = side,
        AgentId = def.Id,
        Pos = new Vec2(side == TeamSide.Attack ? 0 : 10, 0),
        Vel = new Vec2(0, 0),
        FacingRad = 0,
        MaxHp = def.BaseHp,
        Hp = def.BaseHp,
        MaxArmor = def.BaseArmor,
        Armor = def.BaseArmor,
        LoadoutWeaponIds = def.LoadoutWeaponIds,
        LoadoutUtilityIds = def.LoadoutUtilityIds
    };

    // Initialize utility state entries for desired loadout utilities.
    foreach (var uid in def.LoadoutUtilityIds)
        st.Utilities[uid] = new UtilityState { UtilityId = uid, Charges = 0, CooldownTimer = 0 };

    return st;
}

static AgentRuntime ToRuntime(AgentState a, DefDatabase db)
{
    var w = db.Weapons[a.Weapon.WeaponId];
    // For this runner, traits come from defs by AgentId.
    var ad = db.Agents[a.AgentId];

    return new AgentRuntime
    {
        Traits = ad.Traits,
        Weapon = w,
        Hp = a.Hp,
        Armor = a.Armor,
        Stress = a.Stress,
        ReactionTimer = a.ReactionTimer
    };
}
