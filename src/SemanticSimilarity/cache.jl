const Path = Vector{Synset}
const SimilarityGroups = Vector{Set{Synset}}

struct BasicSynset
    words::Vector{String}
end
Base.hash(s::BasicSynset, h::UInt) = hash(s.words, h)
Base.isequal(s1::BasicSynset, s2::BasicSynset) = s1.words === s2.words

WordNet.words(b::BasicSynset) = b.words

const BasicPath = Vector{BasicSynset}
const BasicSimilarityGroups = Vector{Set{BasicSynset}}

struct Cache
    # db::WordNet.DB
    synsets::Dict{String, Vector{BasicSynset}}
    paths::Dict{String, Vector{BasicPath}}
    similarity_groups::Dict{String, Vector{BasicSimilarityGroups}}
end

function push(v::AbstractVector, x)
    result = copy(v)
    push!(result, x)
    result
end

function paths_to_synset(db::DB, synset::Synset)
    complete_paths = Vector{Path}()
    active_set = [[synset]]
    while !isempty(active_set)
        path = pop!(active_set)
        parents = WordNet.relation(db, path[end], WordNet.HYPERNYM)
        if isempty(parents)
            push!(path, WordNet.∅)
            reverse!(path)
            push!(complete_paths, path)
        else
            for parent in parents
                if parent ∉ path
                    if length(parents) == 1
                        push!(path, parent)
                        new_path = path
                    else
                        new_path = push(path, parent)
                    end
                    push!(active_set, new_path)
                end
            end
        end
    end
    complete_paths
end

similar_to(db::DB, synset::Synset) = WordNet.relation(db, synset, WordNet.SIMILAR_TO)

function similarity_groups(db::DB, synset::Synset, max_depth=10)
    explored = Set([synset])
    groups = [Set([synset])]
    for i in 1:max_depth
        active_set = groups[i]
        frontier = Set{Synset}()
        for synset in active_set
            for related in similar_to(db, synset)
                if related in explored
                    continue
                end
                push!(explored, related)
                push!(frontier, related)
            end
        end
        if isempty(frontier)
            break
        end
        push!(groups, frontier)
    end
    groups
end

function basic_stem(word)
    if endswith(word, 's')
        word[1:end-1]
    else
        word
    end
end

strip_wordnet_pointers(s::Synset, c::AbstractDict{Synset, BasicSynset}) =
    get!(() -> BasicSynset(collect(words(s))), c, s)
strip_wordnet_pointers(v::Set{Synset}, c::AbstractDict{Synset, BasicSynset}) =
    Set([strip_wordnet_pointers(x, c) for x in v])
function strip_wordnet_pointers(v::Union{
            Vector{Synset},
            Vector{Set{Synset}},
            Vector{Vector{Synset}},
            Vector{Vector{Set{Synset}}}},
        c::AbstractDict{Synset, BasicSynset})
    [strip_wordnet_pointers(x, c) for x in v]
end

function Cache()
    db = DB()
    synsets = Dict{String, Vector{BasicSynset}}()
    paths = Dict{String, Vector{BasicPath}}()
    groups = Dict{String, Vector{BasicSimilarityGroups}}()
    synset_cache = Dict{Synset, BasicSynset}()
    @showprogress "Caching similarities" for (pos, part_of_speech_synsets) in db.synsets
        for synset in values(part_of_speech_synsets)
            for word in words(synset)
                push!(get!(Vector{BasicSynset},
                           synsets,
                           basic_stem(normalize(word))),
                      strip_wordnet_pointers(synset, synset_cache))
            end
            if synset.pos ∈ ('a', 's')
                g = strip_wordnet_pointers(similarity_groups(db, synset), synset_cache)
                for word in words(synset)
                    push!(get!(Vector{BasicSimilarityGroups}, groups, basic_stem(normalize(word))),
                          g)
                end
            else
                p = strip_wordnet_pointers(paths_to_synset(db, synset), synset_cache)
                for word in words(synset)
                    append!(get!(Vector{BasicPath}, paths, basic_stem(normalize(word))), p)
                end
            end
        end
    end
    Cache(synsets, paths, groups)
end
