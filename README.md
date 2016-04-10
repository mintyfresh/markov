# markov [![DUB](https://img.shields.io/dub/v/markov.svg)](http://code.dlang.org/packages/markov) [![DUB](https://img.shields.io/dub/l/markov.svg)](http://code.dlang.org/packages/markov)
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

Simple functions for serializing markov chains into JSON and binary are included.

```d
void main()
{
    // . . .

    // Serialize the markov chain into JSON.
    string json = chain.encodeJSON;

    // Serialize the markov chain into a binary format.
    ubyte[] binary = chain.encodeBinary;

    // Unserialize the JSON-encoded markov chain.
    MarkovChain!string decoded1 = json.decodeJSON!string;

    // Unserialize the binary-encoded markov chain.
    MarkovChain!string decoded2 = binary.decodeBinary!string;
}
```

In addition, helpers to store encoded data in files are also present.

```d
void main()
{
    // . . .

    // Write a markov chain to a file.
    chain.encodeJSON(File("markov", "w"));

    // Read a markov chain from a file.
    MarkovChain!string decoded = File("markov", "r").decodeJSON!string;
}
```

## License

MIT
