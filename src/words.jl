is_word(x::AbstractString) = x in keys(SYNONYMS)

function straddling_words(w1, w2)
    results = String[]
    combined = w1 * w2
    for i in 2:length(w1)
        for j in length(w1) .+ (1:(length(w2) - 1))
            candidate = combined[i:j]
            if is_word(candidate)
                push!(results, candidate)
            end
        end
    end
    results
end

function is_anagram(w1::AbstractString, w2::AbstractString)
    sort(collect(replace(w1, " " => ""))) == sort(collect(replace(w2, " " => "")))
end

struct DefaultDict{K, V, F} <: AbstractDict{K, V}
    data::Dict{K, V}
    default::F
end

DefaultDict{K, V}(f::F) where {K, V, F} = DefaultDict{K, V, F}(Dict{K, V}(), f)
DefaultDict{K, V}() where {K, V} = DefaultDict{K, V}(() -> V())

Base.getindex(d::DefaultDict, k) = get!(d.default, d.data, k)
Base.setindex(d::DefaultDict, v, k) = setindex(d.data, v, k)

const WORDS = Set{String}(collect(keys(SYNONYMS)))

const WORDS_BY_ANAGRAM = Dict{String, Vector{String}}()

for word in WORDS
    key = join(sort(collect(replace(word, " " => ""))))
    v = get!(Vector{String}, WORDS_BY_ANAGRAM, key)
    push!(v, word)
end

@enum Constraint IsWord IsPrefix IsSuffix

const WORDS_BY_CONSTRAINT = DefaultDict{Constraint, Set{String}}()

for word in WORDS
    push!(WORDS_BY_CONSTRAINT[IsWord], word)
    for i in 1:length(word)
        push!(WORDS_BY_CONSTRAINT[IsPrefix], word[1:i])
        push!(WORDS_BY_CONSTRAINT[IsSuffix], word[(end - i + 1):end])
    end
end


struct Context
    min_length::Int
    max_length::Int
    constraint::Union{Constraint, Nothing}
end

num_letters(word::AbstractString) = count(!isequal(' '), word)

function is_match(context::Context, word::AbstractString)
    (context.min_length <= num_letters(word) <= context.max_length) || return false
    word
    if context.constraint === nothing
        return true
    else
        return word in WORDS_BY_CONSTRAINT[context.constraint]
    end
end

is_match(context::Context) = (word) -> is_match(context, word)

unconstrained_context() = Context(0, typemax(Int), nothing)

function is_subset(c1::Context, c2::Context)
    c1.min_length >= c2.min_length || return false
    c1.max_length <= c2.max_length || return false
    is_subset(c1.constraint, c2.constraint) || return false
    return true
end

is_subset(::Nothing, ::Nothing) = true
is_subset(::Nothing, ::Constraint) = false
is_subset(::Constraint, ::Nothing) = true

function is_subset(c1::Constraint, c2::Constraint)
    if c1 == IsWord && c2 == IsWord
        true
    elseif c1 == IsPrefix && c2 ∈ (IsPrefix, IsWord)
        true
    elseif c1 == IsSuffix && c2 ∈ (IsSuffix, IsWord)
        true
    else
        false
    end
end

⊆(c1::Context, c2::Context) = is_subset(c1, c2)

Base.isempty(c::Context) = c.max_length < 1 || c.min_length > c.max_length
