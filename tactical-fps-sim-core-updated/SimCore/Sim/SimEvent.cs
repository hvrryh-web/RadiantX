using SimCore.Defs;

namespace SimCore.Sim;

public abstract record SimEvent(float Time);

public sealed record UtilityCastEvent(float Time, int CasterId, string UtilityId, Vec2 TargetPos) : SimEvent(Time);
