using SimCore.Defs;

namespace SimCore.Sim;

public sealed class TeamEconomyState
{
    public TeamSide Side { get; init; }
    public int Score { get; set; }
    public int LossStreak { get; set; } // consecutive losses
}

public sealed class MatchState
{
    public int RoundIndex { get; set; }
    public TeamEconomyState Attack { get; } = new() { Side = TeamSide.Attack };
    public TeamEconomyState Defend { get; } = new() { Side = TeamSide.Defend };

    public SimState Sim { get; } = new();
}
