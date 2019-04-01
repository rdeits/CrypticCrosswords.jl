
@testset "Similarity depth cache" begin
    function similarity_depth(db::DB, s1::Synset, s2::Synset, max_depth=5)
        if s1 == s2
            return 0
        end
        explored = Set{Synset}([s1])
        active_set = Vector{Synset}([s1])
        frontier = Vector{Synset}()
        for depth in 1:max_depth
            for synset in active_set
                for related in SemanticSimilarity.similar_to(db, synset)
                    if related == s2
                        return depth
                    end
                    if !(related in explored)
                        push!(frontier, related)
                        push!(explored, related)
                    end
                end
            end
            active_set, frontier = frontier, active_set
            if isempty(active_set)
                break
            end
            empty!(frontier)
        end
        return nothing
    end

    @showprogress "Similarity depths" for groups_for_word in values(SemanticSimilarity.CACHE[].similarity_groups)
        for groups in groups_for_word
            synset = first(first(groups))
            for i in 1:length(groups)
                for element in groups[i]
                    @test similarity_depth(db, synset, element) == i - 1
                end
            end
        end
    end
end