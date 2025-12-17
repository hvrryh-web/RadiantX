namespace SimCore.Geometry;

public readonly record struct Segment(float Ax, float Ay, float Bx, float By)
{
    public override string ToString() => $"[{Ax},{Ay}] -> [{Bx},{By}]";
}
