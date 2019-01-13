module SemanticSimilarity

using ..CrypticCrosswords: normalize

using SnowballStemmer: Stemmer, stem
using WordNet
using ProgressMeter: @showprogress

export similarity, WuPalmer, SimilarityDepth

include("caches.jl")
include("metrics.jl")

end # module
