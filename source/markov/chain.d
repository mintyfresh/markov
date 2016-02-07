
module markov.chain;

import std.algorithm;
import std.range;
import std.traits;
import std.typecons;

import markov.state;

struct MarkovChain(T)
{
private:
    T[] _history;
    State!T[size_t] _states;

public:
    @disable
    this();

    this(size_t[] sizes...)
    {
        _history.length = sizes.reduce!max;

        foreach(size; sizes)
        {
            _states[size] = State!T(size);
        }
    }

    this(State!T[] states...)
    {
        foreach(state; states)
        {
            _states[state.size] = state;
        }

        _history.length = _states.values.map!"a.size".reduce!max;
    }

    @property
    bool empty()
    {
        return _states.values.all!"a.empty";
    }

    void feed(T[] first, T follow)
    {
        auto ptr = first.length in _states;

        if(ptr !is null)
        {
            ptr.poke(first, follow);
        }
    }

    T generate()()
    if(isAssignable!(T, typeof(null)))
    {
        T result = select;
        return result ? result : random;
    }

    Nullable!(Unqual!T) generate()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result = select;
        return !result.isNull ? result : random;
    }

    Unqual!T[] generate()(size_t length)
    {
        Unqual!T[] output;

        if(generate(length, output) == length)
        {
            return output;
        }
        else
        {
            return null;
        }
    }

    size_t generate()(size_t length, out Unqual!T[] output)
    {
        output = new Unqual!T[length];

        foreach(i; 0 .. length)
        {
            auto result = generate;

            static if(isAssignable!(T, typeof(null)))
            {
                if(result is null)
                {
                    return i;
                }
                else
                {
                    output[i] = result;
                }
            }
            else
            {
                if(result.isNull)
                {
                    return i;
                }
                else
                {
                    output[i] = result.get;
                }
            }
        }

        return length;
    }

    @property
    size_t length()
    {
        return _states.length;
    }

    @property
    size_t[] lengths()
    {
        return _states.values.map!"a.length".array;
    }

    void push(T follow)
    {
        static if(isMutable!T)
        {
            copy(_history[1 .. $], _history[0 .. $ - 1]);
            _history[$ - 1] = follow;
        }
        else
        {
            _history = _history[1 .. $] ~ [ follow ];
        }
    }

    @property
    T random()()
    if(isAssignable!(T, typeof(null)))
    {
        foreach(ref state; _states)
        {
            T current = state.random;
            if(current) return push(current), current;
        }

        return null;
    }

    @property
    Nullable!(Unqual!T) random()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result;

        foreach(ref state; _states)
        {
            result = state.random;

            if(!result.isNull)
            {
                push(result.get);
                return result;
            }
        }

        return result;
    }

    @property
    void reset()
    {
        _history = T[].init;
    }

    @property
    void rehash()
    {
        foreach(ref state; _states)
        {
            state.rehash;
        }
    }

    void seed(T[] seed...)
    {
        seed.retro.take(_history.length).each!(f => push(f));
    }

    T select()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            foreach(ref state; _states.values.sort!"a.size > b.size")
            {
                T current = state.select(_history[$ - state.size .. $]);
                if(current) return push(current), current;
            }
        }

        return null;
    }

    Nullable!(Unqual!T) select()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result;

        if(!empty)
        {
            foreach(ref state; _states.values.sort!"a.size > b.size")
            {
                result = state.select(_history[$ - state.size .. $]);

                if(!result.isNull)
                {
                    push(result.get);
                    return result;
                }
            }
        }

        return result;
    }

    @property
    size_t[] sizes()
    {
        return _states.values.map!"a.size".array;
    }

    @property
    State!T[] states()
    {
        return _states.values;
    }

    void train(T[] input...)
    {
        foreach(index, follow; input)
        {
            foreach(size, ref state; _states)
            {
                if(size <= index)
                {
                    T[] first = input[index - size .. index];
                    state.poke(first, follow);
                }
            }
        }
    }
}

unittest
{
    auto chain = MarkovChain!(int[])(1);

    chain.train([1, 2, 3], [4, 5, 6], [7, 8, 9]);
}

unittest
{
    auto chain = MarkovChain!(immutable(int[]))(1);

    chain.train([1, 2, 3], [4, 5, 6], [7, 8, 9]);
}
