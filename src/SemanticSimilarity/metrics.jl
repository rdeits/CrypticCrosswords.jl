abstract type AbstractMetric end
struct WuPalmer <: AbstractMetric end
struct SimilarityDepth <: AbstractMetric end

function similarity(w1::AbstractString, w2::AbstractString)
    phrase1 = basic_stem.(split(w1, ' '))
    phrase2 = basic_stem.(split(w2, ' '))
    max(_similarity_of_stemmed_words(basic_stem(w1), basic_stem(w2)),
        mean(_similarity_of_stemmed_words(a, b) for a in phrase1 for b in phrase2))
end

function _similarity_of_stemmed_words(w1::AbstractString, w2::AbstractString)
    max(similarity(WuPalmer(), w1, w2),
        similarity(SimilarityDepth(), w1, w2))
end

function similarity(::WuPalmer, w1::AbstractString, w2::AbstractString)
    if w1 == w2
        return 1.0
    end
    if !(w1 in keys(CACHE.paths)) || !(w2 in keys(CACHE.paths))
        return 0.0
    end
    s = 0.0
    for p1 in CACHE.paths[w1]
        for p2 in CACHE.paths[w2]
            s = max(s, similarity(WuPalmer(), p1, p2))
        end
    end
    return s
end

function similarity(::WuPalmer, p1::BasicPath, p2::BasicPath)
    2 * common_ancestor_depth(p1, p2) / (length(p1) + length(p2))
end

function common_ancestor_depth(p1::BasicPath, p2::BasicPath)
    max_depth = min(length(p1), length(p2))
    for i in 1:max_depth
        if p1[i] != p2[i]
            return i - 1
        end
    end
    return max_depth
end


function similarity(::SimilarityDepth, w1::AbstractString, w2::AbstractString)
    if w1 == w2
        return 1.0
    end
    s = 0.0
    if !(w1 in keys(CACHE.similarity_groups)) || !(w2 in keys(CACHE.synsets))
        return s
    end
    for groups in CACHE.similarity_groups[w1]
        for synset in CACHE.synsets[w2]
            s = max(s, similarity(SimilarityDepth(), groups, synset))
        end
    end
    s
end

const ADJECTIVE_EQUIVALENT_DEPTH = 10

function similarity(::SimilarityDepth, groups::BasicSimilarityGroups, synset::BasicSynset)
    d = similarity_distance(groups, synset)
    if d === nothing
        return 0.0
    end
    2 * (ADJECTIVE_EQUIVALENT_DEPTH - d) / (2 * ADJECTIVE_EQUIVALENT_DEPTH)
end

function similarity_distance(groups::BasicSimilarityGroups, synset::BasicSynset)
    for i in 1:length(groups)
        if synset in groups[i]
            return i - 1
        end
    end
    nothing
end

