using Test
using CrypticCrosswords

@testset "Explanations" begin
    clue = "spin broken shingle"
    solutions, state = solve(clue, length=7)
    derivations = derive!(state, solutions[1])
    @test explain(first(derivations)) == """
The answer is "english"
"spin" is the definition.
"broken" means to anagram "shingle" to get "english"
"english" matches "spin" with confidence 1.0
"""

    clue = "initially babies are naked"
    solutions, state = solve(clue, length=4)
    derivations = derive!(state, solutions[1])
    @test explain(first(derivations)) == """
The answer is "bare"
"initially" means to take the first letter of "babies" to get "b"
Combine "b" and "are" to get "bare"
"naked" is the definition.
"bare" matches "naked" with confidence 1.0
"""

    clue = "hungary's leader, stuffy and bald"
    solutions, state = solve(clue, length=8)
    derivations = derive!(state, solutions[1])
    @test explain(first(derivations)) == """
The answer is "hairless"
"leader" means to take the first letter of "hungarys" to get "h"
Take a synonym of "stuffy" to get "airless"
Combine "h" and "airless" to get "hairless"
"bald" is the definition.
"hairless" matches "bald" with confidence 1.0
"""

end
