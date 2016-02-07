
module markov.binary.decoder;

import markov.chain;
import markov.counter;
import markov.serialize;
import markov.state;

import std.algorithm;
import std.array;
import std.bitmanip;
import std.conv;
import std.range;
import std.traits;

struct BinaryDecoder(T)
if(isDecodable!(T, ubyte[]))
{
public:
    MarkovChain!T decode()(ubyte[] input)
    {
        auto range = inputRangeObject(input);
        return decode(range);
    }

    MarkovChain!T decode(Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte))
    {
        return MarkovChain!(T)(decodeStates(input));
    }

    State!T[] decodeStates(Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte))
    {
        uint count = decodeValue!(uint)(input);
        return iota(0, count).map!(i => decodeState(input)).array;
    }

    State!T decodeState(Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte))
    {
        State!T state = State!T(decodeValue!(uint)(input));
        uint length = decodeValue!(uint)(input);

        foreach(i; 0 .. length)
        {
            state.set(
                decodeTokens(input),
                decodeCounter(input)
            );
        }

        return state;
    }

    Counter!T decodeCounter(Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte))
    {
        Counter!T counter;
        uint length = decodeValue!(uint)(input);

        foreach(i; 0 .. length)
        {
            counter.set(
                decodeToken(input),
                decodeValue!(uint)(input)
            );
        }

        return counter;
    }

private:
    Type decodeValue(Type, Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte) && isSomeString!Type)
    {
        // TODO : Handle wide strings.
        uint length = decodeValue!(uint)(input);
        return input.take(length).map!(b => b.to!char).array.idup;
    }

    Type decodeValue(Type, Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte) && isArray!Type && !isSomeString!Type)
    {
        uint length = decodeValue!(uint)(input);
        return iota(0, length).map!(i => decodeValue!(ElementType!Type)(input)).array;
    }

    Type decodeValue(Type, Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte) && isArray!Type && !isSomeString!Type)
    {
        ValueType!Type[KeyType!Type] data;
        uint length = decodeValue!(uint)(input);

        foreach(i; 0 .. length)
        {
            data[decodeValue!(KeyType!Type)(input)] = decodeValue!(ValueType!Type)(input);
        }

        return data;
    }

    Type decodeValue(Type, Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte) && isNumeric!Type)
    {
        ubyte[Type.sizeof] b = input.take(Type.sizeof).array[0 .. Type.sizeof];
        return b.bigEndianToNative!Type;
    }

    Type decodeValue(Type, Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte) && isBoolean!Type)
    {
        scope(exit) input.popFront;
        return !!input.front;
    }

    T decodeToken(Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte))
    {
        static if(hasDecodeProperty!(T, ubyte[]))
        {
            return T.decode(input.table(T.sizeof));
        }
        else
        {
            return decodeValue!(T)(input);
        }
    }

    T[] decodeTokens(Range)(ref Range input)
    if(isInputRange!Range && is(ElementType!Range : ubyte))
    {
        uint count = decodeValue!(uint)(input);
        return iota(0, count).map!(i => decodeToken(input)).array;
    }
}

unittest
{
    BinaryDecoder!string decoder;
    decoder.decode([0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]);
}
