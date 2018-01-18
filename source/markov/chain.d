
module markov.chain;

import std.algorithm;
import std.exception;
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

    /++
     + Constructs a markov chain with empty states of the given sizes.
     ++/
    this(size_t[] sizes...)
    {
        _history.length = sizes.reduce!max;

        foreach(size; sizes)
        {
            _states[size] = State!T(size);
        }
    }

    /++
     + Constructs a markov chain using a list of existing states.
     ++/
    this(State!T[] states...)
    {
        enforce(states.length, "Cannot construct markov chain with 0 states.");

        foreach(state; states)
        {
            _states[state.size] = state;
        }

        _history.length = _states.values.map!"a.size".reduce!max;
    }

    /++
     + Checks if all of the markov chain's states are empty.
     ++/
    @property
    bool empty()
    {
        return _states.values.all!"a.empty";
    }

    /++
     + Trains the markov chain with a specific token sequence.
     ++/
    void feed(T[] first, T follow)
    {
        if(auto ptr = first.length in _states)
        {
            ptr.poke(first, follow);
        }
    }

    /++
     + Returns a token generated from the internal set of states, based on the
     + tokens previously generated. If no token can be produced, a random one is returned.
     ++/
    T generate()()
    if(isAssignable!(T, typeof(null)))
    {
        T result = select;
        return result ? result : random;
    }

    /++
     + Ditto
     ++/
    Nullable!(Unqual!T) generate()()
    if(!isAssignable!(T, typeof(null)))
    {
        Nullable!(Unqual!T) result = select;
        return !result.isNull ? result : random;
    }

    /++
     + Ditto, but produces an array of token with the given length.
     ++/
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

    /++
     + Ditto, but the array is given as an out-parameter.
     +
     + Returns:
     +   The number of tokens that were generated.
     ++/
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

    /++
     + Returns the number of states used by the markov chain.
     ++/
    @property
    size_t length()
    {
        return _states.length;
    }

    /++
     + Returns the lengths of the markov chain's states in an unknown order.
     ++/
    @property
    size_t[] lengths()
    {
        return _states.values.map!"a.length".array;
    }

    /++
     + Pushes a token to the markov chain's history buffer.
     ++/
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

    /++
     + Returns a randomly selected token from a randomly selected state.
     ++/
    @property
    T random()()
    if(isAssignable!(T, typeof(null)))
    {
        foreach(ref state; _states)
        {
            T current = state.random;
            if(current) {
                push(current);
                return current;
            }
        }

        return null;
    }

    /++
     + Ditto.
     ++/
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

    /++
     + Resets the markov chain's history buffer to an empty state.
     ++/
    @property
    void reset()
    {
        _history = T[].init;
        _history.length = sizes.reduce!max;
    }

    /++
     + Rehashes the associative arrays used in the markov chain's states.
     ++/
    @property
    void rehash()
    {
        foreach(ref state; _states)
        {
            state.rehash;
        }
    }

    /++
     + Pushes tokens to the markov chain's history buffer, seeding it for
     + subsequent calls to `select()` or `generate()`.
     +
     + Note that any tokens that would exceed the space of the history buffer
     + (which is equal to the size of the largest state) are discarded.
     ++/
    void seed(T[] seed...)
    {
        seed.retro.take(_history.length).retro.each!(f => push(f));
    }

    /++
     + Returns a token generated from the internal set of states, based on the
     + tokens previously generated. If no token can be produced, null is returned.
     ++/
    T select()()
    if(isAssignable!(T, typeof(null)))
    {
        if(!empty)
        {
            foreach(ref state; _states.values.sort!"a.size > b.size")
            {
                T current = state.select(_history[$ - state.size .. $]);
                if(current) {
                    push(current);
                    return current;
                }
            }
        }

        return null;
    }

    /++
     + Ditto
     ++/
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

    /++
     + Returns the sizes of the markov chain's states in an unknown order.
     ++/
    @property
    size_t[] sizes()
    {
        return _states.values.map!"a.size".array;
    }

    /++
     + Returns an array representing the markov chain's internal set of states.
     ++/
    @property
    State!T[] states()
    {
        return _states.values;
    }

    /++
     + Trains the markov chain from a sequence of input tokens.
     ++/
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
