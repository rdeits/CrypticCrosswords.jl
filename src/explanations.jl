function explain(io::IO, ::String)
    # nothing
end

function explain(io::IO, output, ::Definition, ::Any, constituents)
    println(io, "\"$output\" is the definition.")
end

function explain(io::IO, output, ::GrammaticalSymbol, ::Any, constituents)
    # nothing
end

function explain(io::IO, output, ::Anagram, ::Tuple{AnagramIndicator, Any}, constituents)
    println(io, "\"$(constituents[1].output)\" means to anagram \"$(constituents[2].output)\" to get \"$(output)\".")
end

function explain(io::IO, output, ::Substring, ::Tuple{InitialsIndicator, Initials}, (indicator, argument))
    println(io, "\"$(indicator.output)\" means to take the first letter$(length(argument.output) > 1 ? "s" : "") of \"$(argument.constituents[1].output)\" to get \"$(output)\".")
end

explain(io::IO, output, lhs::Substring, rhs::Tuple{Initials, InitialsIndicator}, constituents) = explain(io, output, lhs, reverse(rhs), reverse(constituents))

function explain(io::IO, output, ::Substring, ::Tuple{AbstractIndicator, Any}, (indicator, argument))
    println(io, "\"$(indicator.output)\" means to take a substring of \"$(argument.output)\" to get \"$(output)\".")
end

explain(io::IO, output, lhs::Substring, rhs::Tuple{Any, AbstractIndicator}, constituents) = explain(io, output, lhs, reverse(rhs), reverse(constituents))

explain(io::IO, output, lhs::Anagram, rhs::Tuple{Any, AnagramIndicator}, constituents) = explain(io, output, lhs, reverse(rhs), reverse(constituents))

function explain(io::IO, output, ::Wordplay, ::Tuple{Wordplay, Wordplay}, constituents)
    println(io, "Combine \"$(constituents[1].output)\" and \"$(constituents[2].output)\" to get \"$(output)\".")
end

function explain(io::IO, output, ::Synonym, ::Any, (word,))
    println(io, "Take a synonym of \"$(word.output)\" to get \"$(output)\".")
end

function explain(io::IO, output, ::Reversal, ::Tuple{ReversalIndicator, Any}, (indicator, argument))
    println(io, "\"$(indicator.output)\" means to reverse \"$(argument.output)\" to get \"$(output)\".")
end

explain(io::IO, output, lhs::Reversal, rhs::Tuple{Any, ReversalIndicator}, constituents) = explain(io, output, lhs, reverse(rhs), reverse(constituents))

function explain(io::IO, output, ::Straddle, ::Tuple{StraddleIndicator, Any}, (indicator, argument))
    println(io, "\"$(indicator.output)\" means to take the letters straddling the space in \"$(argument.output)\" to get \"$(output)\".")
end

explain(io::IO, output, lhs::Straddle, rhs::Tuple{Any, StraddleIndicator}, constituents) = explain(io, output, lhs, reverse(rhs), reverse(constituents))

function explain(io::IO, output, ::Synonym, ::Tuple{Phrase}, (phrase,))
    println(io, "Take a synonym of \"$(phrase.output)\" to get \"$(output)\".")
end

function explain(io::IO, output, ::Abbreviation, ::Tuple{Phrase}, (phrase,))
    println(io, "A common replacement for \"$(phrase.output)\" is \"$(output)\".")
end

# Explain how to insert A in B for all three positions of the indicator word
for position in 1:3
    arg_types = [GrammaticalSymbol, GrammaticalSymbol]
    insert!(arg_types, position, InsertABIndicator)
    args = [:a, :b]
    insert!(args, position, :indicator)

    @eval function explain(io::IO, output, ::Insertion, ::Tuple{$arg_types...}, $(Expr(:tuple, args...,)))
        println(io, "\"$(indicator.output)\" means to insert \"$(a.output)\" in \"$(b.output)\" to get \"$(output)\".")
    end
end

# Explain how to insert B in A for all three positions of the indicator word
for position in 1:3
    arg_types = [GrammaticalSymbol, GrammaticalSymbol]
    insert!(arg_types, position, InsertBAIndicator)
    args = [:b, :a]
    insert!(args, position, :indicator)

    @eval function explain(io::IO, output, ::Insertion, ::Tuple{$arg_types...}, $(Expr(:tuple, args...,)))
        println(io, "\"$(indicator.output)\" means to insert \"$(a.output)\" in \"$(b.output)\" to get \"$(output)\".")
    end
end

function explain(io::IO, arc::DerivedArc)
    for c in arc.constituents
        explain(io, c)
    end
    r = inner(rule(arc.arc))
    explain(io, arc.output, lhs(r), rhs(r), arc.constituents)
end

function explain(io::IO, solution::DerivedSolution)
    println(io, "The answer is \"$(solution.output)\".")
    explain(io, solution.derivation)
    println(io, "\"$(solution.output)\" matches \"$(definition(solution.derivation.arc))\" with confidence $(round(Int, 100 * solution.similarity))%.")
end

explain(x) = explain(stdout, x)
