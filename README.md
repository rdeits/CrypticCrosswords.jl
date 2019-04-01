# CrypticCrosswords

[![Build Status](https://travis-ci.org/rdeits/CrypticCrosswords.jl.svg?branch=master)](https://travis-ci.org/rdeits/CrypticCrosswords.jl) [![codecov.io](http://codecov.io/github/rdeits/CrypticCrosswords.jl/coverage.svg?branch=master)](http://codecov.io/github/rdeits/CrypticCrosswords.jl?branch=master)

This package implements a fully automated solver for cryptic crossword clues in the Julia programming language. It works by building up a formal context-free grammar describing the way cryptic clues tend to be structured, then parsing the given clue using that grammar. Each valid parse is solved and checked to see if it produces a coherent wordplay and definition.

This package was adapted from my prior work in Python, which can still be found at https://github.com/rdeits/cryptics . The Julia implementation is significantly more powerful and flexible, as it also includes a custom chart parser (powered by [ChartParsers.jl](https://github.com/rdeits/ChartParsers.jl)) with support for probabilistic grammars. As a result, the Julia implementation can consistently handle longer clues which would have completely stumped the older Python version.

## Status: Experimental

This package is still under active development, and its interfaces will continue to evolve. For examples of basic usage, check out the the solver tests in [test/clues.jl](test/clues.jl) and the derivation tests in [test/derivations.jl](test/derivations.jl).

## Additional License Information

The SCOWL word list is:

> Copyright 2000-2016 by Kevin Atkinson
>
> Permission to use, copy, modify, distribute and sell these word
> lists, the associated scripts, the output created from the scripts,
> and its documentation for any purpose is hereby granted without fee,
> provided that the above copyright notice appears in all copies and
> that both that copyright notice and this permission notice appear in
> supporting documentation. Kevin Atkinson makes no representations
> about the suitability of this array for any purpose. It is provided
> "as is" without express or implied warranty.

