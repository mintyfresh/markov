
module markov.counter;

import std.algorithm;
import std.array;
import std.random;
import std.traits;
import std.typecons;

/++
 + Represents a set of counters for trailing (following) tokens in a markov state.
 ++/
struct Counter(T)
{
private:
    uint[Key] _counts;
    uint _total;

    /++
     + Wraps a token, providing normalized hashing and abstracting type qualifiers.
     ++/
    struct Key
    {
        T _key;

        /++
         + Returns the natural value of the token.
         ++/
        @property
        T value()
        {
            return _key;
        }

        /++
         + Returns the hash for a token.
         ++/
        hash_t toHash() const
        {
            static if(__traits(compiles, {
                T key = void;
                hash_t hash = key.toHash;
            }))
            {
                return _key.toHash;
            }
            else
            {
                return hashOf(_key);
            }
        }

        /++
         + Compares two tokens for equality.
         ++/
        bool opEquals(ref const Key other) const
        {
            return _key == other._key;
        }
    }

public:
    /++
     + Constructs a counter table with an initial token.
     ++/
    this(T follow)
    {
        poke(follow);
    }

    /++
     + Checks if the counter table contains a given token.
     ++/
    bool contains(T follow)
    {
        return !!(Key(follow) in _counts);
    }

    /++
     + Checks if the counter table is empty.
     ++/
    @property
    bool empty()
    {
        return length == 0;
    }

    /++
     + Returns the counter value for a token.
     ++/
    uint get(T follow)
    {
        return _counts[Key(follow)];
    }

    /++
     + Returns a list of tokens in the counter table.
     ++/
    @property
    T[] keys()
    {
        return _counts.keys.map!"a.value".array;
    }

    /++
     + Returns the length of the counter table.
     ++/
    @property
    size_t length()
    {
        return _counts.length;
    }

    /++
     + Returns the counter value for a token.
     + If the token doesn't exist, 0 is returned.
     ++/
    uint peek(T follow)
    {
        auto ptr = Key(follow) in _counts;
        return ptr ? *ptr : 0;
    }

    /++
     + Pokes a token in the counter table, incrementing its counter value.
     + If the token doesn't exist, it's created and assigned a counter of 1.
     ++/
    void poke(T follow)
    {
        scope(exit) _total = 0;
        auto ptr = Key(follow) in _counts;

        if(ptr !is null)
        {
            *ptr = *ptr + 1;
        }
        else
        {
            _counts[Key(follow)] = 1;
        }
    }

    /++
     + Returns a random token with equal distribution.
     + If the counter table is emtpy, null is returned instead.
     ++/
    @property
    T random()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            auto index = uniform(0, length);
            return _counts.keys[index].value;
        }
        else
        {
            return null;
        }
    }

    /++
     + Ditto
     ++/
    @property
    Nullable!(Unqual!T) random()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result;

        if(!empty)
        {
            auto index = uniform(0, length);
            result = _counts.keys[index].value;
        }

        return result;
    }

    /++
     + Rebuilds the associative arrays used by the counter table.
     ++/
    @property
    void rehash()
    {
        _counts.rehash;
    }

    /++
     + Returns a random token, distributed based on the counter values.
     + Specifically, a token with a higher counter is more likely to be chosen
     + than a token with a counter lower than it.
     + If the counter table is empty, null is returned instead.
     ++/
    @property
    T select()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            auto result = uniform(0, total);

            foreach(key, count; _counts)
            {
                if(result < count)
                {
                    return key.value;
                }
                else
                {
                    result -= count;
                }
            }

            // No return.
            assert(0);
        }
        else
        {
            return null;
        }
    }

    /++
     + Ditto
     ++/
    @property
    Nullable!(Unqual!T) select()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result;

        if(!empty)
        {
            auto needle = uniform(0, total);

            foreach(key, count; _counts)
            {
                if(needle < count)
                {
                    result = key.value;
                    return result;
                }
                else
                {
                    needle -= count;
                }
            }

            // No return.
            assert(0);
        }

        return result;
    }

    /++
     + Sets the counter value for a given token.
     ++/
    void set(T follow, uint count)
    {
        scope(exit) _total = 0;
        _counts[Key(follow)] = count;
    }

    /++
     + Returns the sum of all counters on all tokens. The value is cached once
     + it's been computed.
     ++/
    @property
    uint total()
    {
        if(_total == 0)
        {
            _total = _counts.values.sum;
        }

        return _total;
    }
}

unittest
{
    auto counter = Counter!string("1");

    assert(counter.empty == false);
    assert(counter.length == 1);
    assert(counter.total == 1);

    assert(counter.contains("1") == true);
    assert(counter.random == "1");
    assert(counter.select == "1");

    assert(counter.peek("1") == 1);

    counter.poke("1");
    assert(counter.peek("1") == 2);
    assert(counter.length == 1);
    assert(counter.total == 2);

    counter.poke("2");
    assert(counter.peek("1") == 2);
    assert(counter.peek("2") == 1);
    assert(counter.length == 2);
    assert(counter.total == 3);
}

unittest
{
    auto counter = Counter!int(1);

    assert(counter.empty == false);
    assert(counter.length == 1);
    assert(counter.total == 1);

    assert(counter.contains(1) == true);
    assert(counter.random == 1);
    assert(counter.select == 1);

    assert(counter.peek(1) == 1);

    counter.poke(1);
    assert(counter.peek(1) == 2);
    assert(counter.length == 1);
    assert(counter.total == 2);

    counter.poke(2);
    assert(counter.peek(1) == 2);
    assert(counter.peek(2) == 1);
    assert(counter.length == 2);
    assert(counter.total == 3);
}

unittest
{
    auto counter = Counter!(int[])([1]);

    assert(counter.empty == false);
    assert(counter.length == 1);
    assert(counter.total == 1);

    assert(counter.contains([1]) == true);
    assert(counter.random == [1]);
    assert(counter.select == [1]);

    assert(counter.peek([1]) == 1);

    counter.poke([1]);
    assert(counter.peek([1]) == 2);
    assert(counter.length == 1);
    assert(counter.total == 2);

    counter.poke([2]);
    assert(counter.peek([1]) == 2);
    assert(counter.peek([2]) == 1);
    assert(counter.length == 2);
    assert(counter.total == 3);
}

unittest
{
    auto counter = Counter!(const(int[]))([1]);

    assert(counter.empty == false);
    assert(counter.length == 1);
    assert(counter.total == 1);

    assert(counter.contains([1]) == true);
    assert(counter.random == [1]);
    assert(counter.select == [1]);

    assert(counter.peek([1]) == 1);

    counter.poke([1]);
    assert(counter.peek([1]) == 2);
    assert(counter.length == 1);
    assert(counter.total == 2);

    counter.poke([2]);
    assert(counter.peek([1]) == 2);
    assert(counter.peek([2]) == 1);
    assert(counter.length == 2);
    assert(counter.total == 3);
}

unittest
{
    auto counter = Counter!(immutable(int[]))([1]);

    assert(counter.empty == false);
    assert(counter.length == 1);
    assert(counter.total == 1);

    assert(counter.contains([1]) == true);
    assert(counter.random == [1]);
    assert(counter.select == [1]);

    assert(counter.peek([1]) == 1);

    counter.poke([1]);
    assert(counter.peek([1]) == 2);
    assert(counter.length == 1);
    assert(counter.total == 2);

    counter.poke([2]);
    assert(counter.peek([1]) == 2);
    assert(counter.peek([2]) == 1);
    assert(counter.length == 2);
    assert(counter.total == 3);
}
