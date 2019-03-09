module CrypticCrosswords

using ChartParsers
using Base.Iterators: product, drop
using Combinatorics: permutations
using DataDeps: @datadep_str
using ProgressMeter: @showprogress
import JSON

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

include("grammar.jl")
include("solver.jl")

struct PTrie{N}
    mask::UInt
    slots::BitSet
end

function PTrie{N}() where {N}
    slots = BitSet()
    mask = sum(1 << i for i in 0:(N - 1))
    PTrie{N}(mask, slots)
end

function Base.push!(p::PTrie, collection)
    h = zero(UInt)
    @inbounds for element in collection
        h = hash(element, h)
        push!(p.slots, h & p.mask)
    end
end

function Base.in(collection, p::PTrie)
    h = zero(UInt)
    @inbounds for element in collection
        h = hash(element, h)
        if (h & p.mask) ∉ p.slots
            return false
        end
    end
    (h & p.mask) in p.slots
end

function Base.getindex(p::PTrie, collection)
    h = zero(UInt)
    for element in collection
        h = hash(element, h)
        if (h & p.mask) ∉ p.slots
            return nothing
        end
    end
    return h
end

function has_concatenation(p::PTrie, h::UInt, suffix)
    @inbounds for element in suffix
        h = hash(element, h)
        if (h & p.mask) ∉ p.slots
            return false
        end
    end
    (h & p.mask) in p.slots
end

function has_concatenation(p::PTrie, collections::Vararg{String, N}) where {N}
    h = zero(UInt)
    for collection in collections
        @inbounds for element in collection
            h = hash(element, h)
            # if !p.slots[(h & p.mask) + 1]
            if (h & p.mask) ∉ p.slots
                return false
            end
        end
    end
    (h & p.mask) in p.slots
end


const WORDS = Set{String}()
const WORDS_BY_ANAGRAM = Dict{String, Vector{String}}()
const ABBREVIATIONS = Dict{String, Vector{String}}()
const SUBSTRINGS = PTrie{32}()
const PREFIXES = PTrie{32}()
const INDICATORS = Dict{String, Vector{GrammaticalSymbol}}()

is_word(x::AbstractString) = x in WORDS

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
    open(joinpath(@__DIR__, "..", "corpora", "mhl-abbreviations", "abbreviations.json")) do file
        for (word, abbrevs) in JSON.parse(file)
            ABBREVIATIONS[normalize(word)] = normalize.(abbrevs)
        end
    end
    open(joinpath(@__DIR__, "..", "corpora", "abbreviations.json")) do file
        for (word, abbrevs) in JSON.parse(file)
            append!(get!(Vector{String}, ABBREVIATIONS, normalize(word)), normalize.(abbrevs))
        end
    end

    @showprogress "Substrings PTrie" for word in WORDS
        push!(PREFIXES, word)
        word = replace(word, ' ' => "")
        for i in 1:length(word)
            push!(SUBSTRINGS, word[i:end])
        end
    end

    for (filename, part_of_speech) in [
        ("Anagram", AnagramIndicator()),
        ("Filler", Filler()),
        ("FinalSubstring", FinalSubstringIndicator()),
        ("InitialSubstring", InitialSubstringIndicator()),
        ("Insert", InsertABIndicator()),
        ("Insert", InsertBAIndicator()),
        ("Initials", InitialsIndicator()),
        ("Reversal", ReversalIndicator())]
        for line in eachline(joinpath(@__DIR__, "..", "corpora", "indicators", filename))
            phrase = normalize(strip(line))
            push!(get!(Vector{GrammaticalSymbol}, INDICATORS, phrase), part_of_speech)
        end
    end

end

end # module
