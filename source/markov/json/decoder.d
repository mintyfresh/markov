
module markov.json.decoder;

import markov.chain;
import markov.counter;
import markov.serialize;
import markov.state;

import std.algorithm;
import std.array;
import std.conv;
import std.json;
import std.range;
import std.stdio;
import std.typecons;

struct JsonDecoder(T)
{
    MarkovChain!T decode(string input)
    {
        return MarkovChain!T(decodeStates(input.parseJSON));
    }

private:
    State!T[] decodeStates(JSONValue json)
    {
        return json.array.map!(state => decodeState(state)).array;
    }

    State!T decodeState(JSONValue json)
    {
        State!T state = State!T(json["size"].str.to!uint);

        foreach(first, counter; json["counters"].object)
        {
            state.set(decodeKeys(first), decodeCounter(counter));
        }

        return state;
    }

    Counter!T decodeCounter(JSONValue json)
    {
        Counter!T counter;

        foreach(follow, count; json.object)
        {
            counter.set(decodeKey(follow), count.str.to!uint);
        }

        return counter;
    }

    T[] decodeKeys(string keys)
    {
        return keys.to!(string[]).map!(k => decodeKey(k)).array;
    }

    T decodeKey(string key)
    {
        static if(hasDecodeProperty!(T, string))
        {
            return T.decode(key);
        }
        else
        {
            return key.to!T;
        }
    }
}

MarkovChain!T decodeJSON(T)(string encoded)
{
    JsonDecoder!T decoder;
    return decoder.decode(encoded);
}

MarkovChain!T decodeJSON(T, string format)(File input, size_t chunkSize = 4096)
{
    return input.byChunk(chunkSize).joiner.text.decodeJSON!T;
}

unittest
{
    auto chain1 = MarkovChain!string(1, 2, 3);
    chain1.train("a", "b", "c", "e", "b", "a", "b", "a", "c", "e", "d", "c", "b", "a");

    import markov.json.encoder;
    auto chain2 = chain1.encodeJSON.decodeJSON!string;

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
