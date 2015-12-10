
module markov.state;

import std.random;

import markov.counter;

struct State(T)
{
private:
    Counter!T[immutable(T[])] _counters;

public:
    bool contains(T[] first)
    {
        return !!(first in _counters);
    }

    bool contains(T[] first, T follow)
    {
        auto ptr = first in _counters;
        return ptr ? ptr.contains(follow) : false;
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
        auto ptr = first in _counters;
        return ptr ? ptr.peek(follow) : 0;
    }

    void poke(T[] first, T follow)
    {
        auto ptr = first in _counters;

        if(ptr !is null)
        {
            ptr.poke(follow);
        }
        else
        {
            _counters[first.idup] = Counter!T(follow);
        }
    }

    @property
    auto random()
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
    auto select(T[] first)
    {
        if(!empty)
        {
            auto ptr = first in _counters;
            return ptr ? ptr.select : null;
        }
        else
        {
            return null;
        }
    }
}
