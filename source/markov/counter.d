
module markov.counter;

import std.algorithm;
import std.random;
import std.traits;
import std.typecons;

struct Counter(T)
{
private:
    ulong[T] _counts;
    Nullable!ulong _total;

public:
    this(T follow)
    {
        _counts[follow] = 1;
    }

    bool contains(T follow)
    {
        return !!(follow in _counts);
    }

    @property
    bool empty()
    {
        return length == 0;
    }

    @property
    size_t length()
    {
        return _counts.length;
    }

    ulong peek(T follow)
    {
        auto ptr = follow in _counts;
        return ptr ? *ptr : 0;
    }

    void poke(T follow)
    {
        scope(exit) _total.nullify;
        auto ptr = follow in _counts;

        if(ptr !is null)
        {
            *ptr = *ptr + 1;
        }
        else
        {
            _counts[follow] = 1;
        }
    }

    @property
    T random()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            auto index = uniform(0, length);
            return _counts.keys[index];
        }
        else
        {
            return null;
        }
    }

    @property
    Nullable!T random()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!T result;

        if(!empty)
        {
            auto index = uniform(0, length);
            result = _counts.keys[index];
        }

        return result;
    }

    @property
    T select()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            auto result = uniform(0, total);

            foreach(value, count; _counts)
            {
                if(result < count)
                {
                    return value;
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

    @property
    Nullable!T select()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!T result;

        if(!empty)
        {
            auto needle = uniform(0, total);

            foreach(value, count; _counts)
            {
                if(needle < count)
                {
                    result = value;
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

    @property
    ulong total()
    {
        if(_total.isNull)
        {
            _total = _counts.values.sum;
        }

        return _total.get;
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
