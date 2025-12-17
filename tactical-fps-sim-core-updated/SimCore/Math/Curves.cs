namespace SimCore.Math;

public sealed class Curve
{
    public (float X, float Y)[] Keys { get; init; } = Array.Empty<(float, float)>();

    public float Evaluate(float x)
    {
        if (Keys.Length == 0) return 1f;
        if (x <= Keys[0].X) return Keys[0].Y;
        for (int i = 0; i < Keys.Length - 1; i++)
        {
            var a = Keys[i];
            var b = Keys[i + 1];
            if (x <= b.X)
            {
                var t = (x - a.X) / (b.X - a.X);
                return a.Y + t * (b.Y - a.Y);
            }
        }
        return Keys[^1].Y;
    }
}
