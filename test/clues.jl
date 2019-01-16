using Test
using CrypticCrosswords
using CrypticCrosswords: definition, wordplay

@testset "Known clues" begin
    known_clues = [
        ("initially babies are naked", 4, "naked", "bare"),
        ("spin broken shingle", 7, "spin", "english"),
        ("male done mixing drink", 8, "drink", "lemonade"),
        ("mollify with fried sausage", 7, "mollify", "assuage"),
        ("Dotty, Sue, Pearl, Joy", 8, "joy", "pleasure"),
        ("Initially congoers like us eschew solving hints", 5, "hints", "clues"),
        ("Significant ataxia overshadows choral piece", 7, "piece", "cantata"), # definition should actually be "choral piece"
        ("singers in special tosca production", 5, "singers", "altos"),
        ("Desire bawdy slut", 4, "desire", "lust"),
        ("Carryall's gotta be upset", 7, "carryalls", "tote bag"),
    ]

    for (clue, length, expected_definition, expected_wordplay) in known_clues
        solutions = solve(clue, Context(length, length, IsWord))
        (best, score) = first(solutions)
        @test definition(best) == expected_definition
        @test wordplay(best) == expected_wordplay
    end
end
