abstract type AbstractStrategy end
struct BottomUp <: AbstractStrategy end
struct TopDown <: AbstractStrategy end

const RuleID = Pair{UInt, Vector{UInt}}
rule_id(rule::Rule) = RuleID(objectid(lhs(rule)), collect(objectid.(rhs(rule))))

abstract type AbstractArc end

struct PassiveArc <: AbstractArc
    start::Int
    stop::Int
    rule::Rule
    rule_id::RuleID
    constituents::Vector{PassiveArc}
    output::String
end

struct ActiveArc <: AbstractArc
    start::Int
    stop::Int
    rule::Rule
    rule_id::RuleID
    context::Context
    constituents::Vector{PassiveArc}
end

rule(arc::AbstractArc) = arc.rule
rule_id(arc::AbstractArc) = arc.rule_id
head(arc::AbstractArc) = lhs(rule_id(arc))
constituents(arc::AbstractArc) = arc.constituents

context(arc::ActiveArc) = arc.context
num_arguments(arc::AbstractArc) = length(rhs(rule_id(arc)))
num_completions(arc::AbstractArc) = length(constituents(arc))

is_complete(arc::ActiveArc) = num_completions(arc) == num_arguments(arc)
function next_needed(arc::ActiveArc)
    @assert !is_complete(arc)
    rhs(rule_id(arc))[num_completions(arc) + 1]
end

output(arc::PassiveArc) = arc.output

const Constituents = Vector{PassiveArc}
const Agenda = Vector{ActiveArc}

@generated function _apply(head::GrammaticalSymbol,
                           args::Tuple{Vararg{GrammaticalSymbol, N}},
                           constituents::Constituents) where {N}
    quote
        apply(head, args, $(Expr(:tuple, [:(constituents[$i].output) for i in 1:N]...)))
    end
end

function apply(rule::Rule,
                constituents::Constituents)
    _apply(lhs(rule), rhs(rule), constituents)
end


function solve(arc::ActiveArc)
    # @show arc
    @assert is_complete(arc)
    outputs = apply(rule(arc), constituents(arc))
    # @show outputs
    filter!(is_match(context(arc)), outputs)
    # @show outputs
    [PassiveArc(arc.start, arc.stop, rule(arc), rule_id(arc), constituents(arc), output) for output in outputs]
end

function Base.hash(arc::PassiveArc, h::UInt)
    h = hash(arc.start, h)
    h = hash(arc.stop, h)
    h = hash(rule_id(arc), h)
    for c in constituents(arc)
        h = hash(objectid(c), h)
    end
    h = hash(output(arc), h)
    h
end

function Base.:(==)(a1::PassiveArc, a2::PassiveArc)
    a1.start == a2.start || return false
    a1.stop == a2.stop || return false
    rule_id(a1) == rule_id(a2) || return false
    length(constituents(a1)) == length(constituents(a2)) || return false
    for i in eachindex(constituents(a1))
        a1.constituents[i] === a2.constituents[i] || return false
    end
    output(a1) == output(a2) || return false
    true
end

function combine(a1::ActiveArc, a2::PassiveArc)
    new_constituents = push(constituents(a1), a2)
    ActiveArc(a1.start, a2.stop, rule(a1), rule_id(a1), context(a1), new_constituents)
end

combine(a1::PassiveArc, a2::ActiveArc) = combine(a2, a1)

function Base.show(io::IO, arc::AbstractArc)
    expand(io, arc, 0)
end

name(s::GrammaticalSymbol) = typeof(s).name.name

function expand(io::IO, arc::AbstractArc, indentation=0)
    print(io, "(", arc.start, ", ", arc.stop, " ", name(lhs(rule(arc))))
    arguments = rhs(rule(arc))
    for i in eachindex(arguments)
        if length(arguments) > 1
            print(io, "\n", repeat(" ", indentation + 2))
        else
            print(io, " ")
        end
        if i > num_completions(arc)
            print(io, "(", name(arguments[i]), ")")
        else
            constituent = constituents(arc)[i]
            if constituent isa String
                print(io, "\"$constituent\"")
            else
                expand(io, constituent, indentation + 2)
            end
        end
    end
    if isa(arc, ActiveArc)
        print(io, " | ", context(arc))
    else
        print(io, " -> ", output(arc))
    end
    print(io, ")")
end

struct Chart
    num_tokens::Int
    active::Dict{UInt, Vector{Vector{ActiveArc}}} # organized by next needed constituent then by stop
    passive::Dict{UInt, Vector{Set{PassiveArc}}} # organized by head then by start
end

num_tokens(chart::Chart) = chart.num_tokens

Chart(num_tokens) = Chart(num_tokens,
                          Dict{UInt, Vector{Vector{ActiveArc}}}(),
                          Dict{UInt, Vector{Set{PassiveArc}}}())

function _active_storage(chart::Chart, next_needed::UInt, stop::Integer)
    v = get!(chart.active, next_needed) do
        [Vector{ActiveArc}() for _ in 0:num_tokens(chart)]
    end
    v[stop + 1]
end

function _passive_storage(chart::Chart, head::UInt, start::Integer)
    v = get!(chart.passive, head) do
        [Set{PassiveArc}() for _ in 0:num_tokens(chart)]
    end
    v[start + 1]
end

storage(chart::Chart, arc::ActiveArc) = _active_storage(chart, next_needed(arc), arc.stop)
storage(chart::Chart, arc::PassiveArc) = _passive_storage(chart, head(arc), arc.start)

mates(chart::Chart, candidate::ActiveArc) = _passive_storage(chart, next_needed(candidate), candidate.stop)
mates(chart::Chart, candidate::PassiveArc) = _active_storage(chart, head(candidate), candidate.start)

function Base.push!(chart::Chart, arc::AbstractArc)
    push!(storage(chart, arc), arc)
end

Base.in(arc::AbstractArc, chart::Chart) = arc ∈ storage(chart, arc)

# TODO: generalize start token
complete_parses(chart::Chart) = filter(_passive_storage(chart, objectid(Clue()), 0)) do arc
    arc.stop == num_tokens(chart)
end

struct Grammar
    productions::Vector{Pair{Rule, RuleID}}
end

function Grammar(rules::AbstractVector{<:Rule})
    Grammar(Pair{Rule, RuleID}[rule => rule_id(rule) for rule in rules])
end

function initial_chart(tokens, grammar, context::Context, ::TopDown)
    chart = Chart(length(tokens))
    rule = Token() => ()
    id = rule_id(rule)
    for (i, token) in enumerate(tokens)
        push!(chart, PassiveArc(i - 1, i, rule, id, Constituents(), String(token)))
    end
    chart
end

function initial_agenda(tokens, grammar, context::Context, ::TopDown)
    agenda = Agenda()
    for (rule, rule_id) in grammar.productions
        if lhs(rule) == Clue()  # TODO get start symbol from grammar
            push!(agenda, ActiveArc(0, 0, rule, rule_id, context, Constituents()))
        end
    end
    agenda
end

struct Predictions
    predictions::Dict{Tuple{UInt, Int}, Vector{Context}}
end

Predictions() = Predictions(Dict{Tuple{UInt, Int}, Vector{Context}}())

"""
Returns `true` if the key was added, `false` otherwise.
"""
function maybe_push!(p::Predictions, (symbol, index, context)::Tuple{UInt, Int, Context})
    v = get!(() -> Vector{Context}(), p.predictions, (symbol, index))
    for i in eachindex(v)
        other_context = v[i]
        if context == other_context || context ⊆ other_context
            # This context is a subset of a context we've already added,
            # so there is no reason to make hypotheses about it
            return false
        elseif other_context ⊆ context
            # This context is a superset of a context we've already added,
            # so it is useful to make hypotheses about it. Furthermore,
            # we can completely replace the old context in our prediction
            # record with the new, more general, context.
            v[i] = context
            return true
        end
    end
    # This context is totally new, so it's useful for generating hypotheses
    # and we should add it to the record of predictions.
    push!(v, context)
    return true
end

function maybe_push!(chart::Chart, arc::ActiveArc)
    # We expect to avoid duplicate active arcs at the prediction stage, so
    # this should always return true
    # @assert arc ∉ chart
    push!(chart, arc)
    return true
end

function maybe_push!(chart::Chart, arc::PassiveArc)
    if arc ∈ chart
        return false
    else
        push!(chart, arc)
        return true
    end
end

function chart_parse(tokens, grammar, context::Context, strategy::AbstractStrategy)
    chart = initial_chart(tokens, grammar, context, strategy)
    agenda = initial_agenda(tokens, grammar, context, strategy)
    predictions = Predictions()

    while !isempty(agenda)
        candidate = pop!(agenda)
        # @show candidate
        if is_complete(candidate)
            # println("solving: ", candidate)
            for output in solve(candidate)
                # println("got output: ", output)
                update!(chart, agenda, output, grammar, predictions, strategy)
            end
        else
            update!(chart, agenda, candidate, grammar, predictions, strategy)
        end
    end
    chart
end

function matches_context(active::ActiveArc, passive::PassiveArc)
   is_match(propagate(active.context, active.rule, active.constituents), output(passive))
end

matches_context(p::PassiveArc, a::ActiveArc) = matches_context(a, p)

function update!(chart::Chart, agenda::Agenda, candidate::AbstractArc, grammar::Grammar, predictions::Predictions, strategy::AbstractStrategy)
    is_new = maybe_push!(chart, candidate)
    if !is_new
        return
    end
    for mate in mates(chart, candidate)
        # @show mate
        if matches_context(candidate, mate)
            push!(agenda, combine(candidate, mate))
        end
    end
    predict!(agenda, chart, candidate, grammar, predictions, strategy)
    # @show agenda
end

function predict!(agenda::Agenda, chart::Chart, candidate::ActiveArc, grammar::Grammar, predictions::Predictions, ::TopDown)
    new_context::Context = propagate(context(candidate), rule(candidate), constituents(candidate))
    if isempty(new_context)
        return
    end
    key = (next_needed(candidate), candidate.stop, new_context)
    is_new = maybe_push!(predictions, key)
    # show_key = (rhs(rule(candidate))[num_completions(candidate) + 1], candidate.stop, new_context)
    # @show show_key is_new
    if is_new
        for (rule, rule_id) in grammar.productions
            if candidate.stop + length(rhs(rule_id)) > num_tokens(chart)
                # There won't be enough tokens in the input to actually satisfy
                # this rule, so don't bother making a hypothesis with it.
                continue
            end
            if lhs(rule_id) == next_needed(candidate)
                hypothesis = ActiveArc(candidate.stop, candidate.stop, rule, rule_id,
                                       new_context, Constituents())
                # @show hypothesis
                push!(agenda, hypothesis)
            end
        end
    end
end

function predict!(agenda::Agenda, chart::Chart, candidate::PassiveArc, grammar::Grammar, predictions::Predictions, ::TopDown)
    # no predictions generated for passive arcs when using a top-down strategy
end
