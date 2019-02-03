abstract type GrammaticalSymbol end

struct Token <: GrammaticalSymbol end
struct Phrase <: GrammaticalSymbol end
struct Clue <: GrammaticalSymbol end
struct Definition <: GrammaticalSymbol end

abstract type AbstractWordplay <: GrammaticalSymbol end
struct JoinedPhrase <: AbstractWordplay end
struct Filler <: AbstractWordplay end
struct Abbreviation <: AbstractWordplay end
struct Reversal <: AbstractWordplay end
struct Anagram <: AbstractWordplay end
struct Substring <: AbstractWordplay end
struct Insertion <: AbstractWordplay end
struct Straddle <: AbstractWordplay end
struct Literal <: AbstractWordplay end
struct Synonym <: AbstractWordplay end
struct Wordplay <: AbstractWordplay end

struct InnerInsertion <: GrammaticalSymbol end
struct OuterInsertion <: GrammaticalSymbol end
struct Initials <: GrammaticalSymbol end

abstract type AbstractIndicator <: GrammaticalSymbol end
struct AnagramIndicator <: AbstractIndicator end
struct ReverseIndicator <: AbstractIndicator end
struct InsertABIndicator <: AbstractIndicator end
struct InsertBAIndicator <: AbstractIndicator end
struct InitialsIndicator <: AbstractIndicator end
struct TailIndicator <: AbstractIndicator end
struct StraddleIndicator <: AbstractIndicator end
struct InitialSubstringIndicator <: AbstractIndicator end
struct FinalSubstringIndicator <: AbstractIndicator end

const Rule = Pair{<:GrammaticalSymbol, <:Tuple{Vararg{GrammaticalSymbol}}}
lhs(r::Pair) = first(r)
rhs(r::Pair) = last(r)

macro apply_by_reversing(Head, Args...)
    quote
        $(esc(:apply!))(out, H::$(esc(Head)), A::Tuple{$(esc.(Args)...)}, words) = $(esc(:apply!))(out, H, reverse(A), reverse(words))
    end
end

function cryptics_rules()
    Rule[
        Phrase() => (Token(),),
        Phrase() => (Phrase(), Token()),

        JoinedPhrase() => (Phrase(),),

        AnagramIndicator() => (Phrase(),),
        Anagram() => (AnagramIndicator(), JoinedPhrase()),
        Anagram() => (JoinedPhrase(), AnagramIndicator()),

        ReverseIndicator() => (Phrase(),),
        Reversal() => (ReverseIndicator(), JoinedPhrase()),
        Reversal() => (JoinedPhrase(), ReverseIndicator()),

        InitialsIndicator() => (Phrase(),),
        Initials() => (Token(),),
        Initials() => (Initials(), Token()),
        Substring() => (InitialsIndicator(), Initials()),
        Substring() => (Initials(), InitialsIndicator()),

        # HeadIndicator() => (Phrase(),),
        # Substring() => (HeadIndicator(), Phrase()),
        # Substring() => (Phrase(), HeadIndicator()),
        # TailIndicator() => (Phrase(),),
        # Substring() => (TailIndicator(), Phrase()),
        # Substring() => (Phrase(), TailIndicator()),

        InsertABIndicator() => (Phrase(),),
        InsertBAIndicator() => (Phrase(),),
        InnerInsertion() => (Synonym(),),
        InnerInsertion() => (JoinedPhrase(),),
        InnerInsertion() => (Substring(),),
        OuterInsertion() => (Synonym(),),
        OuterInsertion() => (JoinedPhrase(),),
        Insertion() => (InsertABIndicator(), InnerInsertion(), OuterInsertion()),
        Insertion() => (InnerInsertion(), InsertABIndicator(), OuterInsertion()),
        Insertion() => (InnerInsertion(), OuterInsertion(), InsertABIndicator()),
        Insertion() => (InsertBAIndicator(), OuterInsertion(), InnerInsertion()),
        Insertion() => (OuterInsertion(), InsertBAIndicator(), InnerInsertion()),
        Insertion() => (OuterInsertion(), InnerInsertion(), InsertBAIndicator()),

        StraddleIndicator() => (Phrase(),),
        Straddle() => (StraddleIndicator(), Phrase()),
        Straddle() => (Phrase(), StraddleIndicator()),

        Literal() => (Token(),),
        Abbreviation() => (Phrase(),),
        Filler() => (Token(),),
        Synonym() => (Phrase(),),

        InitialSubstringIndicator() => (Phrase(),),
        Substring() => (InitialSubstringIndicator(), Token()),
        Substring() => (Token(), InitialSubstringIndicator()),
        Substring() => (InitialSubstringIndicator(), Synonym()),
        Substring() => (Synonym(), InitialSubstringIndicator()),

        FinalSubstringIndicator() => (Phrase(),),
        Substring() => (FinalSubstringIndicator(), Token()),
        Substring() => (Token(), FinalSubstringIndicator()),
        Substring() => (FinalSubstringIndicator(), Synonym()),
        Substring() => (Synonym(), FinalSubstringIndicator()),

        Definition() => (Phrase(),),

        Wordplay() => (JoinedPhrase(),),
        Wordplay() => (Abbreviation(),),
        Wordplay() => (Reversal(),),
        Wordplay() => (Anagram(),),
        Wordplay() => (Substring(),),
        Wordplay() => (Insertion(),),
        Wordplay() => (Straddle(),),
        Wordplay() => (Literal(),),
        Wordplay() => (Synonym(),),
        Wordplay() => (Wordplay(), Wordplay()),
        Wordplay() => (Wordplay(), Filler(), Wordplay()),

        Clue() => (Wordplay(), Definition()),
        Clue() => (Definition(), Wordplay()),
        Clue() => (Wordplay(), Filler(), Definition()),
        Clue() => (Definition(), Filler(), Wordplay()),
    ]
end

# Fallback method for one-argument rules which just pass their argument
# through
apply!(out, ::GrammaticalSymbol, ::Tuple{GrammaticalSymbol}, (word,)) = push!(out, word)


apply!(out, ::JoinedPhrase, ::Tuple{Phrase}, (p,)) = push!(out, replace(p, ' ' => ""))

const MAX_PHRASE_LENGTH = 4

function apply!(out, ::Phrase, ::Tuple{Phrase, Token}, (phrase, token))
    if count(isequal(' '), phrase) < MAX_PHRASE_LENGTH - 1
        push!(out, string(phrase, " ", token))
    end
end

function apply!(out, ::Anagram, ::Tuple{AnagramIndicator, JoinedPhrase}, (indicator, phrase))
    key = join(sort(collect(phrase)))
    if key in keys(WORDS_BY_ANAGRAM)
        for word in WORDS_BY_ANAGRAM[key]
            if word != phrase
                push!(out, word)
            end
        end
    end
end
@apply_by_reversing Anagram JoinedPhrase AnagramIndicator

function apply!(out, ::Wordplay, ::Tuple{Wordplay, Filler, Wordplay}, (a, filler, b))
    apply!(out, Wordplay(), (Wordplay(), Wordplay()), (a, b))
end

function apply!(out, ::Wordplay, ::Tuple{Wordplay, Wordplay}, (a, b))
    if has_concatenation(PREFIXES, a, b)
        push!(out, string(a, b))
    end
end

apply!(out, ::Clue, ::Tuple{Wordplay, Definition}, (wordplay, definition)) = push!(out, wordplay)
@apply_by_reversing Clue Definition Wordplay

function apply!(out, ::Abbreviation, ::Tuple{Phrase}, (word,))
    if word in keys(ABBREVIATIONS)
        for abbrev in ABBREVIATIONS[word]
            push!(out, abbrev)
        end
    end
end

apply!(out, ::Filler, ::Tuple{Token}, (word,)) = push!(out, "")

apply!(out, ::Clue, ::Tuple{Wordplay, Filler, Definition}, (w, f, d)) = push!(out, w)
apply!(out, ::Clue, ::Tuple{Definition, Filler, Wordplay}, (d, f, w)) = push!(out, w)

apply!(out, ::Reversal, ::Tuple{ReverseIndicator, JoinedPhrase}, (indicator, word)) = push!(out, reverse(word))
@apply_by_reversing Reversal JoinedPhrase ReverseIndicator

apply!(out, ::Initials, ::Tuple{Token}, (word,)) = push!(out, string(first(word)))
function apply!(out, ::Initials, ::Tuple{Initials, Token}, (initials, token))
    next_letter = string(first(token))
    if has_concatenation(SUBSTRINGS, initials, next_letter)
        push!(out, string(initials, next_letter))
    end
end

apply!(out, ::Substring, ::Tuple{InitialsIndicator, Initials}, (indicator, initials)) = push!(out, initials)
@apply_by_reversing Substring Initials InitialsIndicator

apply!(out, ::Substring, ::Tuple{TailIndicator, Phrase}, (indicator, phrase)) = push!(out, join(last(word) for word in split(phrase)))
@apply_by_reversing Substring Phrase TailIndicator

function apply!(out, ::Synonym, ::Tuple{Phrase}, (word,))
    if word in keys(SYNONYMS[])
        for syn in SYNONYMS[][word]
            push!(out, syn)
        end
    end
end

function move_right!(buffer, start, stop)
    @boundscheck start >= 1 || throw(BoundsError())
    @boundscheck stop <= (length(buffer) - 1) || throw(BoundsError())
    @boundscheck start <= stop || throw(ArgumentError("start ($start) must be <= stop ($stop)"))

    swap = buffer[stop + 1]
    for i in stop:-1:start
        buffer[i + 1] = buffer[i]
    end
    buffer[start] = swap
end

"""
All insertions of a into b
"""
function insertions!(results, a, b)
    len_a = length(a)
    len_b = length(b)
    if len_a == 0 || len_b == 0
        return
    end
    buffer = Vector{Char}()
    sizehint!(buffer, len_a + len_b)
    for c in a
        push!(buffer, c)
    end
    for c in b
        push!(buffer, c)
    end
    for i in 1:(len_b - 1)
        move_right!(buffer, i, len_a + i - 1)
        if buffer in SUBSTRINGS
            push!(results, join(buffer))
        end
    end
end

apply!(out, ::Insertion, ::Tuple{InsertABIndicator, Any, Any}, (indicator, a, b)) = insertions!(out, a, b)

apply!(out, ::Insertion, ::Tuple{Any, InsertABIndicator, Any}, (a, indicator, b)) = insertions!(out, a, b)

apply!(out, ::Insertion, ::Tuple{Any, Any, InsertABIndicator}, (a, b, indicator)) = insertions!(out, a, b)

apply!(out, ::Insertion, ::Tuple{InsertBAIndicator, Any, Any}, (indicator, b, a)) = insertions!(out, a, b)

apply!(out, ::Insertion, ::Tuple{Any, InsertBAIndicator, Any}, (b, indicator, a)) = insertions!(out, a, b)

apply!(out, ::Insertion, ::Tuple{Any, Any, InsertBAIndicator}, (b, a, indicator)) = insertions!(out, a, b)

function straddling_words!(results, phrase, condition=is_word)
    combined = replace(phrase, ' ' => "")
    first_space = findfirst(isequal(' '), phrase)
    if first_space === nothing
        return results
    end
    first_word_length = first_space - 1
    last_space = findlast(isequal(' '), phrase)
    last_word_length = length(phrase) - last_space

    for stop_index in (length(combined) - last_word_length + 1):(length(combined) - 1)
        for start_index in 2:first_word_length
            candidate = combined[start_index:stop_index]
            if condition(candidate)
                push!(results, candidate)
            end
        end
    end
end


apply!(out, ::Straddle, ::Tuple{StraddleIndicator, Phrase}, (indicator, phrase)) = straddling_words!(out, phrase)
@apply_by_reversing Straddle Phrase StraddleIndicator

function apply!(out, ::Substring, ::Tuple{InitialSubstringIndicator, Union{Token, Synonym}}, (indicator, phrase))
    combined = replace(phrase, ' ' => "")
    len = length(combined)
    for i in 2:3
        if len > i + 1
            push!(out, combined[1:i])
        end
    end
    if len > 4
        push!(out, combined[1:end-1])
    end
    if iseven(len)
        first_half = combined[1:(len ÷ 2)]
        if first_half ∉ out
            push!(out, first_half)
        end
    end
end
@apply_by_reversing Substring Union{Token, Synonym} InitialSubstringIndicator

function apply!(out, ::Substring, ::Tuple{FinalSubstringIndicator, Union{Token, Synonym}}, (indicator, phrase))
    combined = replace(phrase, ' ' => "")
    len = length(combined)
    if len > 2
        push!(out, combined[2:end])
    end
    if iseven(len)
        last_half = combined[(len ÷ 2 + 1):end]
        if last_half ∉ out
            push!(out, last_half)
        end
    end
end
@apply_by_reversing Substring Union{Token, Synonym} FinalSubstringIndicator
