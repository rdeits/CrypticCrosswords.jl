struct CompletedArc
    head::GrammaticalSymbol
    constituents::NTuple{N, CompletedArc} where N
    output::String
end

function Base.show(io::IO, arc::CompletedArc)
    expand(io, arc, 0)
end

function expand(io::IO, arc::CompletedArc, indentation=0)
    print(io, "(", name(arc.head))
    arguments = arc.constituents
    for i in eachindex(arguments)
        if length(arguments) > 1
            print(io, "\n", repeat(" ", indentation + 2))
        else
            print(io, " ")
        end
        constituent = arguments[i]
        expand(io, constituent, indentation + 2)
    end
    print(io, " -> ", arc.output)
    print(io, ")")
end

@generated function (_completed_arcs(head::GrammaticalSymbol, constituents::Vector{PassiveArc},
                         outputs::Vector{String},
                         derivations::Vector{NTuple{N, String}},
                         target::Union{AbstractString, Nothing}=nothing)::Vector{CompletedArc}) where {N}
    quote
        if typeof(head) === Token
            return [CompletedArc(head, (), outputs[])]
        end
        results = CompletedArc[]
        for (output, inputs) in zip(outputs, derivations)
            # @show output inputs
            if target !== nothing && output != target
                continue
            end
            # @show $(Expr(:tuple, [:(completed_arcs(constituents[$i], inputs[$i])) for i in 1:N]...))
            for completed_constituents in $(Expr(:call, :product, [:(completed_arcs(constituents[$i], inputs[$i])) for i in 1:N]...))
                # @show completed_constituents
                push!(results, CompletedArc(head, completed_constituents, output))
            end
        end
        results
    end
end

function completed_arcs(arc::PassiveArc, target::Union{AbstractString, Nothing}=nothing)::Vector{CompletedArc}
    # results = CompletedArc[]
    # for (output, inputs) in zip(arc.outputs, arc.derivations)
    #     if target !== nothing && output != target
    #         continue
    #     end
    #     for constituents in product(completed_arcs.(arc.constituents, inputs)...)
    #         push!(results, CompletedArc(lhs(rule(arc)), collect(constituents), output))
    #     end
    # end
    # results
    _completed_arcs(lhs(rule(arc)), constituents(arc), outputs(arc), arc.derivations, target)
end

function completed_arcs(chart::Chart)
    parses = complete_parses(chart)
    results = CompletedArc[]
    for passive_arc in parses
        append!(results, completed_arcs(passive_arc,))
    end
    results
end

function answer_similarity(word1::AbstractString, word2::AbstractString)
    if word2 in keys(SYNONYMS[]) && word1 in SYNONYMS[][word2]
        1.0
    else
        SemanticSimilarity.similarity(word1, word2)
    end
end

function solution_quality(arc::PassiveArc, output::AbstractString)
    @assert lhs(rule(arc)) === Clue()
    answer_similarity(definition(arc), output)
end

function definition(arc::PassiveArc)
    @assert lhs(rule(arc)) === Clue()
    first(outputs(x)[] for x in constituents(arc) if lhs(rule(x)) === Definition())
end

function wordplay(arc::PassiveArc)
    @assert lhs(rule(arc)) === Clue()
    first(output(x) for x in constituents(arc) if lhs(rule(x)) === Wordplay())
end

function solutions(chart::Chart, context::Context, pattern::Regex)
    results = Tuple{PassiveArc, String, Float64}[]
    for p in complete_parses(chart)
        for output in p.outputs
            if is_match(context, output) && occursin(pattern, output)
                push!(results, (p, output, solution_quality(p, output)))
            end
        end
    end
    sort!(results, by = x -> x[3], rev = true)
    # results = [(p, solution_quality(p)) for p in complete_parses(chart)]
    # sort!(results, by=x -> x[2], rev=true)
    results
end

solve(clue::AbstractString, length::Integer, pattern::Regex=r"") = solve(clue, Context(length, length, IsWord), pattern)

function solve(clue::AbstractString, context::Context, pattern::Regex=r"")
    rules = cryptics_rules()
    grammar = Grammar(rules)
    tokens = normalize.(split(clue))
    chart = chart_parse(tokens, grammar, TopDown());
    results = solutions(chart, context, pattern)
    results
end
