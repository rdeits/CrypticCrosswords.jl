using Test
using CrypticCrosswords

@testset "Derivations" begin
    clue = "aerial worker anne on the way up"
    pattern = r"^.{7}$"
    solutions, state = CC.solve(clue, pattern=pattern, min_grammar_score=2e-5)
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
