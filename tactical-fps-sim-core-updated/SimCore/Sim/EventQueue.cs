namespace SimCore.Sim;

public sealed class EventQueue
{
    private readonly PriorityQueue<SimEvent, float> _pq = new();

    public int Count => _pq.Count;

    public void Enqueue(SimEvent ev) => _pq.Enqueue(ev, ev.Time);

    public bool TryPeek(out SimEvent? ev) => _pq.TryPeek(out ev, out _);

    public bool TryDequeue(out SimEvent? ev)
    {
        if (_pq.TryDequeue(out ev, out _)) return true;
        return false;
    }
}
