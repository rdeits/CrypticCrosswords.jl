using Test
using CrypticCrosswords

function solve_and_explain(clue, length)
    solutions, state = solve(clue, length=length)
    derivations = derive!(state, solutions[1])
    io = IOBuffer()
    explain(io, first(derivations))
    String(take!(io))
end

@testset "Explanations" begin

    @test solve_and_explain("spin broken shingle", 7) == """
The answer is "english".
"spin" is the definition.
"broken" means to anagram "shingle" to get "english".
"english" matches "spin" with confidence 100%.
"""

    @test solve_and_explain("initially babies are naked", 4) == """
The answer is "bare".
"initially" means to take the first letter of "babies" to get "b".
Combine "b" and "are" to get "bare".
"naked" is the definition.
"bare" matches "naked" with confidence 100%.
"""

    @test solve_and_explain("hungary's leader, stuffy and bald", 8) == """
The answer is "hairless".
"leader" means to take the first letter of "hungarys" to get "h".
Take a synonym of "stuffy" to get "airless".
Combine "h" and "airless" to get "hairless".
"bald" is the definition.
"hairless" matches "bald" with confidence 100%.
"""

    @test solve_and_explain("aerial worker anne on the way up", 7) == """
The answer is "antenna".
"aerial" is the definition.
A common replacement for "worker" is "ant".
"on the way up" means to reverse "anne" to get "enna".
Combine "ant" and "enna" to get "antenna".
"antenna" matches "aerial" with confidence 100%.
"""

end
