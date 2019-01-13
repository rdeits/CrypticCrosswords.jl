* Generate anagrams which do not produce words
    * Pass the context to apply(), but add a default method which just uses it as a filter
    * For anagrams, implement apply() with context so that we can generate all matching anagrams for the given context

* Apply a word stemmer when checking word similarity

* More substring wordplay types

* Allow filler words between wordplay and definition

* Anagrams don't include non-stem forms (like "risked"). Should probably have a bigger word set than just the thesaurus keys.
