
module markov.state;

import std.exception;
import std.random;
import std.traits;
import std.typecons;

import markov.counter;

struct State(T)
{
private:
    size_t _size;
    Counter!T[Key] _counters;

    struct Key
    {
        T[] _key;

        bool opEquals(ref const Key other) const
        {
            return _key == other._key;
        }
    }

public:
    this(size_t size)
    {
        _size = enforce(size, "State size cannot be 0.");
    }

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

    @property
    bool empty()
    {
        return length == 0;
    }

    @property
    size_t length()
    {
        return _counters.length;
    }

    ulong peek(T[] first, T follow)
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
            _counters[Key(first)] = Counter!T(follow);
        }
    }

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

    @property
    Nullable!(Unqual!T)random()()
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
