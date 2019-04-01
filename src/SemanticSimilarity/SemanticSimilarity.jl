module SemanticSimilarity

using ..CrypticCrosswords: normalize

using WordNet
using ProgressMeter: @showprogress
using Statistics: mean

export similarity, WuPalmer, SimilarityDepth

include("cache.jl")
include("metrics.jl")

end # module
