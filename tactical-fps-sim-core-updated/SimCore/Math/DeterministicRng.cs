using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;

namespace SimCore.Math;

public sealed class DeterministicRng
{
    private ulong _state;

    public DeterministicRng(ulong seed) => _state = seed == 0 ? 0x9E3779B97F4A7C15UL : seed;

    // xorshift64*
    public ulong NextU64()
    {
        ulong x = _state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        _state = x;
        return x * 0x2545F4914F6CDD1DUL;
    }

    public float NextFloat01()
    {
        // 24-bit mantissa float
        return (NextU64() >> 40) / (float)(1UL << 24);
    }

    public float NextNormal(float mean, float stdDev)
    {
        // Box-Muller
        var u1 = System.Math.Max(1e-7f, NextFloat01());
        var u2 = NextFloat01();
        var z0 = System.MathF.Sqrt(-2f * System.MathF.Log(u1)) * System.MathF.Cos(2f * System.MathF.PI * u2);
        return mean + stdDev * z0;
    }

    public static ulong HashSeed(params object[] parts)
    {
        // Stable seed derivation using SHA256 of UTF8 concatenation.
        var s = string.Join("|", parts.Select(p => p.ToString()));
        var bytes = Encoding.UTF8.GetBytes(s);
        var hash = SHA256.HashData(bytes);
        return BinaryPrimitives.ReadUInt64LittleEndian(hash.AsSpan(0, 8));
    }
}
