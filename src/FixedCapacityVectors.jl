module FixedCapacityVectors

export SFCVector, push

struct SFCVector{N, T} <: AbstractVector{T}
    length::Int
    data::NTuple{N, T}

    SFCVector{N, T}() where {N, T} = new{N, T}(0)
    SFCVector{N, T}(length::Integer, data::NTuple{N, T}) where {N, T} = new{N, T}(length, data)
end

Base.size(v::SFCVector) = (v.length,)

@inline function Base.getindex(v::SFCVector, i::Integer)
    @boundscheck (i >= 1 && i <= v.length) || throw(BoundsError())
    @inbounds v.data[i]
end

@generated function push(v::SFCVector{N, T}, x::T) where {N, T}
    quote
        @boundscheck (v.length < N) || throw(BoundsError())
        data = $(Expr(:tuple, [:($i <= v.length ? @inbounds(v[$i]) : x) for i in 1:N]...))
        SFCVector{N, T}(v.length + 1, data)
    end
end

function push(v::AbstractVector{T}, x::T) where {T}
    result = copy(v)
    push!(result, x)
    result
end

end
