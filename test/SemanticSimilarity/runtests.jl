using Test
using CrypticCrosswords.SemanticSimilarity
using Random
using WordNet
using ProgressMeter

const db = SemanticSimilarity.CACHE[].db

include("caches.jl")
include("metrics.jl")
