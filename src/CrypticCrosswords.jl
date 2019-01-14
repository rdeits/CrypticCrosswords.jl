module CrypticCrosswords

using Base.Iterators: product, drop
using Combinatorics: permutations
using DataDeps: @datadep_str

export solve, Context, IsWord, IsPrefix, IsSuffix

function normalize(word)
    word |> lowercase |> strip |> (w -> replace(w, '_' => ' ')) |> (w -> replace(w, r"[^a-z0-9 ]" => ""))
end

include("SemanticSimilarity/SemanticSimilarity.jl")
using .SemanticSimilarity

include("Synonyms.jl")
using .Synonyms

include("FixedCapacityVectors.jl")
using .FixedCapacityVectors

include("words.jl")
include("grammar.jl")
include("parsing.jl")
include("solver.jl")

const WORDS = Set{String}()
const WORDS_BY_ANAGRAM = Dict{String, Vector{String}}()
const WORDS_BY_CONSTRAINT = DefaultDict{Constraint, Set{String}}()

function __init__()
    for word in keys(SYNONYMS[])
        push!(WORDS, word)
    end
    for line in eachline(datadep"SCOWL-wordlist-en_US-large/en_US-large.txt")
        push!(WORDS, normalize(line))
    end
    for word in WORDS
        key = join(sort(collect(replace(word, " " => ""))))
        v = get!(Vector{String}, WORDS_BY_ANAGRAM, key)
        push!(v, word)
    end
    for word in WORDS
        push!(WORDS_BY_CONSTRAINT[IsWord], word)
        for i in 1:length(word)
            push!(WORDS_BY_CONSTRAINT[IsPrefix], word[1:i])
            push!(WORDS_BY_CONSTRAINT[IsSuffix], word[(end - i + 1):end])
        end
    end

end

end # module
