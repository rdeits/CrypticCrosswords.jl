const Path = Vector{Synset}
const SimilarityGroups = Vector{Set{Synset}}

struct Cache
    db::WordNet.DB
    synsets::Dict{String, Vector{Synset}}
    paths::Dict{String, Vector{Path}}
    similarity_groups::Dict{String, Vector{SimilarityGroups}}
end

const CACHE = Ref{Cache}()

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

function Cache()
    db = DB()
    synsets = Dict{String, Vector{Synset}}()
    paths = Dict{String, Vector{Path}}()
    groups = Dict{String, Vector{SimilarityGroups}}()
    @showprogress "Caching similarities" for (pos, part_of_speech_synsets) in db.synsets
        for synset in values(part_of_speech_synsets)
            for word in words(synset)
                push!(get!(Vector{Synset}, synsets, basic_stem(normalize(word))), synset)
            end
            if synset.pos ∈ ('a', 's')
                g = similarity_groups(db, synset)
                for word in words(synset)
                    push!(get!(Vector{SimilarityGroups}, groups, basic_stem(normalize(word))), g)
                end
            else
                p = paths_to_synset(db, synset)
                for word in words(synset)
                    append!(get!(Vector{Path}, paths, basic_stem(normalize(word))), p)
                end
            end
        end
    end
    Cache(db, synsets, paths, groups)
end

function update_cache!()
    CACHE[] = Cache()
end

function synsets(word)
    get(CACHE[].synsets, basic_stem(word), Synset[])
end

function __init__()
    update_cache!()
end

