@enum CapnpPtrEnum CapnpStruct CapnpList CapnpISP CapnpCapability

"""
    sizecode(::Type{T}) -> Int8

Map type T to Capnp size code.
"""
sizecode(::Type{T} where {T<:Union{Int8,UInt8          }})::Int8 = 2
sizecode(::Type{T} where {T<:Union{Int16,UInt16,Float16}})::Int8 = 3
sizecode(::Type{T} where {T<:Union{Int32,UInt32,Float32}})::Int8 = 4
sizecode(::Type{T} where {T<:Union{Int64,UInt64,Float64}})::Int8 = 5

function parseword(w::UInt64)
    parseword(w, Val(CapnpPtrEnum(w&3)))
end

function parseword(w::UInt64, ::Val{CapnpStruct})
    b = ((w & 0xffff_fffc) >> 2) % Int32
    c = (w >> 32) % UInt16
    d = (w >> 48) % UInt16
    CapnpStruct, b, c, d
end

function parseword(w::UInt64, ::Val{CapnpList})
    b = ((w & 0xffff_fffc) % Int32) >> 2
    c = ((w >> 32) & 7) % Int8
    d = (w >> 35) % UInt32
    CapnpList, b, c, d
end

function parseword(w::UInt64, ::Val{CapnpISP})
    b = ((w >> 2) & 1) % Int8
    c = ((w & 0xffff_fff8) >> 3) % UInt32
    d = (w >> 32) % UInt32
    CapnpISP, b, c, d
end

function parseword(w::UInt64, ::Val{CapnpCapability})
    b = ((w & 0xffff_fffc) % Int32) >> 2
    c = (w >> 32) % Int32
    CapnpCapability, b, c, 0x00
end

function load_value(::Type{T}, words::Vector{UInt64}, widx::Int64, tidx::Int64)::T where {
        T<:Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,UInt64,Int64,Float32,Float64}}
    # Bounds check
    nw = cld(tidx * sizeof(T), sizeof(UInt64))
    checkbounds(words, widx + nw - 1)

    # Use pointer and unsafe_load to avoid creating views/ReinterpretArrays.
    # Get `p` as a pointer to type T, starting at words[widx]
    p = Ptr{T}(pointer(words, widx))
    GC.@preserve words unsafe_load(p, tidx)
end

function load_string(words::Vector{UInt64}, widx::Int64)
    ptype, offset, szcode, len = parseword(words[widx])

    # A capnp String (Text) is a CapnpList with szcode 2 (i.e. 1 byte
    # elements)
    @assert ptype == CapnpList "ptype $ptype @$widx"
    @assert szcode == sizecode(UInt8) "szcode $szcode != $(sizecode(UInt8)) @$widx"

    # Data index
    didx = widx + offset + 1

    # Bounds check
    nw = cld(len-1, sizeof(UInt64))
    checkbounds(words, didx + nw - 1)

    # Use pointer and unsafe_string to avoid creating views/ReinterpretArrays.
    p = Ptr{UInt8}(pointer(words, didx))
    GC.@preserve words unsafe_string(p, len-1)
end

function load_data!(dest::AbstractArray{T}, words::Vector{UInt64}, widx::Int64,
                    segidxs::Tuple{Int64,Vararg{Int64}}) where {T}
    # Data can be CapnpList or CapnpISP (pointing to a CapnpList)
    # If we have a CapnpISP, we dereference it and pass it, recursively, to
    # load_data!.
    if CapnpPtrEnum(words[widx]&3) == CapnpISP
        _, lpsize, segoffset, segid = parseword(words[widx])

        # For now we don't support "double landing pad"
        @assert lpsize == 0 "double landing pad not supported @$widx"

        # Calcualte landing pad index
        lidx = segidxs[segid+1] + segoffset
        #@show lidx

        return load_data!(dest, words, lidx, segidxs)
    end

    ptype, offset, szcode, len = parseword(words[widx])

    # Data is a capnp List
    @assert ptype == CapnpList "ptype $ptype @$widx"
    @assert szcode == sizecode(T) "szcode $szcode != $(sizecode(T)) @$widx"
    @assert len == length(dest) "len $len != $(length(dest)) @$widx"

    # Data index
    didx = widx + offset + 1

    # Bounds check src and dest
    nw = cld(len * sizeof(T), sizeof(UInt64))
    checkbounds(words, didx + nw - 1)
    checkbounds(dest, len) # redundant when @assert is enabled

    # Use pointer and unsafe_copyto! to avoid creating views/ReinterpretArrays.
    p = Ptr{T}(pointer(words, didx))
    GC.@preserve dest words unsafe_copyto!(pointer(dest), p, len)

    dest
end

function segment_sizes(capnp::Vector{UInt64}, widx)
    @debug "frame @$widx"
    numsegs = load_value(UInt32, capnp, widx, 1) + 1
    ntuple(i->load_value(UInt32, capnp, widx, i+1), numsegs)
end

# CapnpReader

struct CapnpReader
    words::Vector{UInt64}
end

function CapnpReader(io::IO)
    CapnpReader(mmap(io, Vector{UInt64}; shared=false))
end

function CapnpReader(fname::AbstractString)
    CapnpReader(mmap(fname, Vector{UInt64}; shared=false))
end

"""
    finalize(c::CapnpReader)

Calls `finalize` on `c.words` to "mummap" the data array (and close the
underlying file).
"""
function Base.finalize(c::CapnpReader)
    finalize(c.words)
end

function Base.show(io::IO, cr::CapnpReader)
    print(io, "CapnpReader($(length(cr.words)) words)")
end

# Capnp frame iteration

function Base.iterate(iter::CapnpReader, widx::Int64=1)
    Base.isdone(iter, widx) && return nothing

    sizes = segment_sizes(iter.words, widx)
    nw = cld((length(sizes)+1)*sizeof(UInt32), sizeof(UInt64))
    segidxs = ntuple(length(sizes)) do i
        i == 1 ? (widx+nw) : (widx+nw+sizes[i-1])
    end
    nextidx = (widx + nw + sum(sizes)) % Int64
    #@show widx nw sizes segidxs nextidx
    (iter.words, widx+nw, segidxs), nextidx
end

function Base.IteratorSize(::Type{CapnpReader})
    Base.SizeUnknown()
end

function Base.IteratorEltype(::Type{CapnpReader})
    Base.HasEltype()
end

function Base.eltype(::Type{CapnpReader})
    Tuple{Vector{UInt64}, Int64, Tuple{Int64,Vararg{Int64}} where N}
end

function Base.isdone(iter::CapnpReader, widx)
    widx > length(iter.words)
end
