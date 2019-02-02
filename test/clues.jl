using Test
using CrypticCrosswords
using CrypticCrosswords: definition, wordplay

@testset "Known clues" begin
    known_clues = [
        ("canoe wrecked in large sea", 5, "sea", "ocean"), # should be "large sea"
        ("Carryall's gotta be upset", 7, "carryalls", "tote bag"),
        ("couch is unfinished until now", 4, "couch", "sofa"),
        ("cuts up curtains differently for those who use needles", 14, "those who use needles", "acupuncturists"),
        ("Desire bawdy slut", 4, "desire", "lust"),
        ("Dotty, Sue, Pearl, Joy", 8, "joy", "pleasure"),
        ("excitedly print Camus document", 10, "document", "manuscript"),
        ("in glee over unusual color", 10, "color", "olive green"),
        ("initial meetings disappoint rosemary internally", 6, "initial meetings", "intros"),
        ("Initially congoers like us eschew solving hints", 5, "hints", "clues"),
        ("initially babies are naked", 4, "naked", "bare"),
        ("hungary's leader, stuffy and bald", 8, "bald", "hairless"),
        ("male done mixing drink", 8, "drink", "lemonade"),
        ("mollify with fried sausage", 7, "mollify", "assuage"),
        ("M's Rob Titon pitching slider?", 10, "slider", "trombonist"),
        ("Significant ataxia overshadows choral piece", 7, "piece", "cantata"), # definition should actually be "choral piece"
        ("signore redefined districts", 7, "districts", "regions"),
        ("singers in special tosca production", 5, "singers", "altos"),
        ("sink graduate with sin", 5, "sink", "basin"),
        ("spin broken shingle", 7, "spin", "english"),
        ("stirs, spilling soda", 4, "stirs", "ados"),
        ("surprisingly rank height as important", 12, "important", "earthshaking"),
        ("they primarily play Diplomacy", 4, "diplomacy", "tact"),
        ("returning regal drink", 5, "drink", "lager"),
    ]

    @time for (clue, length, expected_definition, expected_wordplay) in known_clues
        @show clue
        solutions = @time solve(clue, Context(length, length, IsWord))
        (arc, output, score) = first(solutions)
        @test definition(arc) == expected_definition
        @test output == expected_wordplay
    end
end
