
module markov.json.encoder;

import markov.chain;
import markov.counter;
import markov.serialize;
import markov.state;

import std.algorithm;
import std.array;
import std.base64;
import std.conv;
import std.json;
import std.string;

class JsonEncoder(T) : Encoder!(T, string)
{
private:
    bool _pretty;

public:
    this(bool pretty)
    {
        _pretty = pretty;
    }

    override string encode(ref MarkovChain!T chain)
    {
        JSONValue states = chain.states.map!(s => encodeState(s)).array;

        return toJSON(&states, _pretty);
    }

private:
    JSONValue encodeState(State!T state)
    {
        JSONValue object = ["size": state.size.text];
        object["counters"] = "{ }".parseJSON;

        foreach(first; state.keys)
        {
            object["counters"][encodeKeys(first)] = encodeCounter(state.get(first));
        }

        return object;
    }

    JSONValue encodeCounter(Counter!T counter)
    {
        string[string] data;

        foreach(follow; counter.keys)
        {
            data[encodeKey(follow)] = counter.get(follow).text;
        }

        JSONValue object = data;
        return object;
    }

    string encodeKeys(T[] keys)
    {
        return "[%(%s,%)]".format(keys.map!(k => encodeKey(k)));
    }

    string encodeKey(T key)
    {
        static if(hasEncodeProperty!(T, string))
        {
            string encoded = key.encode;
        }
        else
        {
            string encoded = key.text;
        }

        return Base64.encode(encoded.map!(to!ubyte).array);
    }
}

@property
string toJson(T)(ref MarkovChain!T chain, bool pretty = false)
{
    return new JsonEncoder!T(pretty).encode(chain);
}
