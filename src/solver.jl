struct SolverState
    # arcs::Dict{Arc{Rule}, Dict{String, Vector{NTuple{N, String}}} where N}
    arcs::Dict{Arc{Rule}, Set{String}}
end

SolverState() = SolverState(Dict())

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
        inputs = [solve!(state, c) for c in constituents(arc)]
        _apply(rule(arc), inputs)
    end
end

@generated function _product(inputs, ::Val{N}) where {N}
    Expr(:call, :product, [:(inputs[$i]) for i in 1:N]...)
end

function apply(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs) where {N}
    # result = Dict{String, Vector{NTuple{N, String}}}()
    # buffer = Vector{String}()
    result = Set{String}()
    for input in _product(inputs, Val{N}())
        # empty!(buffer)
        apply!(result, head, args, input)
        # apply!(buffer, head, args, input)
        # for output in buffer
        #     push!(
        #     push!(get!(Vector{NTuple{N, String}}, result, output), input)
        # end
    end
    result
end

# solve!(state::SolverState, s::AbstractString) = Dict{String, Vector{Vector{String}}}(s => [])
solve!(state::SolverState, s::AbstractString) = Set([s])

struct SolvedArc
    arc::Arc{Rule}
    output::String
    similarity::Float64
end

function output_checker(len::Union{Integer, Nothing}, pattern::Regex)
    return word -> ((len === nothing || num_letters(word) == len) && is_word(word) && occursin(pattern, word))
end

function solve(clue;
        length::Union{Integer, Nothing} = nothing,
        pattern::Regex = r"",
        strategy = BottomUp(),
        min_grammar_score = 1e-5)
    state = SolverState()
    tokens = normalize.(split(clue))
    grammar = CrypticsGrammar()
    check = output_checker(length, pattern)

    function is_solvable(arc)
        if score(arc) < min_grammar_score
            return 0
        end
        outputs = solve!(state, arc)
        isempty(outputs)
        if isempty(outputs)
            return 0
        else
            return 1
        end
    end
    parser = ChartParser(tokens, grammar, BottomUp(),
                         is_solvable)
    solutions = SolvedArc[]
    for arc in Iterators.filter(is_complete(parser), parser)
    # for arc in parser
        if score(arc) < min_grammar_score
            continue
        end
        # TODO: probably don't need to call solve!() here
        outputs = solve!(state, arc)
        @assert !isempty(outputs)
        # for (output, inputs) in outputs
        for output in outputs
            if check(output)
                push!(solutions, SolvedArc(arc, output,
                                           solution_quality(arc, output)))
            end
        end
    end
    sort!(solutions, by=s -> s.similarity, rev=true)
    solutions, state
end

struct DerivedArc
    arc::Arc{Rule}
    output::String
    constituents::Vector{Union{DerivedArc, String}}
end

function derive(arc::Arc{Rule}, target::AbstractString, state::SolverState)
    result = DerivedArc[]
    for inputs in solve!(state, arc)[target]
        for children in product(derive.(constituents(arc), inputs, Ref(state))...)
            push!(result, DerivedArc(arc, target, collect(children)))
        end
    end
    result
end

derive(s::AbstractString, t::AbstractString, state::SolverState) = [t]

derive(solved::SolvedArc, state::SolverState) = derive(solved.arc, solved.output, state)

_show(io::IO, arc::DerivedArc) = print(io, arc)
_show(io::IO, s::AbstractString) = print(io, '"', s, '"')

function Base.show(io::IO, arc::DerivedArc)
    print(io, "($(lhs(rule(arc.arc))) -> ")
    for c in arc.constituents
        _show(io, c)
        print(io, " ")
    end
    print(io, "; $(score(arc.arc))) -> \"$(arc.output)\")")
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
    if word2 in keys(CACHE[].synonyms) && word1 in CACHE[].synonyms[word2]
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

definition(arc::SolvedArc) = definition(arc.arc)

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
