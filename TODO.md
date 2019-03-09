* Generate anagrams which do not produce words
    * Pass the context to apply(), but add a default method which just uses it as a filter
    * For anagrams, implement apply() with context so that we can generate all matching anagrams for the given context

* More substring wordplay types

* Modify the generic chart parser's iteration interface:
    * Allow users to pass a check (or perhaps a score?) function which will be called on each new passive arc before it is added to the chart. By default, this just return 1, but we can use it to solve passive arcs and reject bogus ones, without needing to leave the parsing loop.

