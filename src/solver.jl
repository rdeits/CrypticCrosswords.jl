struct SolverState
    outputs::Dict{Arc{Rule}, Set{String}}
    derivations::Dict{Arc{Rule}, Dict{String, Vector{Vector{String}}}}
end

SolverState() = SolverState(Dict(), Dict())

@generated function _product(inputs, ::Val{N}) where {N}
    Expr(:call, :product, [:(inputs[$i]) for i in 1:N]...)
end

function apply(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs) where {N}
    result = Set{String}()
    for input in _product(inputs, Val{N}())
        apply!(result, head, args, input)
    end
    result
end

function _apply(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs::AbstractVector) where {N}
    apply(head, args, ntuple(i -> inputs[i], Val(N)))
end

function _apply(rule::Rule,
                constituents::AbstractVector)
    r = inner(rule)
    _apply(lhs(r), rhs(r), constituents)
end

solve!(state::SolverState, s::AbstractString) = Set([s])

function solve!(state::SolverState, arc::Arc{Rule})
    get!(state.outputs, arc) do
        inputs = [solve!(state, c) for c in constituents(arc)]
        _apply(rule(arc), inputs)
    end
end


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
        min_grammar_score = 1e-6,
        should_continue = () -> true)
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
    lowest_score_seen = Inf
    for arc in parser
        if !should_continue()
            break
        end
        if !is_complete(arc, parser)
            continue
        end
        @assert score(arc) <= lowest_score_seen
        lowest_score_seen = score(arc)
        if score(arc) < min_grammar_score
            break
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

struct DerivedSolution
    derivation::DerivedArc
    output::String
    similarity::Float64
end

function derive(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs, target) where {N}
    result = Vector{Vector{String}}()
    buffer = Vector{String}()
    for input in _product(inputs, Val{N}())
        empty!(buffer)
        apply!(buffer, head, args, input)
        input_vec = collect(input)
        for output in buffer
            if output == target
                push!(result, input_vec)
            end
        end
    end
    result
end

function _derive(head::GrammaticalSymbol, args::Tuple{Vararg{GrammaticalSymbol, N}}, inputs::AbstractVector, target::AbstractString) where {N}
    derive(head, args, ntuple(i -> inputs[i], Val(N)), target)
end

function _derive(rule::Rule,
                constituents::AbstractVector,
                target::AbstractString)
    r = inner(rule)
    _derive(lhs(r), rhs(r), constituents, target)
end

function find_derivations!(state::SolverState, arc::Arc{Rule}, target::AbstractString)
    arc_derivations = get!(state.derivations, arc) do
        Dict()
    end
    get!(arc_derivations, target) do
        inputs = [solve!(state, c) for c in constituents(arc)]
        _derive(rule(arc), inputs, target)
    end
end

derive!(state::SolverState, s::AbstractString, t::AbstractString) = [t]

function derive!(state::SolverState, arc::Arc{Rule}, target::AbstractString)
    result = DerivedArc[]
    input_lists = find_derivations!(state, arc, target)
    for inputs in input_lists
        for children in product(derive!.(Ref(state), constituents(arc), inputs)...)
            push!(result, DerivedArc(arc, target, collect(children)))
        end
    end
    result
end

function derive!(state::SolverState, solved::SolvedArc)
    derivations = derive!(state, solved.arc, solved.output)
    DerivedSolution.(derivations, Ref(solved.output), Ref(solved.similarity))
end

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

function answer_similarity(word1::AbstractString, word2::AbstractString)
    if word2 in keys(CACHE.synonyms) && word1 in CACHE.synonyms[word2]
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
