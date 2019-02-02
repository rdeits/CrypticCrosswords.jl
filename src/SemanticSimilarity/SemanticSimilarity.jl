module SemanticSimilarity

using ..CrypticCrosswords: normalize

# using SnowballStemmer: Stemmer, stem
using WordNet
using ProgressMeter: @showprogress
using Statistics: mean

export similarity, WuPalmer, SimilarityDepth

include("caches.jl")
include("metrics.jl")

end # module
