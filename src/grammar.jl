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

struct InsertArg <: GrammaticalSymbol end

abstract type AbstractIndicator <: GrammaticalSymbol end
struct AnagramIndicator <: AbstractIndicator end
struct ReverseIndicator <: AbstractIndicator end
struct InsertABIndicator <: AbstractIndicator end
struct InsertBAIndicator <: AbstractIndicator end
struct HeadIndicator <: AbstractIndicator end
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
        Reversal() => (ReverseIndicator(), Phrase()),
        Reversal() => (Phrase(), ReverseIndicator()),

        HeadIndicator() => (Phrase(),),
        Substring() => (HeadIndicator(), Phrase()),
        Substring() => (Phrase(), HeadIndicator()),

        TailIndicator() => (Phrase(),),
        Substring() => (TailIndicator(), Phrase()),
        Substring() => (Phrase(), TailIndicator()),

        InsertABIndicator() => (Phrase(),),
        InsertBAIndicator() => (Phrase(),),
        InsertArg() => (Synonym(),),
        InsertArg() => (JoinedPhrase(),),
        Insertion() => (InsertABIndicator(), InsertArg(), InsertArg()),
        Insertion() => (InsertArg(), InsertABIndicator(), InsertArg()),
        Insertion() => (InsertArg(), InsertArg(), InsertABIndicator()),
        Insertion() => (InsertBAIndicator(), InsertArg(), InsertArg()),
        Insertion() => (InsertArg(), InsertBAIndicator(), InsertArg()),
        Insertion() => (InsertArg(), InsertArg(), InsertBAIndicator()),

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

        Clue() => (Wordplay(), Definition()),
        Clue() => (Definition(), Wordplay()),
        Clue() => (Wordplay(), Filler(), Definition()),
        Clue() => (Definition(), Filler(), Wordplay()),
    ]
end

# propagate(context::Context, rule::Rule, inputs::AbstractVector) = propagate(context, lhs(rule), rhs(rule), inputs)

# Fallback methods for one-argument rules which just pass
# the context down and the output up
apply!(out, ::GrammaticalSymbol, ::Tuple{GrammaticalSymbol}, (word,)) = push!(out, word)
# propagate(context::Context, head::GrammaticalSymbol, args::Tuple{GrammaticalSymbol}, inputs) = context
# propagate(context::Context, head::AbstractIndicator, args::Tuple{GrammaticalSymbol}, inputs) = unconstrained_context()

apply!(out, ::JoinedPhrase, ::Tuple{Phrase}, (p,)) = push!(out, replace(p, ' ' => ""))

apply!(out, ::Phrase, ::Tuple{Phrase, Token}, (a, b)) = push!(out, string(a, " ", b))
# propagate(context::Context, ::Phrase, ::Tuple{Phrase, Token}, inputs) = propagate_concatenation(context, inputs)

# function propagate_concatenation(context, inputs)
#     @assert 0 <= length(inputs) <= 1
#     if length(inputs) == 0
#         Context(1,
#                 context.max_length - 1,
#                 if context.constraint == IsWord || context.constraint == IsPrefix
#                     IsPrefix
#                 else
#                     nothing
#                 end)
#     else
#         len = num_letters(output(first(inputs)))
#         Context(max(1, context.min_length - len),
#                 context.max_length - len,
#                 if context.constraint == IsWord || context.constraint == IsSuffix
#                     IsSuffix
#                 else
#                     nothing
#                 end)
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
    # results = get(Vector{String}, WORDS_BY_ANAGRAM, ))))
    # filter(w -> w != phrase, results)
end
# propagate(context::Context, ::Wordplay, ::Tuple{AnagramIndicator, Phrase}, inputs) = propagate_to_argument(context, 2, inputs, nothing)
@apply_by_reversing Anagram JoinedPhrase AnagramIndicator
# propagate(context::Context, ::Wordplay, ::Tuple{Phrase, AnagramIndicator}, inputs) = propagate_to_argument(context, 1, inputs, nothing)

# function propagate_to_argument(context, index, inputs, constraint=context.constraint)
#     if length(inputs) + 1 == index
#         Context(context.min_length, context.max_length, constraint)
#     else
#         unconstrained_context()
#     end
# end


function apply!(out, ::Wordplay, ::Tuple{Wordplay, Wordplay}, (a, b))
    combined = string(a, b)
    if combined in SUBSTRINGS
        push!(out, combined)
        # [combined]
    # else
    #     String[]
    end
end
# propagate(context::Context, ::Wordplay, ::Tuple{Wordplay, Wordplay}, inputs) = propagate_concatenation(context, inputs)

apply!(out, ::Clue, ::Tuple{Wordplay, Definition}, (wordplay, definition)) = push!(out, wordplay)
# propagate(context::Context, ::Clue, ::Tuple{Wordplay, Definition}, inputs) = propagate_to_argument(context, 1, inputs)
@apply_by_reversing Clue Definition Wordplay
# propagate(context::Context, ::Clue, ::Tuple{Definition, Wordplay}, inputs) = propagate_to_argument(context, 2, inputs)

function apply!(out, ::Abbreviation, ::Tuple{Phrase}, (word,))
    if word in keys(ABBREVIATIONS)
        for abbrev in ABBREVIATIONS[word]
            push!(out, abbrev)
        end
    end
end
 # = copy(get(ABBREVIATIONS, word, String[]))
# propagate(context::Context, ::Abbreviation, ::Tuple{Phrase}, inputs) = unconstrained_context()

apply!(out, ::Filler, ::Tuple{Token}, (word,)) = push!(out, "")
# propagate(context::Context, ::Filler, ::Tuple{Token}, inputs) = unconstrained_context()

apply!(out, ::Clue, ::Tuple{Wordplay, Filler, Definition}, (w, f, d)) = push!(out, w)
# propagate(context::Context, ::Clue, ::Tuple{Wordplay, Filler, Definition}, inputs) = propagate_to_argument(context, 1, inputs)
apply!(out, ::Clue, ::Tuple{Definition, Filler, Wordplay}, (d, f, w)) = push!(out, w)
# propagate(context::Context, ::Clue, ::Tuple{Definition, Filler, Wordplay}, inputs) = propagate_to_argument(context, 3, inputs)

apply!(out, ::Reversal, ::Tuple{ReverseIndicator, Phrase}, (indicator, word)) = push!(out, reverse(replace(word, " " => "")))
# propagate(context::Context, ::Wordplay, ::Tuple{ReverseIndicator, Phrase}, inputs) = propagate_to_argument(context, 2, inputs, nothing)
@apply_by_reversing Reversal Phrase ReverseIndicator
# propagate(context::Context, ::Wordplay, ::Tuple{Phrase, ReverseIndicator}, inputs) = propagate_to_argument(context, 1, inputs, nothing)

apply!(out, ::Substring, ::Tuple{HeadIndicator, Phrase}, (indicator, phrase)) = push!(out, join(first(word) for word in split(phrase)))
# propagate(context::Context, ::Wordplay, ::Tuple{HeadIndicator, Phrase}, inputs) =
    # length(inputs) == 1 ? Context(2, typemax(Int), nothing) : unconstrained_context()

@apply_by_reversing Substring Phrase HeadIndicator
# propagate(context::Context, ::Wordplay, ::Tuple{Phrase, HeadIndicator}, inputs) =
    # length(inputs) == 0 ? Context(2, typemax(Int), nothing) : unconstrained_context()

apply!(out, ::Substring, ::Tuple{TailIndicator, Phrase}, (indicator, phrase)) = push!(out, join(last(word) for word in split(phrase)))
# propagate(context::Context, ::Wordplay, ::Tuple{TailIndicator, Phrase}, inputs) =
    # length(inputs) == 1 ? Context(2, typemax(Int), nothing) : unconstrained_context()

@apply_by_reversing Substring Phrase TailIndicator
# propagate(context::Context, ::Wordplay, ::Tuple{Phrase, TailIndicator}, inputs) =
#     length(inputs) == 0 ? Context(2, typemax(Int), nothing) : unconstrained_context()

function apply!(out, ::Synonym, ::Tuple{Phrase}, (word,))
    if word in keys(SYNONYMS[])
        for syn in SYNONYMS[][word]
            push!(out, syn)
        end
    # else
    #     String[]
    end
end
# propagate(context::Context, ::Synonym, ::Tuple{Phrase}, inputs) = unconstrained_context()


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
    buffer = Vector{Char}()
    len_a = length(a)
    len_b = length(b)
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

# function propagate_to_insertion(context::Context, arg1::Integer, arg2::Integer, inputs)
#     if length(inputs) + 1 == arg1
#         Context(1,
#                 context.max_length - 1,
#                 nothing)
#     elseif length(inputs) + 1 == arg2
#         len = num_letters(output(inputs[arg1]))
#         Context(max(1, context.min_length - len),
#                 context.max_length - len,
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end

apply!(out, ::Insertion, ::Tuple{InsertABIndicator, InsertArg, InsertArg}, (indicator, a, b)) = insertions!(out, a, b)
# propagate(c::Context, ::Wordplay, ::Tuple{InsertABIndicator, Wordplay, Wordplay}, inputs) =
#     propagate_to_insertion(c, 2, 3, inputs)

apply!(out, ::Insertion, ::Tuple{InsertArg, InsertABIndicator, InsertArg}, (a, indicator, b)) = insertions!(out, a, b)
# propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, InsertABIndicator, Wordplay}, inputs) =
#     propagate_to_insertion(c, 1, 3, inputs)

apply!(out, ::Insertion, ::Tuple{InsertArg, InsertArg, InsertABIndicator}, (a, b, indicator)) = insertions!(out, a, b)
# propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, Wordplay, InsertABIndicator}, inputs) =
#     propagate_to_insertion(c, 1, 2, inputs)

apply!(out, ::Insertion, ::Tuple{InsertBAIndicator, InsertArg, InsertArg}, (indicator, b, a)) = insertions!(out, a, b)
# propagate(c::Context, ::Wordplay, ::Tuple{InsertBAIndicator, Wordplay, Wordplay}, inputs) =
#     propagate_to_insertion(c, 2, 3, inputs)

apply!(out, ::Insertion, ::Tuple{InsertArg, InsertBAIndicator, InsertArg}, (b, indicator, a)) = insertions!(out, a, b)
# propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, InsertBAIndicator, Wordplay}, inputs) =
#     propagate_to_insertion(c, 1, 3, inputs)

apply!(out, ::Insertion, ::Tuple{InsertArg, InsertArg, InsertBAIndicator}, (b, a, indicator)) = insertions!(out, a, b)
# propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, Wordplay, InsertBAIndicator}, inputs) =
#     propagate_to_insertion(c, 1, 2, inputs)

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
# function propagate(context::Context, ::Wordplay, ::Tuple{StraddleIndicator, Phrase}, inputs)
#     if length(inputs) == 1
#         Context(2 + context.min_length,
#                 typemax(Int),
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end
@apply_by_reversing Straddle Phrase StraddleIndicator

# apply!(out, ::Straddle, ::Tuple{Phrase, StraddleIndicator}, (phrase, indicator)) = straddling_words!(out, phrase)
# function propagate(context::Context, ::Wordplay, ::Tuple{Phrase, StraddleIndicator}, inputs)
#     if length(inputs) == 0
#         Context(2 + context.min_length,
#                 typemax(Int),
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end

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
# function propagate(context::Context, ::Wordplay, ::Tuple{InitialSubstringIndicator, Union{Phrase, Synonym}}, inputs)
#     if length(inputs) == 1
#         Context(1 + context.min_length,
#                 typemax(Int),
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end
@apply_by_reversing Substring Union{Token, Synonym} InitialSubstringIndicator
# function propagate(context::Context, ::Wordplay, ::Tuple{Union{Phrase, Synonym}, InitialSubstringIndicator}, inputs)
#     if length(inputs) == 0
#         Context(1 + context.min_length,
#                 typemax(Int),
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end

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
# function propagate(context::Context, ::Wordplay, ::Tuple{FinalSubstringIndicator, Union{Phrase, Synonym}}, inputs)
#     if length(inputs) == 1
#         Context(1 + context.min_length,
#                 typemax(Int),
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end
@apply_by_reversing Substring Union{Token, Synonym} FinalSubstringIndicator
# function propagate(context::Context, ::Wordplay, ::Tuple{Union{Phrase, Synonym}, FinalSubstringIndicator}, inputs)
#     if length(inputs) == 0
#         Context(1 + context.min_length,
#                 typemax(Int),
#                 nothing)
#     else
#         unconstrained_context()
#     end
# end

