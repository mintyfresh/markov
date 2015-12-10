
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

    @property
    bool empty()
    {
        return _states.values.all!"a.empty";
    }

    T generate()()
    if(isAssignable!(T, typeof(null)))
    {
        T result = select;
        return result ? result : random;
    }

    Nullable!T generate()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!T result = select;
        return !result.isNull ? result : random;
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
        copy(_history[1 .. $], _history[0 .. $ - 1]);
        _history[$ - 1] = follow;
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
    Nullable!T random()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!T result;

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

    Nullable!T select()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!T result;

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
