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

struct Rule
    inner::Pair{GrammaticalSymbol, Tuple{Vararg{GrammaticalSymbol}}}
    id::Pair{Symbol, Vector{Symbol}}
end

_name(x) = typeof(x).name.name
Rule(p::Pair) = Rule(p, _name(lhs(p)) => collect(_name.(rhs(p))))
Base.convert(::Type{Rule}, p::Pair) = Rule(p)

id(r::Rule) = r.id
inner(r::Rule) = r.inner
ChartParsers.lhs(r::Rule) = lhs(id(r))
ChartParsers.rhs(r::Rule) = rhs(id(r))
ChartParsers.chart_key(::Type{Rule}) = Symbol

# lhs(r::Pair) = first(r)
# rhs(r::Pair) = last(r)

@generated function _product(inputs, ::Val{N}) where {N}
    Expr(:call, :product, [:(inputs[$i]) for i in 1:N]...)
end

function apply(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs) where {N}
    outputs = Vector{String}()
    for input in _product(inputs, Val{N}())
        apply!(outputs, head, args, input)
    end
    unique!(outputs)
    outputs
end

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

function ChartParsers.terminal_productions(g::CrypticsGrammar, tokens)
    result = Arc{Rule}[]

    parts_of_speech = [
        Literal(),
        Filler(),
        Phrase(),
        AnagramIndicator(),
        ReversalIndicator(),
        InitialsIndicator(),
        # InsertABIndicator(),
        # InsertBAIndicator(),
        StraddleIndicator(),
        # InitialSubstringIndicator(),
        # FinalSubstringIndicator(),
    ]

    for start in 1:length(tokens)
        for stop in start .+ (0:2)
            if stop > length(tokens)
                continue
            end
            phrase = join(tokens[start:stop], ' ')
            known_parts_of_speech = get(INDICATORS, phrase, Vector{GrammaticalSymbol}())
            n_known = length(known_parts_of_speech)
            n_unknown = length(parts_of_speech) - n_known
            if n_known > 0
                p_known = 0.9
                p_unknown = 1 - p_known
            else
                p_unknown = 1.0
            end
            for part_of_speech in parts_of_speech
                if part_of_speech in known_parts_of_speech
                    p = p_known / n_known
                else
                    p = p_unknown / n_unknown
                end
                push!(result, Arc{Rule}(start - 1, stop, part_of_speech => (Token(),), [phrase], p))
            end
        end
    end
    result
end

function CrypticsGrammar()
    CrypticsGrammar(Rule[

        JoinedPhrase() => (Literal(),),

        Anagram() => (AnagramIndicator(), JoinedPhrase()),
        Anagram() => (JoinedPhrase(), AnagramIndicator()),

        Reversal() => (ReversalIndicator(), JoinedPhrase()),
        Reversal() => (ReversalIndicator(), Synonym()),
        Reversal() => (JoinedPhrase(), ReversalIndicator()),
        Reversal() => (Synonym(), ReversalIndicator()),

        # InitialsIndicator() => (Phrase(),),
        # Initials() => (Literal(),),
        # Initials() => (Initials(), Literal()),
        # Substring() => (InitialsIndicator(), Initials()),
        # Substring() => (Initials(), InitialsIndicator()),

        # InsertABIndicator() => (Phrase(),),
        # InsertBAIndicator() => (Phrase(),),
        # InnerInsertion() => (Synonym(),),
        # InnerInsertion() => (JoinedPhrase(),),
        # InnerInsertion() => (Substring(),),
        # OuterInsertion() => (Synonym(),),
        # OuterInsertion() => (JoinedPhrase(),),
        # Insertion() => (InsertABIndicator(), InnerInsertion(), OuterInsertion()),
        # Insertion() => (InnerInsertion(), InsertABIndicator(), OuterInsertion()),
        # Insertion() => (InnerInsertion(), OuterInsertion(), InsertABIndicator()),
        # Insertion() => (InsertBAIndicator(), OuterInsertion(), InnerInsertion()),
        # Insertion() => (OuterInsertion(), InsertBAIndicator(), InnerInsertion()),
        # Insertion() => (OuterInsertion(), InnerInsertion(), InsertBAIndicator()),

        # StraddleIndicator() => (Phrase(),),
        # Straddle() => (StraddleIndicator(), Phrase()),
        # Straddle() => (Phrase(), StraddleIndicator()),

        # Literal() => (Token(),),
        # Abbreviation() => (Phrase(),),
        # Filler() => (Token(),),
        # Synonym() => (Phrase(),),

        # InitialSubstringIndicator() => (Phrase(),),
        # Substring() => (InitialSubstringIndicator(), Literal()),
        # Substring() => (Literal(), InitialSubstringIndicator()),
        # Substring() => (InitialSubstringIndicator(), Synonym()),
        # Substring() => (Synonym(), InitialSubstringIndicator()),

        # FinalSubstringIndicator() => (Phrase(),),
        # Substring() => (FinalSubstringIndicator(), Literal()),
        # Substring() => (Literal(), FinalSubstringIndicator()),
        # Substring() => (FinalSubstringIndicator(), Synonym()),
        # Substring() => (Synonym(), FinalSubstringIndicator()),

        Definition() => (Phrase(),),

        # Wordplay() => (Literal(),),
        Wordplay() => (Abbreviation(),),
        Wordplay() => (Reversal(),),
        Wordplay() => (Anagram(),),
        # Wordplay() => (Substring(),),
        # Wordplay() => (Insertion(),),
        # Wordplay() => (Straddle(),),
        Wordplay() => (Synonym(),),
        # Wordplay() => (Wordplay(), Wordplay()),
        # Wordplay() => (Wordplay(), Filler(), Wordplay()),

        Clue() => (Wordplay(), Definition()),
        Clue() => (Definition(), Wordplay()),
        Clue() => (Wordplay(), Filler(), Definition()),
        Clue() => (Definition(), Filler(), Wordplay()),
    ])
end

# Fallback method for one-argument rules which just pass their argument
# through
apply!(out, ::GrammaticalSymbol, ::Tuple{GrammaticalSymbol}, (word,)) = push!(out, word)

apply!(out, ::JoinedPhrase, ::Tuple{Literal}, (p,)) = push!(out, replace(p, ' ' => ""))

# const MAX_PHRASE_LENGTH = 4

# function apply!(out, ::Phrase, ::Tuple{Phrase, Token}, (phrase, token))
#     if count(isequal(' '), phrase) < MAX_PHRASE_LENGTH - 1
#         push!(out, string(phrase, " ", token))
#     end
# end

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

function apply(head::Wordplay, args::Tuple{Wordplay, Filler, Wordplay}, (w1, filler, w2))
    apply(head, (Wordplay(), Wordplay()), (w1, w2))
end

function apply(head::Wordplay, args::Tuple{Wordplay, Wordplay}, (words1, words2))
    outputs = Vector{String}()
    for w1 in words1
        h = PREFIXES[w1]
        if h !== nothing
            for w2 in words2
                if has_concatenation(PREFIXES, h, w2)
                    push!(outputs, string(w1, w2))
                end
            end
        end
    end
    unique!(outputs)
    outputs
end

apply(head::Clue, args::Tuple{Wordplay, Definition}, (w, d)) = w
apply(head::Clue, args::Tuple{Definition, Wordplay}, (d, w)) = w

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

apply!(out, ::Reversal, ::Tuple{ReversalIndicator, Any}, (indicator, word)) = push!(out, reverse(word))
@apply_by_reversing Reversal Any ReversalIndicator

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
            if (partial_hash & SUBSTRINGS.mask) ∉ SUBSTRINGS.slots
                valid_substring = false
                break
            end
        end
        if !valid_substring
            break
        end
        for j in (i + 1 + len_a + 1):(len_a + len_b)
            partial_hash = hash(buffer[j], partial_hash)
            if (partial_hash & SUBSTRINGS.mask) ∉ SUBSTRINGS.slots
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
    outputs = Vector{String}()
    buffer = Vector{Char}()
    for w1 in inner
        for w2 in outer
            insertions!(outputs, buffer, w1, w2)
        end
    end
    unique!(outputs)
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
