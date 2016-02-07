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

## Serialization

Simple functions for encoding/decoding markov chains to and from JSON are included.

```d
void main()
{
    // . . .

    // Serialize the markov chain into JSON.
    string encoded = chain.toJson;

    // Unserialize the JSON-encoded markov chain.
    MarkovChain!string decoded = encoded.toMarkovChain!string;
}
```

In addition, helpers to write encoded data to and from files are also included.

```d
void main()
{
    // . . .

    // Write a markov chain to a file.
    chain.writeJson(File("markov", "w"));

    // Read a markov chain from a file.
    MarkovChain!string decoded = File("markov", "r").readMarkovChain!string;
}
```

## License

MIT
