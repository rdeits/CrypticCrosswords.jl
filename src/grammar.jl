abstract type GrammaticalSymbol end

struct Synonym <: GrammaticalSymbol end
struct Token <: GrammaticalSymbol end
struct Phrase <: GrammaticalSymbol end
struct Wordplay <: GrammaticalSymbol end
struct Clue <: GrammaticalSymbol end
struct Definition <: GrammaticalSymbol end
struct Filler <: GrammaticalSymbol end
struct Abbreviation <: GrammaticalSymbol end

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
        $(esc(:apply))(H::$(esc(Head)), A::Tuple{$(esc.(Args)...)}, words) = $(esc(:apply))(H, reverse(A), reverse(words))
    end
end

function cryptics_rules()
    Rule[
        Phrase() => (Token(),),
        Phrase() => (Phrase(), Token()),
        AnagramIndicator() => (Phrase(),),
        Wordplay() => (AnagramIndicator(), Phrase()),
        Wordplay() => (Phrase(), AnagramIndicator()),
        ReverseIndicator() => (Phrase(),),
        Wordplay() => (ReverseIndicator(), Phrase()),
        Wordplay() => (Phrase(), ReverseIndicator()),
        HeadIndicator() => (Phrase(),),
        Wordplay() => (HeadIndicator(), Phrase()),
        Wordplay() => (Phrase(), HeadIndicator()),
        TailIndicator() => (Phrase(),),
        Wordplay() => (TailIndicator(), Phrase()),
        Wordplay() => (Phrase(), TailIndicator()),
        InsertABIndicator() => (Phrase(),),
        InsertBAIndicator() => (Phrase(),),
        Wordplay() => (InsertABIndicator(), Wordplay(), Wordplay()),
        Wordplay() => (Wordplay(), InsertABIndicator(), Wordplay()),
        Wordplay() => (Wordplay(), Wordplay(), InsertABIndicator()),
        Wordplay() => (InsertBAIndicator(), Wordplay(), Wordplay()),
        Wordplay() => (Wordplay(), InsertBAIndicator(), Wordplay()),
        Wordplay() => (Wordplay(), Wordplay(), InsertBAIndicator()),
        StraddleIndicator() => (Phrase(),),
        Wordplay() => (StraddleIndicator(), Phrase()),
        Wordplay() => (Phrase(), StraddleIndicator()),
        Wordplay() => (Token(),),
        Wordplay() => (Synonym(),),
        Wordplay() => (Wordplay(), Wordplay()),
        Wordplay() => (Abbreviation(),),
        InitialSubstringIndicator() => (Phrase(),),
        Wordplay() => (InitialSubstringIndicator(), Phrase()),
        Wordplay() => (Phrase(), InitialSubstringIndicator()),
        Wordplay() => (InitialSubstringIndicator(), Synonym()),
        Wordplay() => (Synonym(), InitialSubstringIndicator()),
        FinalSubstringIndicator() => (Phrase(),),
        Wordplay() => (FinalSubstringIndicator(), Synonym()),
        Wordplay() => (Synonym(), FinalSubstringIndicator()),
        Abbreviation() => (Phrase(),),
        Filler() => (Token(),),
        Synonym() => (Phrase(),),
        Definition() => (Phrase(),),
        Clue() => (Wordplay(), Definition()),
        Clue() => (Definition(), Wordplay()),
        Clue() => (Wordplay(), Filler(), Definition()),
        Clue() => (Definition(), Filler(), Wordplay()),
    ]
end

propagate(context::Context, rule::Rule, inputs::AbstractVector) = propagate(context, lhs(rule), rhs(rule), inputs)

# Fallback methods for one-argument rules which just pass
# the context down and the output up
apply(::GrammaticalSymbol, ::Tuple{GrammaticalSymbol}, (word,)) = [word]
propagate(context::Context, head::GrammaticalSymbol, args::Tuple{GrammaticalSymbol}, inputs) = context
propagate(context::Context, head::AbstractIndicator, args::Tuple{GrammaticalSymbol}, inputs) = unconstrained_context()

apply(::Phrase, ::Tuple{Phrase, Token}, (a, b)) = [string(a, " ", b)]
propagate(context::Context, ::Phrase, ::Tuple{Phrase, Token}, inputs) = propagate_concatenation(context, inputs)

function propagate_concatenation(context, inputs)
    @assert 0 <= length(inputs) <= 1
    if length(inputs) == 0
        Context(1,
                context.max_length - 1,
                if context.constraint == IsWord || context.constraint == IsPrefix
                    IsPrefix
                else
                    nothing
                end)
    else
        len = num_letters(output(first(inputs)))
        Context(max(1, context.min_length - len),
                context.max_length - len,
                if context.constraint == IsWord || context.constraint == IsSuffix
                    IsSuffix
                else
                    nothing
                end)
    end
end

function apply(::Wordplay, ::Tuple{AnagramIndicator, Phrase}, (indicator, phrase))
    results = get(Vector{String}, WORDS_BY_ANAGRAM, join(sort(collect(replace(phrase, " " => "")))))
    filter(w -> w != phrase, results)
end
propagate(context::Context, ::Wordplay, ::Tuple{AnagramIndicator, Phrase}, inputs) = propagate_to_argument(context, 2, inputs, nothing)
@apply_by_reversing Wordplay Phrase AnagramIndicator
propagate(context::Context, ::Wordplay, ::Tuple{Phrase, AnagramIndicator}, inputs) = propagate_to_argument(context, 1, inputs, nothing)

function propagate_to_argument(context, index, inputs, constraint=context.constraint)
    if length(inputs) + 1 == index
        Context(context.min_length, context.max_length, constraint)
    else
        unconstrained_context()
    end
end


function apply(::Wordplay, ::Tuple{Wordplay, Wordplay}, (a, b))
    combined = string(a, b)
    if combined in SUBSTRINGS
        [combined]
    else
        String[]
    end
end
propagate(context::Context, ::Wordplay, ::Tuple{Wordplay, Wordplay}, inputs) = propagate_concatenation(context, inputs)

apply(::Clue, ::Tuple{Wordplay, Definition}, (wordplay, definition)) = [wordplay]
propagate(context::Context, ::Clue, ::Tuple{Wordplay, Definition}, inputs) = propagate_to_argument(context, 1, inputs)
@apply_by_reversing Clue Definition Wordplay
propagate(context::Context, ::Clue, ::Tuple{Definition, Wordplay}, inputs) = propagate_to_argument(context, 2, inputs)

apply(::Abbreviation, ::Tuple{Phrase}, (word,)) = copy(get(ABBREVIATIONS, word, String[]))
propagate(context::Context, ::Abbreviation, ::Tuple{Phrase}, inputs) = unconstrained_context()

apply(::Filler, ::Tuple{Token}, (word,)) = [""]
propagate(context::Context, ::Filler, ::Tuple{Token}, inputs) = unconstrained_context()

apply(::Clue, ::Tuple{Wordplay, Filler, Definition}, (w, f, d)) = [w]
propagate(context::Context, ::Clue, ::Tuple{Wordplay, Filler, Definition}, inputs) = propagate_to_argument(context, 1, inputs)
apply(::Clue, ::Tuple{Definition, Filler, Wordplay}, (d, f, w)) = [w]
propagate(context::Context, ::Clue, ::Tuple{Definition, Filler, Wordplay}, inputs) = propagate_to_argument(context, 3, inputs)

apply(::Wordplay, ::Tuple{ReverseIndicator, Phrase}, (indicator, word)) = [reverse(replace(word, " " => ""))]
propagate(context::Context, ::Wordplay, ::Tuple{ReverseIndicator, Phrase}, inputs) = propagate_to_argument(context, 2, inputs, nothing)
@apply_by_reversing Wordplay Phrase ReverseIndicator
propagate(context::Context, ::Wordplay, ::Tuple{Phrase, ReverseIndicator}, inputs) = propagate_to_argument(context, 1, inputs, nothing)

apply(::Wordplay, ::Tuple{HeadIndicator, Phrase}, (indicator, phrase)) = [join(first(word) for word in split(phrase))]
propagate(context::Context, ::Wordplay, ::Tuple{HeadIndicator, Phrase}, inputs) =
    length(inputs) == 1 ? Context(2, typemax(Int), nothing) : unconstrained_context()

@apply_by_reversing Wordplay Phrase HeadIndicator
propagate(context::Context, ::Wordplay, ::Tuple{Phrase, HeadIndicator}, inputs) =
    length(inputs) == 0 ? Context(2, typemax(Int), nothing) : unconstrained_context()

apply(::Wordplay, ::Tuple{TailIndicator, Phrase}, (indicator, phrase)) = [join(last(word) for word in split(phrase))]
propagate(context::Context, ::Wordplay, ::Tuple{TailIndicator, Phrase}, inputs) =
    length(inputs) == 1 ? Context(2, typemax(Int), nothing) : unconstrained_context()

@apply_by_reversing Wordplay Phrase TailIndicator
propagate(context::Context, ::Wordplay, ::Tuple{Phrase, TailIndicator}, inputs) =
    length(inputs) == 0 ? Context(2, typemax(Int), nothing) : unconstrained_context()

function apply(::Synonym, ::Tuple{Phrase}, (word,))
    if word in keys(SYNONYMS[])
        collect(SYNONYMS[][word])
    else
        String[]
    end
end
propagate(context::Context, ::Synonym, ::Tuple{Phrase}, inputs) = unconstrained_context()


"""
All insertions of a into b
"""
function insertions(a, b)
    results = String[]
    for breakpoint in 1:(length(b) - 1)
        s = string(b[1:breakpoint], a, b[(breakpoint+1):end])
        if s in SUBSTRINGS
            push!(results, s)
        end
    end
    results
end

function propagate_to_insertion(context::Context, arg1::Integer, arg2::Integer, inputs)
    if length(inputs) + 1 == arg1
        Context(1,
                context.max_length - 1,
                nothing)
    elseif length(inputs) + 1 == arg2
        len = num_letters(output(inputs[arg1]))
        Context(max(1, context.min_length - len),
                context.max_length - len,
                nothing)
    else
        unconstrained_context()
    end
end

apply(::Wordplay, ::Tuple{InsertABIndicator, Wordplay, Wordplay}, (indicator, a, b)) = insertions(a, b)
propagate(c::Context, ::Wordplay, ::Tuple{InsertABIndicator, Wordplay, Wordplay}, inputs) =
    propagate_to_insertion(c, 2, 3, inputs)

apply(::Wordplay, ::Tuple{Wordplay, InsertABIndicator, Wordplay}, (a, indicator, b)) = insertions(a, b)
propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, InsertABIndicator, Wordplay}, inputs) =
    propagate_to_insertion(c, 1, 3, inputs)

apply(::Wordplay, ::Tuple{Wordplay, Wordplay, InsertABIndicator}, (a, b, indicator)) = insertions(a, b)
propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, Wordplay, InsertABIndicator}, inputs) =
    propagate_to_insertion(c, 1, 2, inputs)

apply(::Wordplay, ::Tuple{InsertBAIndicator, Wordplay, Wordplay}, (indicator, b, a)) = insertions(a, b)
propagate(c::Context, ::Wordplay, ::Tuple{InsertBAIndicator, Wordplay, Wordplay}, inputs) =
    propagate_to_insertion(c, 2, 3, inputs)

apply(::Wordplay, ::Tuple{Wordplay, InsertBAIndicator, Wordplay}, (b, indicator, a)) = insertions(a, b)
propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, InsertBAIndicator, Wordplay}, inputs) =
    propagate_to_insertion(c, 1, 3, inputs)

apply(::Wordplay, ::Tuple{Wordplay, Wordplay, InsertBAIndicator}, (b, a, indicator)) = insertions(a, b)
propagate(c::Context, ::Wordplay, ::Tuple{Wordplay, Wordplay, InsertBAIndicator}, inputs) =
    propagate_to_insertion(c, 1, 2, inputs)

apply(::Wordplay, ::Tuple{StraddleIndicator, Phrase}, (indicator, phrase)) = straddling_words(phrase)
function propagate(context::Context, ::Wordplay, ::Tuple{StraddleIndicator, Phrase}, inputs)
    if length(inputs) == 1
        Context(2 + context.min_length,
                typemax(Int),
                nothing)
    else
        unconstrained_context()
    end
end

apply(::Wordplay, ::Tuple{Phrase, StraddleIndicator}, (phrase, indicator)) = straddling_words(phrase)
function propagate(context::Context, ::Wordplay, ::Tuple{Phrase, StraddleIndicator}, inputs)
    if length(inputs) == 0
        Context(2 + context.min_length,
                typemax(Int),
                nothing)
    else
        unconstrained_context()
    end
end

function apply(::Wordplay, ::Tuple{InitialSubstringIndicator, Union{Phrase, Synonym}}, (indicator, phrase))
    combined = replace(phrase, ' ' => "")
    results = String[]
    len = length(combined)
    for i in 2:3
        if len > i + 1
            push!(results, combined[1:i])
        end
    end
    if len > 4
        push!(results, combined[1:end-1])
    end
    if iseven(len)
        first_half = combined[1:(len ÷ 2)]
        if first_half ∉ results
            push!(results, first_half)
        end
    end
    results
end
function propagate(context::Context, ::Wordplay, ::Tuple{InitialSubstringIndicator, Union{Phrase, Synonym}}, inputs)
    if length(inputs) == 1
        Context(1 + context.min_length,
                typemax(Int),
                nothing)
    else
        unconstrained_context()
    end
end
@apply_by_reversing Wordplay Union{Phrase, Synonym} InitialSubstringIndicator
function propagate(context::Context, ::Wordplay, ::Tuple{Union{Phrase, Synonym}, InitialSubstringIndicator}, inputs)
    if length(inputs) == 0
        Context(1 + context.min_length,
                typemax(Int),
                nothing)
    else
        unconstrained_context()
    end
end

function apply(::Wordplay, ::Tuple{FinalSubstringIndicator, Union{Phrase, Synonym}}, (indicator, phrase))
    combined = replace(phrase, ' ' => "")
    results = String[]
    len = length(combined)
    if len > 2
        push!(results, combined[2:end])
    end
    if iseven(len)
        last_half = combined[(len ÷ 2 + 1):end]
        if last_half ∉ results
            push!(results, last_half)
        end
    end
    results
end
function propagate(context::Context, ::Wordplay, ::Tuple{FinalSubstringIndicator, Union{Phrase, Synonym}}, inputs)
    if length(inputs) == 1
        Context(1 + context.min_length,
                typemax(Int),
                nothing)
    else
        unconstrained_context()
    end
end
@apply_by_reversing Wordplay Union{Phrase, Synonym} FinalSubstringIndicator
function propagate(context::Context, ::Wordplay, ::Tuple{Union{Phrase, Synonym}, FinalSubstringIndicator}, inputs)
    if length(inputs) == 0
        Context(1 + context.min_length,
                typemax(Int),
                nothing)
    else
        unconstrained_context()
    end
end

