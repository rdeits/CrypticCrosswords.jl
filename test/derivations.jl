using Test
using CrypticCrosswords

@testset "Derivations" begin
    @testset "Reversal" begin
        clue = "aerial worker anne on the way up"
        pattern = r"^.{7}$"
        solutions, state = solve(clue, pattern=pattern, min_grammar_score=2e-5)
        sol = first(solutions)
        derivations = derive!(state, sol)
        @test length(derivations) == 1
        d = first(derivations)
        @test d.output == "antenna"
        @test d.derivation.constituents[1].output == "aerial"
        @test d.derivation.constituents[2].output == "antenna"
        @test d.derivation.constituents[2].constituents[1].output == "ant"
        @test d.derivation.constituents[2].constituents[1].constituents[1].output == "ant"
        @test d.derivation.constituents[2].constituents[1].constituents[1].constituents[1].output == "worker"
        @test d.derivation.constituents[2].constituents[2].output == "enna"
        @test d.derivation.constituents[2].constituents[2].constituents[1].output == "enna"
        @test d.derivation.constituents[2].constituents[2].constituents[1].constituents[1].output == "anne"
    end

    @testset "Insertion" begin
        # Simplified version of "Join trio of astronomers in marsh"
        clue = "join ast in marsh"
        solutions, state = solve(clue, length=6)
        sol = first(solutions)
        derivations = derive!(state, sol)
        d = first(derivations)
        @test d.output == "fasten"
        @test d.derivation.constituents[1].output == "join"
        @test d.derivation.constituents[2].output == "fasten"
        @test d.derivation.constituents[2].constituents[1].output == "fasten"
        @test d.derivation.constituents[2].constituents[1].constituents[1].output == "ast"
        @test d.derivation.constituents[2].constituents[1].constituents[2].output == "in"
        @test d.derivation.constituents[2].constituents[1].constituents[3].output == "fen"
        @test d.derivation.constituents[2].constituents[1].constituents[3].constituents[1].output == "fen"
        @test d.derivation.constituents[2].constituents[1].constituents[3].constituents[1].constituents[1].output == "marsh"
    end
end

