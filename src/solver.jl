struct SolverState
    arcs::Dict{Arc{Rule}, Vector{String}}
end

SolverState() = SolverState(Dict{Arc{Rule}, Vector{String}}())

function _apply(rule::Rule,
                constituents::AbstractVector)
    r = inner(rule)
    _apply(lhs(r), rhs(r), constituents)
end

function _apply(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs::AbstractVector) where {N}
    apply(head, args, ntuple(i -> inputs[i], Val(N)))
end

function solve!(state::SolverState, arc::Arc{Rule})
    get!(state.arcs, arc) do
        inputs = solve!.(Ref(state), constituents(arc))
        _apply(rule(arc), inputs)
    end
end

solve!(state::SolverState, s::AbstractString) = [s]

function solve(clue)
    state = SolverState()
    tokens = normalize.(split(clue))
    grammar = CrypticsGrammar()
    parser = ChartParser(tokens, grammar)
    solutions = Tuple{Arc{Rule}, String, Float64}[]
    for arc in Iterators.filter(is_complete(parser), parser)
        outputs = solve!(state, arc)
        for output in outputs
            push!(solutions, (arc, output, solution_quality(arc, output)))
        end
    end
    solutions, state
end

# struct CompletedArc
#     head::GrammaticalSymbol
#     constituents::NTuple{N, CompletedArc} where N
#     output::String
# end

# function Base.show(io::IO, arc::CompletedArc)
#     expand(io, arc, 0)
# end

# function expand(io::IO, arc::CompletedArc, indentation=0)
#     print(io, "(", name(arc.head))
#     arguments = arc.constituents
#     for i in eachindex(arguments)
#         if length(arguments) > 1
#             print(io, "\n", repeat(" ", indentation + 2))
#         else
#             print(io, " ")
#         end
#         constituent = arguments[i]
#         expand(io, constituent, indentation + 2)
#     end
#     print(io, " -> ", arc.output)
#     print(io, ")")
# end

# @generated function (_completed_arcs(head::GrammaticalSymbol, constituents::Vector{PassiveArc},
#                          outputs::Vector{String},
#                          derivations::Vector{NTuple{N, String}},
#                          target::Union{AbstractString, Nothing}=nothing)::Vector{CompletedArc}) where {N}
#     quote
#         if typeof(head) === Token
#             return [CompletedArc(head, (), outputs[])]
#         end
#         results = CompletedArc[]
#         for (output, inputs) in zip(outputs, derivations)
#             # @show output inputs
#             if target !== nothing && output != target
#                 continue
#             end
#             # @show $(Expr(:tuple, [:(completed_arcs(constituents[$i], inputs[$i])) for i in 1:N]...))
#             for completed_constituents in $(Expr(:call, :product, [:(completed_arcs(constituents[$i], inputs[$i])) for i in 1:N]...))
#                 # @show completed_constituents
#                 push!(results, CompletedArc(head, completed_constituents, output))
#             end
#         end
#         results
#     end
# end

# function completed_arcs(arc::PassiveArc, target::Union{AbstractString, Nothing}=nothing)::Vector{CompletedArc}
#     # results = CompletedArc[]
#     # for (output, inputs) in zip(arc.outputs, arc.derivations)
#     #     if target !== nothing && output != target
#     #         continue
#     #     end
#     #     for constituents in product(completed_arcs.(arc.constituents, inputs)...)
#     #         push!(results, CompletedArc(lhs(rule(arc)), collect(constituents), output))
#     #     end
#     # end
#     # results
#     _completed_arcs(lhs(rule(arc)), constituents(arc), outputs(arc), arc.derivations, target)
# end

# function completed_arcs(chart::Chart)
#     parses = complete_parses(chart)
#     results = CompletedArc[]
#     for passive_arc in parses
#         append!(results, completed_arcs(passive_arc,))
#     end
#     results
# end

function answer_similarity(word1::AbstractString, word2::AbstractString)
    if word2 in keys(SYNONYMS[]) && word1 in SYNONYMS[][word2]
        1.0
    else
        SemanticSimilarity.similarity(word1, word2)
    end
end

function solution_quality(arc::Arc, output::AbstractString)
    @assert lhs(inner(rule(arc))) === Clue()
    answer_similarity(definition(arc), output)
end

tokens(arc::Arc) = join((tokens(x) for x in constituents(arc)), ' ')
tokens(s::AbstractString) = s

function definition(arc::Arc)
    @assert lhs(inner(rule(arc))) === Clue()
    tokens(first(x for x in constituents(arc) if lhs(inner(rule(x))) == Definition()))
end

num_letters(word::AbstractString) = count(!isequal(' '), word)

# function solutions(chart::Chart, len::Integer, pattern::Regex)
#     results = Tuple{PassiveArc, String, Float64}[]
#     for p in complete_parses(chart)
#         for output in p.outputs
#             if is_word(output) && num_letters(output) == len && occursin(pattern, output)
#                 push!(results, (p, output, solution_quality(p, output)))
#             end
#         end
#     end
#     sort!(results, by = x -> x[3], rev = true)
#     # results = [(p, solution_quality(p)) for p in complete_parses(chart)]
#     # sort!(results, by=x -> x[2], rev=true)
#     results
# end

# function solve(clue::AbstractString, len::Integer, pattern::Regex=r"")
#     rules = cryptics_rules()
#     grammar = Grammar(rules)
#     tokens = normalize.(split(clue))
#     filter!(!isempty, tokens)
#     chart = chart_parse(tokens, grammar, TopDown());
#     results = solutions(chart, len, pattern)
#     results
# end
