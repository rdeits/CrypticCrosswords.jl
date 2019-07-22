module SemanticSimilarity

using ..CrypticCrosswords: normalize

using WordNet
using ProgressMeter: @showprogress
using Statistics: mean

export similarity, WuPalmer, SimilarityDepth

include("cache.jl")

const CACHE = Cache()

include("metrics.jl")

end # module
