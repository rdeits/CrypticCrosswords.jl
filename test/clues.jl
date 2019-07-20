using Test
using CrypticCrosswords
using CrypticCrosswords: definition

@testset "Known clues" begin
    known_clues = [
        ("Ach, Cole wrecked something in the ear", 7, "something in the ear", "cochlea"),
        ("aerial worker anne on the way up", 7, "aerial", "antenna"),
        ("at first congoers like us eschew solving hints", 5, "hints", "clues"),
        ("attractive female engraving", 8, "attractive", "fetching"),
        ("canoe wrecked in large sea", 5, "large sea", "ocean"),
        ("Carryall's gotta be upset", 7, "carryalls", "tote bag"),
        ("couch is unfinished until now", 4, "couch", "sofa"),
        ("cuts up curtains differently for those who use needles", 14, "those who use needles", "acupuncturists"),
        ("Desire bawdy slut", 4, "desire", "lust"),
        ("Dotty, Sue, Pearl, Joy", 8, "joy", "pleasure"),
        ("Endlessly long months and months", 4, "months and months", "year"),
        ("excitedly print Camus document", 10, "document", "manuscript"),
        ("Father returning ring with charm", 6, "charm", "appeal"),
        ("form of licit sea salt", 8, "salt", "silicate"),
        ("improve meal or I eat nuts", 10, "improve", "ameliorate"),
        ("initial meetings disappoint rosemary internally", 6, "initial meetings", "intros"),
        ("Initially congoers like us eschew solving hints", 5, "hints", "clues"),
        ("initially babies are naked", 4, "naked", "bare"),
        ("it's lunacy for dam to back onto ness", 7, "its lunacy", "madness"),
        ("hungary's leader, stuffy and bald", 8, "bald", "hairless"),
        ("male done mixing drink", 8, "drink", "lemonade"),
        ("measuring exotic flowers", 9, "flowers", "geraniums"),
        ("model unusually creepy hat", 9, "model", "archetype"),
        ("mollify with fried sausage", 7, "mollify", "assuage"),
        ("M's Rob Titon pitching slider?", 10, "slider", "trombonist"),
        ("Orchestra: I'm reorganizing conductor", 11, "conductor", "choirmaster"),
        ("Partially misconstrue fulminations; sorry", 6, "sorry", "rueful"),
        ("Propane explodes, theoretically", 7, "theoretically", "on paper"),
        ("Reap pleasure holding fruit", 5, "fruit", "apple"),
        ("Recover via fantastic miracle", 7, "recover", "reclaim"),
        ("returning regal drink", 5, "drink", "lager"),
        ("she literally describes high society", 5, "high society", "elite"),
        ("Significant ataxia overshadows choral piece", 7, "piece", "cantata"), # definition should actually be "choral piece"
        ("signore redefined districts", 7, "districts", "regions"),
        ("Sing gist of laudatory ode loudly", 5, "sing", "yodel"),
        ("singers in special tosca production", 5, "singers", "altos"),
        ("sink graduate with sin", 5, "sink", "basin"),
        ("spin broken shingle", 7, "spin", "english"),
        ("St. Michael transforms metal transformer", 9, "transformer", "alchemist"), # should be "metal transformer"
        ("stirs, spilling soda", 4, "stirs", "ados"),
        ("surprisingly rank height as important", 12, "important", "earthshaking"),
        ("they primarily play Diplomacy", 4, "diplomacy", "tact"),
        ("trimmed complicated test", 7, "test", "midterm"),
    ]

    badly_ranked_clues = [
        ("in glee over unusual color", 10, "color", "olive green"), # TODO: this is solvable, but we get "green olive" equally highly ranked
        ("anagram marvellously conceals structure of language", 7, "language", "grammar"),
        ("clean oneself, but in reverse", 3, "clean oneself", "tub"),
        ("Damaged credential tied together", 10, "tied together", "interlaced"),
        ("during exam I diagrammed viscera", 4, "during", "amid"),
        ("fish or insect for captain", 7, "fish or insect", "skipper"),
        ("figure out price he'd restructured", 8, "figure out", "decipher"),
        ("Inherently helps students over here", 4, "over here", "psst"),
        ("made mistake in deer reduction", 5, "made mistake", "erred"),
        # ("join trio of astronomers in marsh", 6, "join", "fasten"), # TODO: fix these clues. Weirdly low grammar scores.
        # ("sat up, interrupting sibling's balance", 6, "balance", "stasis"),
        ("setting for a cello composition", 6, "setting", "locale"),
        ("small bricks included among durable goods", 4, "small bricks", "lego"),
        ("waste pores vent exhausted resources", 9, "exhausted resources", "overspent"),

    ]

    @time for (clue, length, expected_definition, expected_wordplay) in known_clues
        @show clue
        solutions, state = @time solve(clue, length=length)
        arc = first(solutions)
        @test definition(arc) == expected_definition || endswith(expected_definition, definition(arc))
        @test arc.output == expected_wordplay
        derivations = Iterators.flatten([derive!(state, s) for s in Iterators.take(solutions, 10)])
    end

    @time for (clue, length, expected_definition, expected_wordplay) in badly_ranked_clues
        @show clue
        solutions, state = @time solve(clue, length=length)
        @test any(solutions) do arc
            definition(arc) == expected_definition && arc.output == expected_wordplay
        end
        derivations = Iterators.flatten([derive!(state, s) for s in Iterators.take(solutions, 10)])
    end
end
