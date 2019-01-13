using Pkg
pkg"activate ."

using Test
using CrypticCrosswords
const CC = CrypticCrosswords

include("test/clues.jl")

# clue = "initially babies are naked"
# rules = CC.cryptics_rules()
# grammar = CC.Grammar(rules)
# tokens = split(clue)
# chart = CC.chart_parse(tokens, grammar, CC.TopDown());

# # clue = "male done mixing drink"
# # clue = "absmoo thief straddle drink"
# rules = CC.cryptics_rules()
# grammar = CC.Grammar(rules)
# tokens = split(clue)
# context = CC.Context(4, 4, CC.IsWord)
# chart = CC.chart_parse(tokens, grammar, context, CC.TopDown());

# @show length(CC.complete_parses(chart))

# println("======================================")

# for p in CC.complete_parses(chart)
#     println(p)
# end

# println("--------------------------------------")

# for p in CC.solutions(chart)
#     println(p)
# end

# using ProfileView
# using Profile
# Profile.clear()
# clue = "initially babies are naked"
# clue = "spin broken shingle"
# clue = "healthy competent boy nearly died"
# @profile CC.solve(clue, context, CC.TopDown())
# @time solutions = CC.solve(clue, context, CC.TopDown())
# @show first(solutions)
# Profile.clear()
# @profile CC.solve(clue, context, CC.TopDown())
# ProfileView.view()

