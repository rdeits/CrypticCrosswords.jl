module CrypticCrosswords

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

include("words.jl")
include("grammar.jl")
include("parsing.jl")
include("solver.jl")

# struct Trie{T}
#     children::Dict{T, Trie{T}}
# end

# Trie{T}() where {T} = Trie{T}(Dict{T, Trie{T}}())

# function Base.push!(t::Trie, x)
#     T = eltype(x)
#     for element in x
#         t = get!(Trie{T}, t.children, element)
#     end
# end

# function Base.show(io::IO, t::Trie{T}) where {T}
#     print(io, "Trie{$T}(...)")
# end

# function Base.in(x, t::Trie)
#     for element in x
#         t = get(t.children, element, nothing)
#         if t === nothing
#             return false
#         end
#     end
#     return true
# end

# function Base.getindex(t::Trie, x)
#     for element in x
#         t = get(t.children, element, nothing)
#         if t === nothing
#             return nothing
#         end
#     end
#     return t
# end

struct PTrie{N}
    mask::UInt
    slots::BitArray{1}
end

function PTrie{N}() where {N}
    slots = BitArray(undef, 2^N)
    slots .= false
    mask = sum(1 << i for i in 0:(N - 1))
    PTrie{N}(mask, slots)
end

function Base.push!(p::PTrie, collection)
    h = zero(UInt)
    @inbounds for element in collection
        h = hash(element, h)
        p.slots[(h & p.mask) + 1] = true
    end
end

function Base.in(collection, p::PTrie)
    h = zero(UInt)
    @inbounds for element in collection
        h = hash(element, h)
        if !p.slots[(h & p.mask) + 1]
            return false
        end
    end
    @inbounds p.slots[(h & p.mask) + 1]
end

function has_concatenation(p::PTrie, collections::Vararg{String, N}) where {N}
    h = zero(UInt)
    for collection in collections
        @inbounds for element in collection
            h = hash(element, h)
            if !p.slots[(h & p.mask) + 1]
                return false
            end
        end
    end
    @inbounds p.slots[(h & p.mask) + 1]
end


const WORDS = Set{String}()
const WORDS_BY_ANAGRAM = Dict{String, Vector{String}}()
const WORDS_BY_CONSTRAINT = DefaultDict{Constraint, Set{String}}()
const ABBREVIATIONS = Dict{String, Vector{String}}()
const SUBSTRINGS = PTrie{32}()
const SUBSTRINGS_SET = Set{String}()


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
        word = replace(word, ' ' => "")
        for i in 1:length(word)
            push!(SUBSTRINGS, word[i:end])
        end
    end

    @showprogress "Substrings set" for word in WORDS
        word = replace(word, ' ' => "")
        for i in 1:length(word)
            for j in 1:length(word)
                push!(SUBSTRINGS_SET, word[i:j])
            end
        end
    end
end

end # module
