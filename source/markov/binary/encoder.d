
module markov.binary.encoder;

import markov.chain;
import markov.counter;
import markov.serialize;
import markov.state;

import std.algorithm;
import std.array;
import std.bitmanip;
import std.conv;
import std.outbuffer;
import std.range;
import std.traits;

struct BinaryEncoder(T)
if(isEncodable!(T, ubyte[]))
{
public:
    ubyte[] encode()(ref MarkovChain!T chain)
    {
        auto buffer = new OutBuffer;
        encode(chain, buffer);
        return buffer.toBytes;
    }

    void encode(Range)(ref MarkovChain!T chain, ref Range output)
    if(isOutputRange!(Range, ubyte))
    {
        encodeStates(chain.states, output);
    }

    void encodeStates(Range)(State!T[] states, ref Range output)
    if(isOutputRange!(Range, ubyte))
    {
        encodeValue!(uint)(cast(uint) states.length, output);
        states.each!(state => encodeState(state, output));
    }

    void encodeState(Range)(State!T state, ref Range output)
    if(isOutputRange!(Range, ubyte))
    {
        encodeValue!(uint)(cast(uint) state.size, output);
        encodeValue!(uint)(cast(uint) state.length, output);

        foreach(key; state.keys)
        {
            encodeTokens(key, output);
            encodeCounter(state.get(key), output);
        }
    }

    void encodeCounter(Range)(Counter!T counter, ref Range output)
    if(isOutputRange!(Range, ubyte))
    {
        encodeValue!(uint)(cast(uint) counter.length, output);

        foreach(key; counter.keys)
        {
            encodeToken(key, output);
            encodeValue!(uint)(counter.get(key), output);
        }
    }

private:
    void encodeValue(Type, Range)(Type value, ref Range output)
    if(isOutputRange!(Range, ubyte) && isSomeString!Type)
    {
        // TODO : Handle wide strings.
        encodeValue!(uint)(cast(uint) value.length, output);
        value.map!(to!ubyte).each!(b => put(output, b));
    }

    void encodeValue(Type, Range)(Type value, ref Range output)
    if(isOutputRange!(Range, ubyte) && isArray!Type && !isSomeString!Type)
    {
        encodeValue!(uint)(cast(uint) value.length, output);
        value.each!(e => encodeValue!(ForeachType!Type)(e, output));
    }

    void encodeValue(Type, Range)(Type value, ref Range output)
    if(isOutputRange!(Range, ubyte) && isAssociativeArray!Type)
    {
        encodeValue!(uint)(value.length, output);

        foreach(key, element; value)
        {
            encodeValue!(KeyType!Type)(key, output);
            encodeValue!(ValueType!Type)(element, output);
        }
    }

    void encodeValue(Type, Range)(Type value, ref Range output)
    if(isOutputRange!(Range, ubyte) && isNumeric!Type)
    {
        value.nativeToBigEndian[].each!(b => put(output, b));
    }

    void encodeValue(Type, Range)(Type value, ref Range output)
    if(isOutputRange!(Range, ubyte) && isBoolean!Type)
    {
        put(output, cast(ubyte)(value ? 1 : 0));
    }

    void encodeToken(Range)(T token, ref Range output)
    if(isOutputRange!(Range, ubyte))
    {
        static if(hasEncodeProperty!(T, ubyte[]))
        {
            token.encode.each!(b => put(output, b));
        }
        else
        {
            encodeValue!(T)(token, output);
        }
    }

    void encodeTokens(Range)(T[] tokens, ref Range output)
    if(isOutputRange!(Range, ubyte))
    {
        encodeValue!(uint)(cast(uint) tokens.length, output);
        tokens.each!(token => encodeToken(token, output));
    }
}

unittest
{
    import markov.binary.decoder;
    auto chain1 = MarkovChain!string(1, 2, 3);
    chain1.train("a", "b", "c", "e", "b", "a", "b", "a", "c", "e", "d", "c", "b", "a");

    BinaryEncoder!string encoder;
    BinaryDecoder!string decoder;

    auto bytes = encoder.encode(chain1);
    auto chain2 = decoder.decode(bytes);

    assert(chain1.sizes.length == chain2.sizes.length);

    foreach(state1, state2; chain1.states.sort!"a.size > b.size".lockstep(chain2.states.sort!"a.size > b.size"))
    {
        assert(state1.size == state2.size);
        assert(state1.keys.length == state2.keys.length);

        foreach(first1, first2; sort(state1.keys).lockstep(sort(state1.keys)))
        {
            assert(first1 == first2);
            auto counters1 = state1.get(first1);
            auto counters2 = state2.get(first2);

            assert(counters1.total == counters2.total);
            assert(sort(counters1.keys) == sort(counters2.keys));

            foreach(follow1, follow2; sort(counters1.keys).lockstep(sort(counters2.keys)))
            {
                assert(follow1 == follow2);
                assert(counters1.get(follow1) == counters2.get(follow2));
            }
        }
    }
}
