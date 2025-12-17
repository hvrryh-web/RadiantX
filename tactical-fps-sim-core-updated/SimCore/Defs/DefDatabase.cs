using System.Text.Json;
using SimCore.Math;

namespace SimCore.Defs;

public sealed class DefDatabase
{
    public Dictionary<string, RulesetDef> Rulesets { get; } = new();
    public Dictionary<string, AgentDef> Agents { get; } = new();
    public Dictionary<string, WeaponDef> Weapons { get; } = new();
    public Dictionary<string, UtilityDef> Utilities { get; } = new();
    public Dictionary<string, MapDef> Maps { get; } = new();

    private readonly JsonSerializerOptions _json;

    public DefDatabase()
    {
        _json = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            ReadCommentHandling = JsonCommentHandling.Skip
        };
        _json.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    }

    public void LoadFromFolder(string defsFolder)
    {

        // Flexible loader: drop more defs in Defs/ without changing code.
        if (!Directory.Exists(defsFolder))
            throw new DirectoryNotFoundException(defsFolder);

        // Rulesets: rules*.json (each file is a single object)
        foreach (var path in Directory.EnumerateFiles(defsFolder, "rules*.json"))
            LoadSingle<RulesetDef>(path, d => Rulesets[d.Id] = d);

        // Weapons: weapons*.json (each file is an array)
        foreach (var path in Directory.EnumerateFiles(defsFolder, "weapons*.json"))
            LoadWeaponArray(path);

        // Utilities: utilities*.json (each file is an array)
        foreach (var path in Directory.EnumerateFiles(defsFolder, "utilities*.json"))
            LoadArray<UtilityDef>(path, u => Utilities[u.Id] = u);

        // Agents: agents*.json (each file is an array)
        foreach (var path in Directory.EnumerateFiles(defsFolder, "agents*.json"))
            LoadArray<AgentDef>(path, a => Agents[a.Id] = a);

        // Maps: map*.json (each file is a single object)
        foreach (var path in Directory.EnumerateFiles(defsFolder, "map*.json"))
            LoadSingle<MapDef>(path, m => Maps[m.Id] = m);

        ValidateReferences();
    }

    private void LoadWeaponArray(string path)
    {
        if (!File.Exists(path)) return;

        var json = File.ReadAllText(path);
        var arr = JsonSerializer.Deserialize<WeaponDefJson[]>(json, _json);
        if (arr is null) throw new InvalidOperationException($"Failed to parse {path}");

        foreach (var j in arr)
        {
            var w = new WeaponDef
            {
                Id = j.Id,
                FireMode = j.FireMode,
                CreditCost = j.CreditCost,
                MagazineSize = j.MagazineSize,
                RoundsPerMinute = j.RoundsPerMinute,
                ReloadTime = j.ReloadTime,
                Damage = new DamageProfile
                {
                    BaseDamage = j.Damage.BaseDamage,
                    HeadMult = j.Damage.HeadMult,
                    LegMult = j.Damage.LegMult,
                    RangeMultiplier = new Curve
                    {
                        Keys = j.Damage.RangeMultiplierKeys.Select(k => (k.X, k.Y)).ToArray()
                    }
                },
                Spread = new SpreadProfile
                {
                    BaseSigma = j.Spread.BaseSigma,
                    CrouchMult = j.Spread.CrouchMult,
                    MoveSigmaAdd = j.Spread.MoveSigmaAdd,
                    JumpSigmaAdd = j.Spread.JumpSigmaAdd,
                    FirstShotBonus = j.Spread.FirstShotBonus
                },
                Recoil = new RecoilProfile
                {
                    RecoilPerShot = j.Recoil.RecoilPerShot,
                    MaxRecoil = j.Recoil.MaxRecoil,
                    RecoveryPerSec = j.Recoil.RecoveryPerSec
                },
                Penetration = new PenetrationProfile
                {
                    CanPenetrate = j.Penetration.CanPenetrate,
                    PenPower = j.Penetration.PenPower,
                    DamageLossPerUnit = j.Penetration.DamageLossPerUnit
                }
            };

            Weapons[w.Id] = w;
        }
    }

    private void LoadSingle<T>(string path, Action<T> sink)
    {
        if (!File.Exists(path)) return;
        var json = File.ReadAllText(path);
        var item = JsonSerializer.Deserialize<T>(json, _json);
        if (item is null) throw new InvalidOperationException($"Failed to parse {path}");
        sink(item);
    }

    private void LoadArray<T>(string path, Action<T> sink)
    {
        if (!File.Exists(path)) return;
        var json = File.ReadAllText(path);
        var arr = JsonSerializer.Deserialize<T[]>(json, _json);
        if (arr is null) throw new InvalidOperationException($"Failed to parse {path}");
        foreach (var item in arr) sink(item);
    }

    private void ValidateReferences()
    {
        foreach (var a in Agents.Values)
        {
            foreach (var wid in a.LoadoutWeaponIds)
                if (!Weapons.ContainsKey(wid))
                    throw new InvalidOperationException($"Agent {a.Id} references missing weapon {wid}");

            foreach (var uid in a.LoadoutUtilityIds)
                if (!Utilities.ContainsKey(uid))
                    throw new InvalidOperationException($"Agent {a.Id} references missing utility {uid}");
        }
    }

    // -------- JSON DTOs --------
    private sealed class WeaponDefJson
    {
        public string Id { get; init; } = "";
        public FireMode FireMode { get; init; }
        public int CreditCost { get; init; } = 0;
        public int MagazineSize { get; init; }
        public float RoundsPerMinute { get; init; }
        public float ReloadTime { get; init; }
        public DamageJson Damage { get; init; } = new();
        public SpreadJson Spread { get; init; } = new();
        public RecoilJson Recoil { get; init; } = new();
        public PenetrationJson Penetration { get; init; } = new();
    }

    private sealed class DamageJson
    {
        public float BaseDamage { get; init; }
        public float HeadMult { get; init; }
        public float LegMult { get; init; }
        public KeyPoint[] RangeMultiplierKeys { get; init; } = Array.Empty<KeyPoint>();
    }

    private sealed class SpreadJson
    {
        public float BaseSigma { get; init; }
        public float CrouchMult { get; init; }
        public float MoveSigmaAdd { get; init; }
        public float JumpSigmaAdd { get; init; }
        public float FirstShotBonus { get; init; }
    }

    private sealed class RecoilJson
    {
        public float RecoilPerShot { get; init; }
        public float MaxRecoil { get; init; }
        public float RecoveryPerSec { get; init; }
    }

    private sealed class PenetrationJson
    {
        public bool CanPenetrate { get; init; }
        public float PenPower { get; init; }
        public float DamageLossPerUnit { get; init; }
    }

    private sealed class KeyPoint
    {
        public float X { get; init; }
        public float Y { get; init; }
    }
}