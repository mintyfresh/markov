
module markov.serialize;

import markov.chain;
import markov.counter;
import markov.state;

import std.traits;

abstract class Decoder(T, Input) if(isDecodable!(T, Input))
{
    abstract MarkovChain!T decode(Input input);
}

abstract class Encoder(T, Output) if(isEncodable!(T, Output))
{
    abstract Output encode(ref MarkovChain!T chain);
}

template isDecodable(T, Input)
{
    enum isDecodable =
        isSomeString!T ||
        isArray!T ||
        isAssociativeArray!T ||
        isBoolean!T ||
        isNumeric!T ||
        isSomeChar!T ||
        hasDecodeProperty!(T, Input);
}

template isEncodable(T, Output)
{
    enum isEncodable =
        isSomeString!T ||
        isArray!T ||
        isAssociativeArray!T ||
        isBoolean!T ||
        isNumeric!T ||
        isSomeChar!T ||
        hasEncodeProperty!(T, Output);
}

template hasDecodeProperty(T, Input)
{
    enum hasDecodeProperty = __traits(compiles, {
        Input encoded = void;
        T decoded = T.decode(encoded);
    });
}

template hasEncodeProperty(T, Output)
{
    enum hasEncodeProperty = __traits(compiles, {
        T type = void;
        Output output = type.encode;
    });
}
