using SimCore.Defs;

namespace SimCore.Geometry;

// A very cheap smoke opacity field.
// For CS2-like "volumetric" smokes, upgrade this to a grid density + disturbance operations.
public sealed class SmokeField
{
    public readonly List<SmokeVolume> Smokes = new();

    public float IntegrateOpacity(Vec2 a, Vec2 b, int samples = 10)
    {
        if (Smokes.Count == 0) return 0f;

        float sum = 0f;
        for (int i = 0; i <= samples; i++)
        {
            float t = i / (float)samples;
            var p = new Vec2(
                a.X + (b.X - a.X) * t,
                a.Y + (b.Y - a.Y) * t
            );
            sum += OpacityAtPoint(p);
        }
        return sum / (samples + 1);
    }

    public float OpacityAtPoint(Vec2 p)
    {
        float o = 0f;
        foreach (var s in Smokes)
        {
            float dx = p.X - s.Center.X;
            float dy = p.Y - s.Center.Y;
            float d = System.MathF.Sqrt(dx * dx + dy * dy);
            if (d <= s.Radius)
            {
                float local = 1f - (d / s.Radius) * s.Falloff;
                o = System.MathF.Max(o, local);
            }
        }
        return System.MathF.Min(1f, o);
    }

    public void Tick(float dt)
    {
        for (int i = Smokes.Count - 1; i >= 0; i--)
        {
            Smokes[i].Remaining -= dt;
            if (Smokes[i].Remaining <= 0) Smokes.RemoveAt(i);
        }
    }
}

public sealed class SmokeVolume
{
    public Vec2 Center;
    public float Radius;
    public float Falloff;
    public float Remaining;
}
