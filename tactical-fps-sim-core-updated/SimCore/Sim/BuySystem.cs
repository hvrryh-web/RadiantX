using SimCore.Defs;

namespace SimCore.Sim;

public static class BuySystem
{
    public static void EnsureRoundLoadout(AgentState agent, DefDatabase db, RulesetDef ruleset)
    {
        // Weapon: pick first compatible weapon in the agent's loadout list.
        if (string.IsNullOrWhiteSpace(agent.Weapon.WeaponId))
        {
            foreach (var wid in agent.LoadoutWeaponIds)
            {
                if (!db.Weapons.TryGetValue(wid, out var w)) continue;
                if (TryPurchaseWeapon(agent, ruleset, w))
                {
                    EquipWeapon(agent, w);
                    break;
                }
            }
        }

        // Utilities/abilities: buy up to MaxCharges for compatible family.
        foreach (var uid in agent.LoadoutUtilityIds)
        {
            if (!db.Utilities.TryGetValue(uid, out var u)) continue;
            if (u.Family != ruleset.UtilityFamily) continue;

            if (!agent.Utilities.TryGetValue(uid, out var st))
                st = new UtilityState { UtilityId = uid, Charges = 0, CooldownTimer = 0 };

            while (st.Charges < u.MaxCharges)
            {
                if (!TryPurchaseUtilityCharge(agent, ruleset, u)) break;
                st.Charges++;
            }

            agent.Utilities[uid] = st;
        }
    }

    public static bool TryPurchaseWeapon(AgentState agent, RulesetDef ruleset, WeaponDef weapon)
    {
        if (weapon.CreditCost <= 0) return true;
        if (agent.Credits < weapon.CreditCost) return false;
        agent.Credits -= weapon.CreditCost;
        return true;
    }

    public static bool TryPurchaseUtilityCharge(AgentState agent, RulesetDef ruleset, UtilityDef util)
    {
        // CS/VAL both spend credits; you can later fork via ruleset.UsesAbilityEconomy.
        if (util.CreditCost <= 0) return true;
        if (agent.Credits < util.CreditCost) return false;
        agent.Credits -= util.CreditCost;
        return true;
    }

    public static void EquipWeapon(AgentState agent, WeaponDef weapon)
    {
        agent.Weapon.WeaponId = weapon.Id;
        agent.Weapon.AmmoInMag = weapon.MagazineSize;
        agent.Weapon.FireCooldown = 0;
        agent.Weapon.ReloadTimer = 0;
        agent.Weapon.Recoil = 0;
    }
}
