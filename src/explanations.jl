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
    println(io, "\"$(indicator.output)\" means to take the first letter of \"$(argument.constituents[1].output)\" to get \"$(output)\".")
end

explain(io::IO, output, lhs::Substring, rhs::Tuple{Initials, InitialsIndicator}, constituents) = explain(io, output, lhs, reverse(rhs), reverse(constituents))

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
    println(io, "\"$(solution.output)\" matches \"$(definition(solution.derivation.arc))\" with confidence $(solution.similarity).")
end

explain(x) = explain(stdout, x)
