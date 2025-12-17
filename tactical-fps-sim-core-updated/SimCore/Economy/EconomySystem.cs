using SimCore.Defs;
using SimCore.Sim;

namespace SimCore.Economy;

/// <summary>
/// Minimal but production-usable economy + round-start refill logic.
/// 
/// Design intent:
/// - Keep everything deterministic and data-driven.
/// - Support both CS-like grenades and VAL-like abilities using the same UtilityDef fields.
/// - Keep "buy" logic in one place so you can swap in a smarter GM/coach AI later.
/// </summary>
public static class EconomySystem
{
    public static void InitializeAgentState(
        AgentState agent,
        AgentDef def,
        RulesetDef rules,
        DefDatabase db)
    {
        // Credits are only assigned here if not already set.
        if (agent.Credits <= 0)
            agent.Credits = rules.RoundStartCredits;

        // Initialize weapon to first loadout weapon (fallback to any known weapon).
        string weaponId = def.LoadoutWeaponIds.FirstOrDefault() ?? db.Weapons.Keys.First();
        if (!db.Weapons.ContainsKey(weaponId))
            weaponId = db.Weapons.Keys.First();

        agent.Weapon.WeaponId = weaponId;
        agent.Weapon.AmmoInMag = db.Weapons[weaponId].MagazineSize;

        // Initialize utilities dictionary with zero charges.
        foreach (var uid in def.LoadoutUtilityIds)
        {
            if (!db.Utilities.TryGetValue(uid, out var u)) continue;
            agent.Utilities[uid] = new UtilityState { UtilityId = uid, Charges = 0, CooldownTimer = 0f };
        }
    }

    public static void RoundStart(
        AgentState agent,
        AgentDef def,
        RulesetDef rules,
        DefDatabase db)
    {
        // Reset vitals
        if (rules.ResetHpEachRound)
        {
            agent.MaxHp = def.BaseHp;
            agent.Hp = def.BaseHp;
        }
        if (rules.ResetArmorEachRound)
            agent.Armor = def.BaseArmor;

        // Reset transient combat state
        agent.Stress = 0f;
        agent.ReactionTimer = 0f;
        agent.Status = new SimCore.Combat.StatusState();
        agent.Weapon.FireCooldown = 0f;
        agent.Weapon.ReloadTimer = 0f;
        agent.Weapon.Recoil = 0f;

        // Refill ammo in mag each round (tactical FPS norm)
        if (db.Weapons.TryGetValue(agent.Weapon.WeaponId, out var w))
            agent.Weapon.AmmoInMag = w.MagazineSize;

        // Tick down cooldowns to 0 at the start of a round (buy-phase baseline)
        foreach (var kv in agent.Utilities)
            kv.Value.CooldownTimer = 0f;

        // Apply free refills (VAL signature and generic round-start charges)
        ApplyRoundStartUtilityRefills(agent, rules, db);

        // Spend credits to buy remaining charges (CS grenades or VAL purchasable abilities)
        BuyUtilities(agent, def, rules, db);
    }

    public static void ApplyRoundStartUtilityRefills(AgentState agent, RulesetDef rules, DefDatabase db)
    {
        foreach (var kv in agent.Utilities)
        {
            if (!db.Utilities.TryGetValue(kv.Key, out var util)) continue;

            int refillToAtLeast = 0;

            if (util.IsSignature && rules.RefillSignatureEachRound && rules.UtilityFamily == UtilityFamily.VAL_Ability)
            {
                refillToAtLeast = System.Math.Max(util.RoundStartCharges, rules.DefaultSignatureRoundStartCharges);
            }
            else
            {
                refillToAtLeast = util.RoundStartCharges;
            }

            if (refillToAtLeast > 0)
                kv.Value.Charges = System.Math.Min(util.MaxCharges, System.Math.Max(kv.Value.Charges, refillToAtLeast));
        }
    }

    public static void BuyUtilities(AgentState agent, AgentDef def, RulesetDef rules, DefDatabase db)
    {
        // If a user wants strict phase separation, call this only during buy-time.
        // Here we treat it as "auto-buy" for a manager sim.

        if (rules.UtilityFamily == UtilityFamily.CS_Grenade)
        {
            int totalGrenades = agent.Utilities.Values.Sum(u => u.Charges);
            foreach (var uid in def.LoadoutUtilityIds)
            {
                if (totalGrenades >= rules.MaxGrenades) break;
                if (!db.Utilities.TryGetValue(uid, out var util)) continue;

                if (!agent.Utilities.TryGetValue(uid, out var st))
                    agent.Utilities[uid] = st = new UtilityState { UtilityId = uid };

                while (st.Charges < util.MaxCharges && totalGrenades < rules.MaxGrenades)
                {
                    if (util.CreditCost > 0 && agent.Credits < util.CreditCost) break;
                    if (util.CreditCost > 0) agent.Credits -= util.CreditCost;
                    st.Charges++;
                    totalGrenades++;
                }
            }

            return;
        }

        // VAL-like abilities: purchase up to MaxCharges per ability.
        if (rules.UsesAbilityEconomy)
        {
            foreach (var uid in def.LoadoutUtilityIds)
            {
                if (!db.Utilities.TryGetValue(uid, out var util)) continue;

                if (!agent.Utilities.TryGetValue(uid, out var st))
                    agent.Utilities[uid] = st = new UtilityState { UtilityId = uid };

                // Signatures may already have 1 charge; purchase up to MaxCharges.
                while (st.Charges < util.MaxCharges)
                {
                    if (util.CreditCost <= 0) break;
                    if (agent.Credits < util.CreditCost) break;
                    agent.Credits -= util.CreditCost;
                    st.Charges++;
                }
            }
        }
    }

    public static void AwardKillCredits(AgentState killer, RulesetDef rules)
    {
        killer.Credits = System.Math.Min(rules.MaxCredits, killer.Credits + rules.KillCredits);
    }

    public static void ApplyRoundEndRewards(IEnumerable<AgentState> teamAgents, bool wonRound, RulesetDef rules)
    {
        int delta = wonRound ? rules.RoundWinCredits : rules.RoundLossCredits;
        foreach (var a in teamAgents)
            a.Credits = System.Math.Min(rules.MaxCredits, a.Credits + delta);
    }
}
