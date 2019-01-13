@testset "Symmetry" begin
    words = collect(keys(SemanticSimilarity.SYNSETS))

    Random.seed!(42)
    for i in 1:1000
        # Similarity is symmetric
        word1 = rand(words)
        word2 = rand(words)
        @test similarity(word1, word2) == similarity(word2, word1)
        @test similarity(WuPalmer(), word1, word2) == similarity(WuPalmer(), word2, word1)
        @test similarity(SimilarityDepth(), word1, word2) == similarity(SimilarityDepth(), word2, word1)
    end
    for i in 1:100
        # No word is similar to a nonexistent word
        word1 = rand(words)
        word2 = "abcdefgh"
        @test similarity(word1, word2) == similarity(word2, word1) == 0
        @test similarity(WuPalmer(), word1, word2) == similarity(WuPalmer(), word2, word1) == 0
        @test similarity(SimilarityDepth(), word1, word2) == similarity(SimilarityDepth(), word2, word1) == 0
    end

    # Nonexistent words are still identitcal to themselves
    @test similarity("abcdefgh", "abcdefgh") == 1.0
    @test similarity(WuPalmer(), "abcdefgh", "abcdefgh") == 1.0
    @test similarity(SimilarityDepth(), "abcdefgh", "abcdefgh") == 1.0

    # Nonexistent words are not similar to other nonexistent words
    @test similarity("abcdefgh", "asdfghj") == 0
end

@testset "Synonyms" begin
    # Members of the same synset should always have similarity == 1
    Random.seed!(1)
    synsets = collect(values(SemanticSimilarity.SYNSETS))
    for i in 1:100
        synset = rand(rand(synsets))
        for word1 in WordNet.words(synset)
            for word2 in words(synset)
                @test similarity(word1, word2) == 1.0
            end
        end
    end
end

@testset "Specific words" begin

end
