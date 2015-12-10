
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

}
