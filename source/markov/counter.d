
module markov.counter;

import std.algorithm;
import std.random;
import std.traits;
import std.typecons;

struct Counter(T)
{
private:
    uint[Key] _counts;
    uint _total;

    struct Key
    {
        T _key;

        @property
        T value()
        {
            return _key;
        }

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

        bool opEquals(ref const Key other) const
        {
            return _key == other._key;
        }
    }

public:
    this(T follow)
    {
        poke(follow);
    }

    bool contains(T follow)
    {
        return !!(Key(follow) in _counts);
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

    uint peek(T follow)
    {
        auto ptr = Key(follow) in _counts;
        return ptr ? *ptr : 0;
    }

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

    @property
    Nullable!(Unqual!T)  random()()
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

    @property
    void rehash()
    {
        _counts.rehash;
    }

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
