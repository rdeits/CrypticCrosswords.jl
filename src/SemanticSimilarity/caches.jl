const Path = Vector{Synset}
const SimilarityGroups = Vector{Set{Synset}}
const db = Ref{WordNet.DB}()
const SYNSETS = Dict{String, Vector{Synset}}()
const PATHS = Dict{String, Vector{Path}}()
const SIMILARITY_GROUPS = Dict{String, Vector{SimilarityGroups}}()
const STEMMER = Ref{Stemmer}()

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

function update_caches!()
    db[] = DB()
    empty!(PATHS)
    empty!(SIMILARITY_GROUPS)
    empty!(SYNSETS)
    STEMMER[] = Stemmer("english")
    @showprogress "Caching similarities" for (pos, part_of_speech_synsets) in db[].synsets
        for synset in values(part_of_speech_synsets)
            for word in words(synset)
                push!(get!(Vector{Synset}, SYNSETS, stem(STEMMER[], normalize(word))), synset)
            end
            if synset.pos ∈ ('a', 's')
                groups = similarity_groups(db[], synset)
                for word in words(synset)
                    push!(get!(Vector{SimilarityGroups}, SIMILARITY_GROUPS, stem(STEMMER[], normalize(word))), groups)
                end
            else
                paths = paths_to_synset(db[], synset)
                for word in words(synset)
                    append!(get!(Vector{Path}, PATHS, stem(STEMMER[], normalize(word))), paths)
                end
            end
        end
    end
end

function __init__()
    update_caches!()
end

