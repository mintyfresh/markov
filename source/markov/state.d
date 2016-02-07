
module markov.state;

import std.algorithm;
import std.array;
import std.exception;
import std.random;
import std.traits;
import std.typecons;

import markov.counter;

/++
 + Represents a table of token sequences bound to counter tables in a markov chain.
 ++/
struct State(T)
{
private:
    size_t _size;
    Counter!T[Key] _counters;

    /++
     + Wraps a token, abstracting type qualifiers.
     ++/
    struct Key
    {
        const T[] _key;

        /++
         + Returns the natural value of the token sequence.
         ++/
        @property
        T[] value()
        {
            return cast(T[]) _key.dup;
        }

        /++
         + Compares two token sequences for equality.
         ++/
        bool opEquals(ref const Key other) const
        {
            return _key == other._key;
        }
    }

public:
    @disable
    this();

    /++
     + Constructs a markov state with the given size.
     + The size must be greater than 0.
     ++/
    this(size_t size)
    {
        _size = enforce(size, "State size cannot be 0.");
    }

    /++
     + Checks if a counter table exists in the markov state.
     ++/
    bool contains(T[] first)
    {
        if(first.length == size)
        {
            return !!(Key(first) in _counters);
        }
        else
        {
            return false;
        }
    }

    /++
     + Checks if a token exists in a counter table in the markov state.
     ++/
    bool contains(T[] first, T follow)
    {
        if(first.length == size)
        {
            auto ptr = Key(first) in _counters;
            return ptr ? ptr.contains(follow) : false;
        }
        else
        {
            return false;
        }
    }

    /++
     + Checks if the markov state is empty.
     ++/
    @property
    bool empty()
    {
        return length == 0;
    }

    /++
     + Returns the counter table that corresponds to the token sequence.
     ++/
    Counter!T get(T[] first)
    {
        return _counters[Key(first)];
    }

    /++
     + Returns a list of token sequences in the counter table.
     ++/
    @property
    T[][] keys()
    {
        return _counters.keys.map!"a.value".array;
    }

    /++
     + Returns the length of the markov state.
     ++/
    @property
    size_t length()
    {
        return _counters.length;
    }

    /++
     + Return the counter value of a token, from the counter table that
     + corresponds to the given token sequence.
     + If the token doesn't exist in the counter table, of the leading sequence
     + doesn't exist in the markov state, or the length of the sequence doesn't
     + match the size of the markov state, 0 is returned instead.
     ++/
    uint peek(T[] first, T follow)
    {
        if(first.length == size)
        {
            auto ptr = Key(first) in _counters;
            return ptr ? ptr.peek(follow) : 0;
        }
        else
        {
            return 0;
        }
    }

    /++
     + Pokes a token in the counter table that corresponds to the given leading
     + sequence of tokens, incrementing its counter value.
     + If the token counter have an entry in the counter table, it is created
     + and assigned a value of 1, and if no counter table exists for the leading
     + token sequence, one is created as well.
     + The length of the token sequence must match the size of the markov state.
     ++/
    void poke(T[] first, T follow)
    {
        // Ensure that first length is equal to this state's size.
        enforce(first.length == size, "Length of input doesn't match size.");

        auto ptr = Key(first) in _counters;

        if(ptr !is null)
        {
            ptr.poke(follow);
        }
        else
        {
            Counter!T counter;
            counter.poke(follow);

            _counters[Key(first)] = counter;
        }
    }

    /++
     + Returns a random token from a random counter table.
     + If either the markov state or the counter table is empty,
     + null is returned instead.
     ++/
    @property
    T random()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            auto index = uniform(0, length);
            return _counters.values[index].random;
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
            return _counters.values[index].random;
        }

        return result;
    }

    /++
     + Rebuilds the associative arrays used by the markov table.
     +
     + Params:
     +   deep = If true, all the counter tables are rebuilt as well.
     ++/
    @property
    void rehash(bool deep = false)
    {
        _counters.rehash;

        if(deep)
        {
            foreach(ref counter; _counters)
            {
                counter.rehash;
            }
        }
    }

    /++
     + Returns a random token that might follow the given sequence of tokens
     + based on the markov state and the counter table that corresponds to the
     + token sequence.
     + If either the markov state of the corresponding counter table is empty,
     + or the token sequence doesn't have a counter table assigned to it,
     + null is returned instead.
     ++/
    @property
    T select()(T[] first)
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            auto ptr = Key(first) in _counters;
            return ptr ? ptr.select : null;
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
    Nullable!(Unqual!T) select()(T[] first)
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result;

        if(!empty)
        {
            auto ptr = Key(first) in _counters;
            if(ptr) return ptr.select;
        }

        return result;
    }

    /++
     + Sets the counter table for a given sequence of tokens.
     ++/
    void set(T[] first, Counter!T counter)
    {
        _counters[Key(first)] = counter;
    }

    /++
     + Returns the size of the markov state.
     ++/
    @property
    size_t size()
    {
        return _size;
    }
}

unittest
{
    try
    {
        auto state = State!string(0);
        assert(0);
    }
    catch(Exception)
    {
        // Expected result.
    }
}

unittest
{
    try
    {
        auto state = State!string(1);
        state.poke(["1", "2"], "3");
        assert(0);
    }
    catch(Exception)
    {
        // Expected result.
    }
}

unittest
{
    auto state = State!string(1);

    assert(state.empty == true);
    assert(state.length == 0);
    assert(state.size == 1);

    assert(state.random is null);
    assert(state.select(["1"]) is null);
    assert(state.peek(["1"], "2") == 0);

    state.poke(["1"], "2");
    assert(state.empty == false);
    assert(state.length == 1);
    assert(state.size == 1);

    assert(state.random == "2");
    assert(state.select(["1"]) == "2");
    assert(state.peek(["1"], "2") == 1);

    state.poke(["1"], "2");
    assert(state.peek(["1"], "2") == 2);
    assert(state.peek(["1"], "3") == 0);

    state.poke(["1"], "3");
    assert(state.length == 1);
    assert(state.peek(["1"], "2") == 2);
    assert(state.peek(["1"], "3") == 1);
}

unittest
{
    auto state = State!int(1);

    assert(state.empty == true);
    assert(state.length == 0);
    assert(state.size == 1);

    assert(state.random.isNull);
    assert(state.select([1]).isNull);
    assert(state.peek([1], 2) == 0);

    state.poke([1], 2);
    assert(state.empty == false);
    assert(state.length == 1);
    assert(state.size == 1);

    assert(state.random == 2);
    assert(state.select([1]) == 2);
    assert(state.peek([1], 2) == 1);

    state.poke([1], 2);
    assert(state.peek([1], 2) == 2);
    assert(state.peek([1], 3) == 0);

    state.poke([1], 3);
    assert(state.length == 1);
    assert(state.peek([1], 2) == 2);
    assert(state.peek([1], 3) == 1);
}

unittest
{
    auto state = State!(int[])(1);

    assert(state.empty == true);
    assert(state.length == 0);
    assert(state.size == 1);

    assert(state.random is null);
    assert(state.select([[1]]) is null);
    assert(state.peek([[1]], [2]) == 0);

    state.poke([[1]], [2]);
    assert(state.empty == false);
    assert(state.length == 1);
    assert(state.size == 1);

    assert(state.random == [2]);
    assert(state.select([[1]]) == [2]);
    assert(state.peek([[1]], [2]) == 1);

    state.poke([[1]], [2]);
    assert(state.peek([[1]], [2]) == 2);
    assert(state.peek([[1]], [3]) == 0);

    state.poke([[1]], [3]);
    assert(state.length == 1);
    assert(state.peek([[1]], [2]) == 2);
    assert(state.peek([[1]], [3]) == 1);
}

unittest
{
    auto state = State!(const(int[]))(1);

    assert(state.empty == true);
    assert(state.length == 0);
    assert(state.size == 1);

    assert(state.random.isNull);
    assert(state.select([[1]]).isNull);
    assert(state.peek([[1]], [2]) == 0);

    state.poke([[1]], [2]);
    assert(state.empty == false);
    assert(state.length == 1);
    assert(state.size == 1);

    assert(state.random == [2]);
    assert(state.select([[1]]) == [2]);
    assert(state.peek([[1]], [2]) == 1);

    state.poke([[1]], [2]);
    assert(state.peek([[1]], [2]) == 2);
    assert(state.peek([[1]], [3]) == 0);

    state.poke([[1]], [3]);
    assert(state.length == 1);
    assert(state.peek([[1]], [2]) == 2);
    assert(state.peek([[1]], [3]) == 1);
}

unittest
{
    auto state = State!(immutable(int[]))(1);

    assert(state.empty == true);
    assert(state.length == 0);
    assert(state.size == 1);

    assert(state.random.isNull);
    assert(state.select([[1]]).isNull);
    assert(state.peek([[1]], [2]) == 0);

    state.poke([[1]], [2]);
    assert(state.empty == false);
    assert(state.length == 1);
    assert(state.size == 1);

    assert(state.random == [2]);
    assert(state.select([[1]]) == [2]);
    assert(state.peek([[1]], [2]) == 1);

    state.poke([[1]], [2]);
    assert(state.peek([[1]], [2]) == 2);
    assert(state.peek([[1]], [3]) == 0);

    state.poke([[1]], [3]);
    assert(state.length == 1);
    assert(state.peek([[1]], [2]) == 2);
    assert(state.peek([[1]], [3]) == 1);
}
