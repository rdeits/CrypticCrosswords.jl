struct PTrie{N}
    mask::UInt
    slots::BitSet
end

function PTrie{N}() where {N}
    slots = BitSet()
    mask = sum(1 << i for i in 0:(N - 1))
    PTrie{N}(mask, slots)
end

function Base.push!(p::PTrie, collection)
    h = zero(UInt)
    @inbounds for element in collection
        h = hash(element, h)
        push!(p.slots, h & p.mask)
    end
end

function Base.in(collection, p::PTrie)
    h = zero(UInt)
    @inbounds for element in collection
        h = hash(element, h)
        if (h & p.mask) ∉ p.slots
            return false
        end
    end
    (h & p.mask) in p.slots
end

function Base.getindex(p::PTrie, collection)
    h = zero(UInt)
    for element in collection
        h = hash(element, h)
        if (h & p.mask) ∉ p.slots
            return nothing
        end
    end
    return h
end

function has_concatenation(p::PTrie, h::UInt, suffix)
    @inbounds for element in suffix
        h = hash(element, h)
        if (h & p.mask) ∉ p.slots
            return false
        end
    end
    (h & p.mask) in p.slots
end

function has_concatenation(p::PTrie, collections::Vararg{String, N}) where {N}
    h = zero(UInt)
    for collection in collections
        @inbounds for element in collection
            h = hash(element, h)
            # if !p.slots[(h & p.mask) + 1]
            if (h & p.mask) ∉ p.slots
                return false
            end
        end
    end
    (h & p.mask) in p.slots
end
