
module markov.state;

import std.exception;
import std.random;

import markov.counter;

struct State(T)
{
private:
    size_t _size;
    Counter!T[immutable(T[])] _counters;

public:
    this(size_t size)
    {
        _size = enforce(size, "State size cannot be 0.");
    }

    bool contains(T[] first)
    {
        if(first.length == size)
        {
            return !!(first in _counters);
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
            auto ptr = first in _counters;
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
            auto ptr = first in _counters;
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

    @property
    size_t size()
    {
        return _size;
    }
}
