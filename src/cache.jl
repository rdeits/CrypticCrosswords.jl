struct Cache
    words::Set{String}
    synonyms::Dict{String, Set{String}}
    words_by_anagram::Dict{String, Vector{String}}
    abbreviations::Dict{String, Set{String}}
    substrings::PTrie{32}
    prefixes::PTrie{32}
    indicators::Dict{String, Vector{GrammaticalSymbol}}
end

const CACHE = Ref{Cache}()

function parse_heading(line)
    parts = split(line, '|')
    length(parts) == 2 || @show line parts
    word = parts[1]
    num_entries = parse(Int, parts[2])
    word, num_entries
end

function parse_entry(line)
    normalize.(split(line, '|')[2:end])
end

function add_synonyms!(synonyms, word, list)
    entries = get!(() -> Set{String}(), synonyms, word)
    for entry in list
        push!(entries, entry)
    end
end

function parse_synonyms(fname)
    @info("Parsing synonyms file...")
    synonyms = Dict{String, Set{String}}()
    open(fname) do file
        @assert readline(file) == "ISO8859-1"
        while true
            line = readline(file)
            if isempty(line)
                break
            end
            word, num_entries = parse_heading(line)
            for i in 1:num_entries
                add_synonyms!(synonyms, normalize(word), parse_entry(readline(file)))
            end
        end
    end
    @info("Done!")
    synonyms
end

function make_symmetric!(synonyms)
    for (word, entries) in synonyms
        for entry in entries
            push!(get!(() -> Set{String}(), synonyms, entry), word)
        end
    end
end

function remove_loops!(synonyms)
    for (word, entries) in synonyms
        if word in entries
            delete!(entries, word)
        end
    end
end

"""
Remove synonym entries which contain the original word. For example,
"spin" and "spin around" are listed as synonyms in the dataset, but
crossword rules don't allow the clue to contain part of the answer
like that.
"""
function remove_self_mentions!(synonyms)
    for (word, entries) in synonyms
        disallowed = String[]
        for entry in entries
            if occursin(word, entry) || occursin(entry, word)
                push!(disallowed, entry)
            end
        end
        for entry in disallowed
            delete!(entries, entry)
        end
    end
end

function load_synonyms()
    path = datadep"OpenOffice-MyThes-1.0/MyThes-1.0/th_en_US_new.dat"
    synonyms = parse_synonyms(path)
    make_symmetric!(synonyms)
    remove_loops!(synonyms)
    remove_self_mentions!(synonyms)
    synonyms
end

function Cache()
    synonyms = load_synonyms()
    words = Set{String}()
    words_by_anagram = Dict{String, Vector{String}}()
    abbreviations = Dict{String, Set{String}}()
    substrings = PTrie{32}()
    prefixes = PTrie{32}()
    indicators = Dict{String, Vector{GrammaticalSymbol}}()

    for word in keys(synonyms)
        push!(words, word)
    end
    for line in eachline(datadep"SCOWL-wordlist-en_US-large/en_US-large.txt")
        push!(words, normalize(line))
    end
    for word in words
        key = join(sort(collect(replace(word, " " => ""))))
        v = get!(Vector{String}, words_by_anagram, key)
        push!(v, word)
    end
    open(joinpath(@__DIR__, "..", "corpora", "mhl-abbreviations", "abbreviations.json")) do file
        for (word, abbrevs) in JSON.parse(file)
            abbreviations[normalize(word)] = Set(normalize.(abbrevs))
        end
    end
    open(joinpath(@__DIR__, "..", "corpora", "abbreviations.json")) do file
        for (word, abbrevs) in JSON.parse(file)
            s = get!(Set{String}, abbreviations, normalize(word))
            for a in abbrevs
                push!(s, a)
            end
        end
    end

    @showprogress "Substrings PTrie" for word in words
        push!(prefixes, word)
        word = replace(word, ' ' => "")
        for i in 1:length(word)
            push!(substrings, word[i:end])
        end
    end

    for (filename, part_of_speech) in [
        ("Anagram", AnagramIndicator()),
        ("Filler", Filler()),
        ("FinalSubstring", FinalSubstringIndicator()),
        ("InitialSubstring", InitialSubstringIndicator()),
        ("InsertAB", InsertABIndicator()),
        ("InsertBA", InsertBAIndicator()),
        ("Initials", InitialsIndicator()),
        ("Reversal", ReversalIndicator())]
        for line in eachline(joinpath(@__DIR__, "..", "corpora", "indicators", filename))
            phrase = normalize(strip(line))
            push!(get!(Vector{GrammaticalSymbol}, indicators, phrase), part_of_speech)
        end
    end
    Cache(words, synonyms, words_by_anagram, abbreviations, substrings, prefixes, indicators)
end

function update_cache!()
    CACHE[] = Cache()
    SemanticSimilarity.update_cache!()
end

