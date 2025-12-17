using SimCore.Defs;

namespace SimCore.Sim;

public sealed record RoundResult(TeamSide Winner, int AttackAlive = 0, int DefendAlive = 0);

public static class RoundSystem
{
    public static void ApplyRoundStart(
        MatchState match,
        DefDatabase db,
        RulesetDef ruleset,
        RoundResult? lastRoundResult)
    {
        // Round 1: initialize credits to round-start baseline.
        if (match.RoundIndex == 0 && lastRoundResult is null)
        {
            foreach (var a in match.Sim.Agents)
                a.Credits = ruleset.RoundStartCredits;

            match.Attack.LossStreak = 0;
            match.Defend.LossStreak = 0;
        }
        else if (lastRoundResult is not null)
        {
            ApplyEconomy(match, ruleset, lastRoundResult.Winner);
        }

        // Reset per-round combat state (tactical FPS norm).
        foreach (var a in match.Sim.Agents)
        {
            if (ruleset.ResetHpEachRound) a.Hp = a.MaxHp;
            if (ruleset.ResetArmorEachRound) a.Armor = a.MaxArmor;

            a.Stress = 0;
            a.ReactionTimer = 0;
            a.Status.ClearAll();

            // Weapon reload/cooldowns reset at round start.
            a.Weapon.FireCooldown = 0;
            a.Weapon.ReloadTimer = 0;
            a.Weapon.Recoil = 0;

            // Ability/grenade round-start refills.
            RefillUtilitiesAtRoundStart(a, db, ruleset);
        }
    }

    private static void ApplyEconomy(MatchState match, RulesetDef ruleset, TeamSide winner)
    {
        var atkWon = winner == TeamSide.Attack;
        ApplyTeamEconomy(match.Attack, match.Sim.Agents, ruleset, atkWon);
        ApplyTeamEconomy(match.Defend, match.Sim.Agents, ruleset, !atkWon);
    }

    private static void ApplyTeamEconomy(TeamEconomyState team, List<AgentState> agents, RulesetDef ruleset, bool won)
    {
        if (won)
        {
            team.Score++;
            team.LossStreak = 0;
        }
        else
        {
            team.LossStreak++;
        }

        // Income model (data-driven; kept deliberately simple).
        int income;
        if (won)
        {
            income = ruleset.RoundWinCredits;
        }
        else
        {
            int streakIndex = System.Math.Clamp(team.LossStreak - 1, 0, ruleset.LossStreakBonuses.Length - 1);
            income = ruleset.RoundLossCredits + ruleset.LossStreakBonuses[streakIndex];
        }

        foreach (var a in agents)
        {
            if (a.Side != team.Side) continue;
            a.Credits = System.Math.Min(ruleset.MaxCredits, a.Credits + income);
        }
    }

    private static void RefillUtilitiesAtRoundStart(AgentState agent, DefDatabase db, RulesetDef ruleset)
    {
        foreach (var kvp in agent.Utilities)
        {
            var utilId = kvp.Key;
            var state = kvp.Value;

            if (!db.Utilities.TryGetValue(utilId, out var def))
                continue;

            // Cooldown ticks naturally during play; at round start we clear cooldown.
            state.CooldownTimer = 0;

            int minCharges = def.RoundStartCharges;

            if (def.Family == UtilityFamily.VAL_Ability && def.IsSignature && ruleset.RefillSignatureEachRound)
                minCharges = System.Math.Max(minCharges, ruleset.DefaultSignatureRoundStartCharges);

            // Set-to-at-least semantics to avoid wiping purchased charges.
            state.Charges = System.Math.Max(state.Charges, minCharges);
            agent.Utilities[utilId] = state;
        }
    }
}
