module Synonyms

using ..CrypticCrosswords: normalize

export SYNONYMS

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
    synonyms = parse_synonyms(joinpath(@__DIR__, "..", "corpora", "OpenOffice", "MyThes-1.0", "th_en_US_new.dat"))
    make_symmetric!(synonyms)
    remove_loops!(synonyms)
    remove_self_mentions!(synonyms)
    synonyms
end

const SYNONYMS = load_synonyms()

end
