module CrypticCrosswords

using ChartParsers
using Base.Iterators: product, drop
using Combinatorics: permutations
using DataDeps: @datadep_str
using ProgressMeter: @showprogress
import JSON

export solve, Context, IsWord, IsPrefix, IsSuffix, derive!, explain

function normalize(word)
    word |> lowercase |> strip |> (w -> replace(w, '_' => ' ')) |> (w -> replace(w, r"[^a-z0-9 ]" => ""))
end

include("SemanticSimilarity/SemanticSimilarity.jl")
using .SemanticSimilarity

include("grammar.jl")
include("solver.jl")
include("explanations.jl")
include("ptrie.jl")
include("cache.jl")

include(joinpath(@__DIR__, "..", "deps", "data_registration.jl"))
const CACHE = Cache()

is_word(x::AbstractString) = x in CACHE.words

end # module
