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
struct ReversalIndicator <: AbstractIndicator end
struct InsertABIndicator <: AbstractIndicator end
struct InsertBAIndicator <: AbstractIndicator end
struct InitialsIndicator <: AbstractIndicator end
struct TailIndicator <: AbstractIndicator end
struct StraddleIndicator <: AbstractIndicator end
struct InitialSubstringIndicator <: AbstractIndicator end
struct FinalSubstringIndicator <: AbstractIndicator end

struct Rule <: AbstractRule{Symbol}
    inner::Pair{GrammaticalSymbol, Tuple{Vararg{GrammaticalSymbol}}}
    id::Pair{Symbol, Vector{Symbol}}
    score::Float64
end

_name(x) = typeof(x).name.name
Rule(p::Pair, s::Real) = Rule(p, _name(lhs(p)) => collect(_name.(rhs(p))), s)
Base.convert(::Type{Rule}, p::Tuple{Pair, Real}) = Rule(p...)

id(r::Rule) = r.id
inner(r::Rule) = r.inner
ChartParsers.lhs(r::Rule) = lhs(id(r))
ChartParsers.rhs(r::Rule) = rhs(id(r))
ChartParsers.score(r::Rule) = r.score

# lhs(r::Pair) = first(r)
# rhs(r::Pair) = last(r)


macro apply_by_reversing(Head, Args...)
    quote
        $(esc(:apply!))(out, H::$(esc(Head)), A::Tuple{$(esc.(Args)...)}, words) = $(esc(:apply!))(out, H, reverse(A), reverse(words))
    end
end

struct CrypticsGrammar <: AbstractGrammar{Rule}
    productions::Vector{Rule}
end

ChartParsers.productions(g::CrypticsGrammar) = g.productions
ChartParsers.start_symbol(g::CrypticsGrammar) = _name(Clue())

function weight(phrase::AbstractString, candidate::GrammaticalSymbol, indicators)
    known_phrases = get(indicators, candidate, Set{String}())
    if phrase in known_phrases
        100
    elseif any(w -> w in known_phrases, split(phrase))
        1
    elseif candidate ∈ (Literal(), Phrase(), Token())
        0.1
    else
        0.01
    end
end

function candidates(start, stop)
    result = GrammaticalSymbol[
        Literal()
    ]
    if stop - start < 4
        append!(result, [
            Phrase(),
            AnagramIndicator(),
            InitialsIndicator(),
            InitialSubstringIndicator(),
            FinalSubstringIndicator(),
            ReversalIndicator(),
            InsertABIndicator(),
            InsertBAIndicator(),
        ])
    end
    if stop == start
        append!(result, [
            Filler(),
            Token(),
        ])
    end
    result
end

function ChartParsers.terminal_productions(g::CrypticsGrammar, tokens)
    weights = Vector{Tuple{UnitRange{Int}, Float64}}()
    for start in 1:length(tokens)
        for stop in start:length(tokens)
            phrase = join(tokens[start:stop], ' ')
            for candidate in candidates(start, stop)
                w = weight(phrase, candidate, CACHE[].indicators)
                push!(weights, (start:stop, w))
            end
        end
    end

    result = Arc{Rule}[]
    for start in 1:length(tokens)
        for stop in start:length(tokens)
            phrase = join(tokens[start:stop], ' ')
            for candidate in candidates(start, stop)
                w = weight(phrase, candidate, CACHE[].indicators)
                displacement = sum(weights) do (range, weight)
                    if !isempty(intersect(range, start:stop))
                        weight
                    else
                        0.0
                    end
                end
                p = w / displacement
                push!(result, Arc{Rule}(start - 1, stop, Rule(candidate => (Token(),), p), [phrase], p))
            end
        end
    end
    result
end

function CrypticsGrammar()
    CrypticsGrammar(Rule[

        (JoinedPhrase() => (Literal(),), 1),

        (Anagram() => (AnagramIndicator(), JoinedPhrase()), 0.5),
        (Anagram() => (JoinedPhrase(), AnagramIndicator()), 0.5),

        (Reversal() => (ReversalIndicator(), JoinedPhrase()), 0.25),
        (Reversal() => (ReversalIndicator(), Synonym()), 0.25),
        (Reversal() => (JoinedPhrase(), ReversalIndicator()), 0.25),
        (Reversal() => (Synonym(), ReversalIndicator()), 0.25),

        # InitialsIndicator() => (Phrase(),),
        # Initials() => (Initials(), Literal()),

        # (InsertABIndicator() => (Phrase(),), 1.0),
        # (InsertBAIndicator() => (Phrase(),), 1.0),
        (InnerInsertion() => (Synonym(),), 1/4),
        (InnerInsertion() => (JoinedPhrase(),), 1/4),
        (InnerInsertion() => (Substring(),), 1/4),
        (InnerInsertion() => (Reversal(),), 1/4),
        (OuterInsertion() => (Synonym(),), 1/3),
        (OuterInsertion() => (Abbreviation(),), 1/3),
        (OuterInsertion() => (JoinedPhrase(),), 1/3),
        # Insertion() => (InsertABIndicator(), InnerInsertion(), OuterInsertion()),
        (Insertion() => (InnerInsertion(), InsertABIndicator(), OuterInsertion()), 0.5),
        # Insertion() => (InnerInsertion(), OuterInsertion(), InsertABIndicator()),
        # Insertion() => (InsertBAIndicator(), OuterInsertion(), InnerInsertion()),
        (Insertion() => (OuterInsertion(), InsertBAIndicator(), InnerInsertion()), 0.5),
        # Insertion() => (OuterInsertion(), InnerInsertion(), InsertBAIndicator()),

        (StraddleIndicator() => (Phrase(),), 1.0),
        (Straddle() => (StraddleIndicator(), Literal()), 0.5),
        (Straddle() => (Literal(), StraddleIndicator()), 0.5),

        # Literal() => (Token(),),
        (Abbreviation() => (Phrase(),), 1.0),
        # Filler() => (Token(),),
        (Synonym() => (Phrase(),), 1.0),

        (Initials() => (Literal(),), 1),
        (InitialSubstringIndicator() => (Phrase(),), 1.0),

        (Substring() => (InitialsIndicator(), Initials()), 1/6),
        (Substring() => (Initials(), InitialsIndicator()), 1/6),
        (Substring() => (InitialSubstringIndicator(), Token()), 1/6),
        (Substring() => (Token(), InitialSubstringIndicator()), 1/6),
        (Substring() => (InitialSubstringIndicator(), Synonym()), 1/6),
        (Substring() => (Synonym(), InitialSubstringIndicator()), 1/6),

        # FinalSubstringIndicator() => (Phrase(),),
        # Substring() => (FinalSubstringIndicator(), Literal()),
        # Substring() => (Literal(), FinalSubstringIndicator()),
        # Substring() => (FinalSubstringIndicator(), Synonym()),
        # Substring() => (Synonym(), FinalSubstringIndicator()),

        (Definition() => (Phrase(),), 1),

        (Wordplay() => (Literal(),), 1/18),
        (Wordplay() => (Abbreviation(),), 1/18),
        (Wordplay() => (Reversal(),), 1/18),
        (Wordplay() => (Anagram(),), 1/18),
        (Wordplay() => (Substring(),), 1/18),
        (Wordplay() => (Insertion(),), 1/18),
        (Wordplay() => (Straddle(),), 1/18),
        (Wordplay() => (Synonym(),), 1/18),
        (Wordplay() => (Wordplay(), Filler(), Wordplay()), 1/18),
        (Wordplay() => (Wordplay(), Wordplay()), 1/2),

        (Clue() => (Wordplay(), Definition()), 1/4),
        (Clue() => (Definition(), Wordplay()), 1/4),
        (Clue() => (Wordplay(), Filler(), Definition()), 1/4),
        (Clue() => (Definition(), Filler(), Wordplay()), 1/4),
    ])
end

# Fallback method for one-argument rules which just pass their argument
# through
apply!(out, ::GrammaticalSymbol, ::Tuple{GrammaticalSymbol}, (word,)) = push!(out, word)

apply!(out, ::JoinedPhrase, ::Tuple{Literal}, (p,)) = push!(out, replace(p, ' ' => ""))

function apply!(out, ::Anagram, ::Tuple{AnagramIndicator, JoinedPhrase}, (indicator, phrase))
    key = join(sort(collect(phrase)))
    if key in keys(CACHE[].words_by_anagram)
        for word in CACHE[].words_by_anagram[key]
            if word != phrase
                push!(out, word)
            end
        end
    end
end
@apply_by_reversing Anagram JoinedPhrase AnagramIndicator

function apply(head::Wordplay, args::Tuple{Wordplay, Filler, Wordplay}, (w1, filler, w2))
    apply(head, (Wordplay(), Wordplay()), (w1, w2))
end

function apply!(out, ::Wordplay, ::Tuple{Wordplay, Wordplay}, (w1, w2))
    h = CACHE[].prefixes[w1]
    if h !== nothing
        if has_concatenation(CACHE[].prefixes, h, w2)
            push!(out, string(w1, w2))
        end
    end
end

apply!(out, ::Wordplay, ::Tuple{Wordplay, Filler, Wordplay}, (w1, _, w2)) =
    apply!(out, Wordplay(), (Wordplay(), Wordplay()), (w1, w2))

# function apply(head::Wordplay, args::Tuple{Wordplay, Wordplay}, (words1, words2))
#     outputs = Vector{String}()
#     for w1 in words1
#         h = CACHE[].prefixes[w1]
#         if h !== nothing
#             for w2 in words2
#                 if has_concatenation(CACHE[].prefixes, h, w2)
#                     push!(outputs, string(w1, w2))
#                 end
#             end
#         end
#     end
#     unique!(outputs)
#     outputs
# end

apply!(out, ::Clue, ::Tuple{Wordplay, Definition}, (w, d)) = push!(out, w)
@apply_by_reversing Clue Definition Wordplay

# apply(head::Clue, args::Tuple{Wordplay, Definition}, (w, d)) = w
# apply(head::Clue, args::Tuple{Definition, Wordplay}, (d, w)) = w

function apply!(out, ::Abbreviation, ::Tuple{Phrase}, (word,))
    if word in keys(CACHE[].abbreviations)
        for abbrev in CACHE[].abbreviations[word]
            push!(out, abbrev)
        end
    end
end

apply!(out, ::Filler, ::Tuple{Token}, (word,)) = push!(out, "")

apply!(out, ::Clue, ::Tuple{Wordplay, Filler, Definition}, (w, f, d)) = push!(out, w)
apply!(out, ::Clue, ::Tuple{Definition, Filler, Wordplay}, (d, f, w)) = push!(out, w)

apply!(out, ::Reversal, ::Tuple{ReversalIndicator, Any}, (indicator, word)) = push!(out, reverse(word))
@apply_by_reversing Reversal Any ReversalIndicator

function apply!(out, ::Initials, ::Tuple{Literal}, (phrase,))
    result = join(first(s) for s in split(phrase))
    if result in CACHE[].substrings
        push!(out, result)
    end
end
# apply!(out, ::Initials, ::Tuple{Token}, (word,)) = push!(out, string(first(word)))
# function apply!(out, ::Initials, ::Tuple{Initials, Token}, (initials, token))
#     next_letter = string(first(token))
#     if has_concatenation(CACHE[].substrings, initials, next_letter)
#         push!(out, string(initials, next_letter))
#     end
# end

apply!(out, ::Substring, ::Tuple{InitialsIndicator, Initials}, (indicator, initials)) = push!(out, initials)
@apply_by_reversing Substring Initials InitialsIndicator

apply!(out, ::Substring, ::Tuple{TailIndicator, Phrase}, (indicator, phrase)) = push!(out, join(last(word) for word in split(phrase)))
@apply_by_reversing Substring Phrase TailIndicator

function apply!(out, ::Synonym, ::Tuple{Phrase}, (word,))
    if word in keys(CACHE[].synonyms)
        for syn in CACHE[].synonyms[word]
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
function insertions!(results, buffer, a, b)
    len_a = length(a)
    len_b = length(b)
    if len_a == 0 || len_b == 0
        return
    end
    empty!(buffer)
    sizehint!(buffer, len_a + len_b)
    for c in a
        push!(buffer, c)
    end
    for c in b
        push!(buffer, c)
    end
    prefix_hash = zero(UInt)
    for i in 1:(len_b - 1)
        move_right!(buffer, i, len_a + i - 1)
        prefix_hash = hash(buffer[i], prefix_hash)
        valid_substring = true
        partial_hash = prefix_hash
        for j in (i + 1):(i + 1 + len_a)
            partial_hash = hash(buffer[j], partial_hash)
            if (partial_hash & CACHE[].substrings.mask) ∉ CACHE[].substrings.slots
                valid_substring = false
                break
            end
        end
        if !valid_substring
            break
        end
        for j in (i + 1 + len_a + 1):(len_a + len_b)
            partial_hash = hash(buffer[j], partial_hash)
            if (partial_hash & CACHE[].substrings.mask) ∉ CACHE[].substrings.slots
                valid_substring = false
                break
            end
        end
        if !valid_substring
            break
        end
        push!(results, join(buffer))
    end
end

function insertions(inner, outer)
    outputs = Set{String}()
    buffer = Vector{Char}()
    for w1 in inner
        for w2 in outer
            insertions!(outputs, buffer, w1, w2)
        end
    end
    outputs
end


apply(::Insertion, ::Tuple{InsertABIndicator, GrammaticalSymbol, GrammaticalSymbol}, (indicator, a, b)) = insertions(a, b)

apply(::Insertion, ::Tuple{GrammaticalSymbol, InsertABIndicator, GrammaticalSymbol}, (a, indicator, b)) = insertions(a, b)

apply(::Insertion, ::Tuple{GrammaticalSymbol, GrammaticalSymbol, InsertABIndicator}, (a, b, indicator)) = insertions(a, b)

apply(::Insertion, ::Tuple{InsertBAIndicator, GrammaticalSymbol, GrammaticalSymbol}, (indicator, b, a)) = insertions(a, b)

apply(::Insertion, ::Tuple{GrammaticalSymbol, InsertBAIndicator, GrammaticalSymbol}, (b, indicator, a)) = insertions(a, b)

apply(::Insertion, ::Tuple{GrammaticalSymbol, GrammaticalSymbol, InsertBAIndicator}, (b, a, indicator)) = insertions(a, b)

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


apply!(out, ::Straddle, ::Tuple{StraddleIndicator, Literal}, (indicator, phrase)) = straddling_words!(out, phrase)
@apply_by_reversing Straddle Literal StraddleIndicator

# TODO: inefficiently doing the replace() on already-joined phrases
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
