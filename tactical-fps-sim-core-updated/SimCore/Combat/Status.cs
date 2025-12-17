namespace SimCore.Combat;

public sealed class StatusState
{
    public float FlashTimer;
    public float ConcussTimer;
    public float SlowTimer;
    public float BurnTimer;
    public float RevealTimer;
    public float SuppressTimer;

    public bool IsFlashed => FlashTimer > 0;
    public bool IsConcussed => ConcussTimer > 0;
    public bool IsSlowed => SlowTimer > 0;
    public bool IsBurning => BurnTimer > 0;
    public bool IsSuppressed => SuppressTimer > 0;


    public void ClearAll()
    {
        FlashTimer = ConcussTimer = SlowTimer = BurnTimer = RevealTimer = SuppressTimer = 0;
    }

    public void Tick(float dt)
    {
        FlashTimer = System.MathF.Max(0, FlashTimer - dt);
        ConcussTimer = System.MathF.Max(0, ConcussTimer - dt);
        SlowTimer = System.MathF.Max(0, SlowTimer - dt);
        BurnTimer = System.MathF.Max(0, BurnTimer - dt);
        RevealTimer = System.MathF.Max(0, RevealTimer - dt);
        SuppressTimer = System.MathF.Max(0, SuppressTimer - dt);
    }
}