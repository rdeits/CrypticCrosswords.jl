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

@generated function SFCVector{N, T}(x::NTuple{N2, T}) where {N, T, N2}
    args = []
    for i in 1:N2
        push!(args, :(x[$i]))
    end
    for i in (N2 + 1):N
        push!(args, :(x[$N2]))
    end
    quote
        $N2 <= $N || throw(ArgumentError("Tuple with $N2 elements is too long for SFCVector{$N}"))
        SFCVector{$N, $T}($N2, $(Expr(:tuple, args...)))
    end
end

SFCVector{N}(x::NTuple{N2, T}) where {N, T, N2} = SFCVector{N, T}(x)

Base.convert(::Type{<:SFCVector{N}}, x::NTuple) where {N} = SFCVector{N}(x)

end
