using SimCore.Defs;

namespace SimCore.Geometry;

public sealed class MapRuntime
{
    public string Id { get; }
    public Segment[] Walls { get; }

    public MapRuntime(MapDef def)
    {
        Id = def.Id;
        Walls = def.Walls.Select(w => new Segment(w.Ax, w.Ay, w.Bx, w.By)).ToArray();
    }
}
