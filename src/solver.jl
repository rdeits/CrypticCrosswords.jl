function answer_similarity(word1::AbstractString, word2::AbstractString)
    if word2 in keys(SYNONYMS[]) && word1 in SYNONYMS[][word2]
        1.0
    else
        SemanticSimilarity.similarity(word1, word2)
    end
end

function solution_quality(arc::PassiveArc)
    @assert lhs(rule(arc)) === Clue()
    answer_similarity(definition(arc), wordplay(arc))
end

function definition(arc::PassiveArc)
    @assert lhs(rule(arc)) === Clue()
    first(output(x) for x in constituents(arc) if lhs(rule(x)) === Definition())
end

function wordplay(arc::PassiveArc)
    @assert lhs(rule(arc)) === Clue()
    first(output(x) for x in constituents(arc) if lhs(rule(x)) === Wordplay())
end

function solutions(chart::Chart)
    results = [(p, solution_quality(p)) for p in complete_parses(chart)]
    sort!(results, by=x -> x[2], rev=true)
    results
end

solve(clue::AbstractString, length::Integer, pattern::Regex=r"") = solve(clue, Context(length, length, IsWord), pattern)

function solve(clue::AbstractString, context::Context, pattern::Regex=r"")
    rules = cryptics_rules()
    grammar = Grammar(rules)
    tokens = normalize.(split(clue))
    chart = chart_parse(tokens, grammar, context, TopDown());
    results = solutions(chart)
    filter!(((arc, score),) -> occursin(pattern, wordplay(arc)), results)
    results
end
