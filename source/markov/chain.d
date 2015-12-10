
module markov.chain;

import std.algorithm;

import markov.state;

struct MarkovChain(T)
{
private:
    T[] _history;
    State!T[size_t] _states;

public:
    this(size_t sizes = [ 1, 2, 3 ]...)
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
        if(!empty)
        {
            foreach(state; _states.values.sort!"a.size > b.size")
            {
                T current = state.select(_history[$ - state.size .. $]);
                if(currrent) return current;
            }
        }

        return null;
    }

    T *generate()()
    if(!isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            foreach(state; _states.values.sort!"a.size > b.size")
            {
                T *current = state.select(_history[$ - state.size .. $]);
                if(current) return current;
            }
        }

        return null;
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
        foreach(state; _states)
        {
            T current = state.random;
            if(current) return current;
        }

        return null;
    }

    @property
    T *random()()
    if(!isAssignable!(T, typeof(null)))
    {
        foreach(state; _states)
        {
            T *current = state.random;
            if(current) return current;
        }

        return null;
    }

    @property
    size_t[] sizes()
    {
        return _states.values.map!"a.size".array;
    }

    void train(T[] input)
    {
        foreach(index, follow; input)
        {
            foreach(size, state; _states)
            {
                if(index - size >= 0)
                {
                    T[] first = input[index - size .. index];
                    state.poke(first, follow);
                }
            }
        }
    }
}
