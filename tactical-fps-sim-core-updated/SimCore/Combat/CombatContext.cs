using SimCore.Defs;
using SimCore.Geometry;

namespace SimCore.Combat;

public sealed class CombatContext
{
    public required MapRuntime Map { get; init; }
    public required SmokeField Smoke { get; init; }
    public float Time { get; set; }
    public float Dt { get; set; }
}
