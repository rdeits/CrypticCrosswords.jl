abstract type AbstractMetric end
struct WuPalmer <: AbstractMetric end
struct SimilarityDepth <: AbstractMetric end

function similarity(w1::AbstractString, w2::AbstractString)
    w1 = stem(STEMMER[], w1)
    w2 = stem(STEMMER[], w2)
    max(similarity(WuPalmer(), w1, w2),
        similarity(SimilarityDepth(), w1, w2))
end

function similarity(::WuPalmer, w1::AbstractString, w2::AbstractString)
    if w1 == w2
        return 1.0
    end
    if !(w1 in keys(PATHS)) || !(w2 in keys(PATHS))
        return 0.0
    end
    s = 0.0
    for p1 in PATHS[w1]
        for p2 in PATHS[w2]
            s = max(s, similarity(WuPalmer(), p1, p2))
        end
    end
    return s
end

function similarity(::WuPalmer, p1::Path, p2::Path)
    2 * common_ancestor_depth(p1, p2) / (length(p1) + length(p2))
end

function common_ancestor_depth(p1::Path, p2::Path)
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
    if !(w1 in keys(SIMILARITY_GROUPS)) || !(w2 in keys(SYNSETS))
        return s
    end
    for groups in SIMILARITY_GROUPS[w1]
        for synset in SYNSETS[w2]
            s = max(s, similarity(SimilarityDepth(), groups, synset))
        end
    end
    s
end

const ADJECTIVE_EQUIVALENT_DEPTH = 10

function similarity(::SimilarityDepth, groups::SimilarityGroups, synset::Synset)
    d = similarity_distance(groups, synset)
    if d === nothing
        return 0.0
    end
    2 * (ADJECTIVE_EQUIVALENT_DEPTH - d) / (2 * ADJECTIVE_EQUIVALENT_DEPTH)
end

function similarity_distance(groups::SimilarityGroups, synset::Synset)
    for i in 1:length(groups)
        if synset in groups[i]
            return i - 1
        end
    end
    nothing
end

