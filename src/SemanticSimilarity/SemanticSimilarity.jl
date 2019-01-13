module SemanticSimilarity

using ..CrypticCrosswords: normalize

using WordNet
using ProgressMeter

export similarity, WuPalmer, SimilarityDepth

include("caches.jl")
include("metrics.jl")

end # module
