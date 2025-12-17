using SimCore.Defs;
using SimCore.Economy;

// Console runner: exercises defs loading, economy+refills, and duel engines.
//
// Examples:
//   dotnet run --project SimConsoleRunner -- --defs ./Defs --rules rules.cs --rounds 5 --engine ttk
//   dotnet run --project SimConsoleRunner -- --defs ./Defs --rules rules.val --rounds 5 --engine raycast --atk agent.val.duelist --def agent.val.sentinel

static string GetArg(Dictionary<string, string> args, string key, string fallback)
    => args.TryGetValue(key, out var v) && !string.IsNullOrWhiteSpace(v) ? v : fallback;

static int GetInt(Dictionary<string, string> args, string key, int fallback)
    => int.TryParse(GetArg(args, key, ""), out var n) ? n : fallback;

static float GetFloat(Dictionary<string, string> args, string key, float fallback)
    => float.TryParse(GetArg(args, key, ""), out var n) ? n : fallback;

var kv = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
for (int i = 0; i < args.Length; i++)
{
    if (!args[i].StartsWith("--")) continue;
    var k = args[i][2..];
    var v = (i + 1 < args.Length && !args[i + 1].StartsWith("--")) ? args[++i] : "true";
    kv[k] = v;
}

string defsFolder = Path.GetFullPath(GetArg(kv, "defs", Path.Combine(Environment.CurrentDirectory, "Defs")));
string rulesId = GetArg(kv, "rules", "rules.cs");
int rounds = GetInt(kv, "rounds", 5);
string engine = GetArg(kv, "engine", "ttk");
string atkId = GetArg(kv, "atk", "agent.sample.entry");
string defId = GetArg(kv, "def", "agent.sample.anchor");
float distance = GetFloat(kv, "distance", 18f);
float exposure = GetFloat(kv, "exposure", 0.80f);
int seed = GetInt(kv, "seed", 12345);

var db = new DefDatabase();
db.LoadFromFolder(defsFolder);

if (!db.Rulesets.ContainsKey(rulesId))
{
    Console.Error.WriteLine($"Ruleset '{rulesId}' not found. Available: {string.Join(", ", db.Rulesets.Keys.OrderBy(x => x))}");
    return;
}

if (!db.Agents.ContainsKey(atkId) || !db.Agents.ContainsKey(defId))
{
    Console.Error.WriteLine("Agent IDs not found. Available agent IDs:");
    foreach (var id in db.Agents.Keys.OrderBy(x => x)) Console.Error.WriteLine($"  - {id}");
    return;
}

var cfg = new MatchConfig { Seed = seed, RulesetId = rulesId, TickRate = 20, MapId = db.Maps.Keys.First() };
var rr = new RoundRunner(cfg, db);

Console.WriteLine($"Defs:   {defsFolder}");
Console.WriteLine($"Rules:  {rulesId}");
Console.WriteLine($"Engine: {engine}");
Console.WriteLine($"Atk:    {atkId}");
Console.WriteLine($"Def:    {defId}");
Console.WriteLine($"Rounds: {rounds}\n");

int atkWins = 0;
for (int r = 1; r <= rounds; r++)
{
    var sum = rr.RunDuelRound(r, atkId, defId, engine, distance, exposure);
    if (sum.AttackerKilledDefender) atkWins++;

    Console.WriteLine($"Round {sum.RoundIndex} | {(sum.AttackerKilledDefender ? "ATTACKER" : "DEFENDER")} wins | TTK={sum.TimeToKill:0.000}s | shots={sum.ShotsFired} hits={sum.Hits}");
    PrintAgent(sum.Attacker, label: "ATK");
    PrintAgent(sum.Defender, label: "DEF");
    Console.WriteLine();
}

Console.WriteLine($"Series result: attacker won {atkWins}/{rounds} rounds");

static void PrintAgent(AgentSummary a, string label)
{
    Console.WriteLine($"  {label} {a.Name} | weapon={a.WeaponId} | credits={a.Credits}");
    if (a.Utilities.Length > 0)
        Console.WriteLine($"    util: {string.Join(", ", a.Utilities.Select(u => $"{u.UtilityId}x{u.Charges}"))}");
}
