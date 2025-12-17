namespace SimCore.Geometry;

public static class Raycast2D
{
    // Returns true if segment p->q intersects wall segment a->b, and outputs t along ray [0..1].
    public static bool IntersectSegment(
        float px, float py, float qx, float qy,
        float ax, float ay, float bx, float by,
        out float tRay)
    {
        tRay = float.PositiveInfinity;

        // Ray segment P + t(R), wall A + u(S)
        float rx = qx - px; float ry = qy - py;
        float sx = bx - ax; float sy = by - ay;

        float rxs = Cross(rx, ry, sx, sy);
        float q_p_x = ax - px; float q_p_y = ay - py;
        float qpxr = Cross(q_p_x, q_p_y, rx, ry);

        if (System.MathF.Abs(rxs) < 1e-8f)
        {
            // Parallel: treat as no hit for simplicity
            return false;
        }

        float t = Cross(q_p_x, q_p_y, sx, sy) / rxs;
        float u = qpxr / rxs;

        if (t >= 0f && t <= 1f && u >= 0f && u <= 1f)
        {
            tRay = t;
            return true;
        }
        return false;
    }

    private static float Cross(float ax, float ay, float bx, float by) => ax * by - ay * bx;

    public static bool HasLineOfSight(Segment[] walls, float x0, float y0, float x1, float y1)
    {
        foreach (var w in walls)
        {
            if (IntersectSegment(x0, y0, x1, y1, w.Ax, w.Ay, w.Bx, w.By, out _))
                return false;
        }
        return true;
    }

    public static float FirstHitT(Segment[] walls, float x0, float y0, float x1, float y1)
    {
        float best = float.PositiveInfinity;
        foreach (var w in walls)
        {
            if (IntersectSegment(x0, y0, x1, y1, w.Ax, w.Ay, w.Bx, w.By, out var t))
                if (t < best) best = t;
        }
        return best;
    }
}
