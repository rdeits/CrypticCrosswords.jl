using Test
using CrypticCrosswords.SemanticSimilarity
using Random
using WordNet
using ProgressMeter

const db = SemanticSimilarity.db[]

include("caches.jl")
include("metrics.jl")
