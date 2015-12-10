# markov
A simple library that provides templated types for markov chains.

## Usage

```d
import std.stdio;

import markov;

void main()
{
    // Build states for 1, 2, and 3 leading elements.
    auto chain = MarkovChain!string(1, 2, 3);
    
    chain.train("foo", "bar", "foo");
    chain.train("bar", "foo", "bar");
    
    chain.seed("foo");
    
    foreach(i; 0 .. 10)
    {
        // bar foo bar foo bar . . .
        writeln(chain.generate);
    }
}
```

## License

MIT
