@enum CapnpPtrEnum CapnpStruct CapnpList CapnpISP CapnpCapability

"""
    sizecode(::Type{T}) -> Int8

Map type T to Capnp size code.
"""
sizecode(::Type{T} where {T<:Union{Int8,UInt8          }})::Int8 = 2
sizecode(::Type{T} where {T<:Union{Int16,UInt16,Float16}})::Int8 = 3
sizecode(::Type{T} where {T<:Union{Int32,UInt32,Float32}})::Int8 = 4
sizecode(::Type{T} where {T<:Union{Int64,UInt64,Float64}})::Int8 = 5

function parseword_struct(w::UInt64)
    @assert w&3 == Int(CapnpStruct) "parseword_struct: $w is not a struct"
    b = ((w & 0xffff_fffc) % Int32) >> 2
    c = (w >> 32) % UInt16
    d = (w >> 48) % UInt16
    b, c, d
end

function parseword_list(w::UInt64)
    @assert w&3 == Int(CapnpList) "parseword_list: $w is not a list"
    b = ((w & 0xffff_fffc) % Int32) >> 2
    c = ((w >> 32) & 7) % Int8
    d = (w >> 35) % UInt32
    b, c, d
end

function parseword_isp(w::UInt64)
    @assert w&3 == Int(CapnpISP) "parseword_list: $w is not an ISP"
    b = ((w >> 2) & 1) % Int8
    c = ((w & 0xffff_fff8) >> 3) % UInt32
    d = (w >> 32) % UInt32
    b, c, d
end

function parseword_cap(w::UInt64)
    @assert w&3 == Int(CapnpCapability) "parseword_list: $w is not a capability"
    b = ((w & 0xffff_fffc) % Int32) >> 2
    c = (w >> 32) % Int32
    b, c, 0x00
end

function load_value(::Type{T}, words::Vector{UInt64}, widx::Int64, tidx::Int64)::T where {
        T<:Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,UInt64,Int64,Float32,Float64}}
    # Bounds check
    nwords = cld(tidx * sizeof(T), sizeof(UInt64))
    checkbounds(words, widx + nwords - 1)

    # Use pointer and unsafe_load to avoid creating views/ReinterpretArrays.
    # Get `p` as a pointer to type T, starting at words[widx]
    p = Ptr{T}(pointer(words, widx))
    GC.@preserve words unsafe_load(p, tidx)
end

function load_string(words::Vector{UInt64}, widx::Int64)
    # A capnp String (Text) is a CapnpList with szcode 2 (i.e. 1 byte
    # elements)
    offset, szcode, len = parseword_list(words[widx])
    @assert szcode == sizecode(UInt8) "szcode $szcode != $(sizecode(UInt8)) @$widx"

    # Data index
    didx = widx + offset + 1

    # Bounds check
    nwords = cld(len-1, sizeof(UInt64))
    checkbounds(words, didx + nwords - 1)

    # Use pointer and unsafe_string to avoid creating views/ReinterpretArrays.
    p = Ptr{UInt8}(pointer(words, didx))
    GC.@preserve words unsafe_string(p, len-1)
end

function load_data!(dest::AbstractArray{T,N}, words::Vector{UInt64}, widx::Int64,
                    sidxs::Vararg{Int64,S}) where {T,N,S}
    # Data can be CapnpList or CapnpISP (pointing to a CapnpList)
    # If we have a CapnpISP, we dereference it and pass it, recursively, to
    # load_data!.
    if CapnpPtrEnum(words[widx]&3) == CapnpISP
        lpsize, segoffset, segid = parseword_isp(words[widx])

        # For now we don't support "double landing pad"
        @assert lpsize == 0 "double landing pad not supported @$widx"

        # Calcualte landing pad index
        lidx = sidxs[segid+1] + segoffset
        #@show lidx

        return load_data!(dest, words, lidx, sidxs...)
    end

    # Data is a capnp List
    offset, szcode, len = parseword_list(words[widx])
    @assert szcode == sizecode(T) "szcode $szcode != $(sizecode(T)) @$widx"
    @assert len == length(dest) "len $len != $(length(dest)) @$widx"

    # Data index
    didx = widx + offset + 1

    # Bounds check src and dest
    nwords = cld(len * sizeof(T), sizeof(UInt64))
    checkbounds(words, didx + nwords - 1)
    checkbounds(dest, len) # redundant when @assert is enabled

    # Use pointer and unsafe_copyto! to avoid creating views/ReinterpretArrays.
    p = Ptr{T}(pointer(words, didx))
    GC.@preserve dest words unsafe_copyto!(pointer(dest), p, len)

    dest
end

"""
    segment_sizes(words::Vector{UInt64}, fidx::Int64) -> (sizes...,)

Returns a tuple containing the sizes of the segments of the Capnp frame starting
at `words[fidx]`.
"""
function segment_sizes(words::Vector{UInt64}, fidx::Int64)
    numsegs = load_value(UInt32, words, fidx, 1) + 1
    # We don't support empty frames (yet?)
    @assert numsegs != 0 "empty frame @$fidx"
    ntuple(i->load_value(UInt32, words, fidx, i+1), numsegs)
end

"""
    segment_idxs(words::Vector{UInt64}, fidx) -> (sidx, ..., nextfidx)

Returns a tuple containing the index of the each segment of the frame starting
at `words[fidx]` and the index of the start of the next frame.
"""
function segment_idxs(words::Vector{UInt64}, fidx::Int64)
    seg_sizes = segment_sizes(words, fidx)
    hdr_size = cld(length(seg_sizes)+1, 2) # 2 == sizeof(UInt64)/sizeof(UInt32)
    cumsum((fidx+hdr_size, seg_sizes...))
end

"""
    frame_idx(sidxs::Vararg{Int64,N}) -> fidx

Given a tuple of segment indices (as returned by `segment_idxs`), return the
index of the start of the frame containing those segments.  Note that the length
of `sidxs` should be one more than the number of segments in the frame (i.e. it
should include the index of the start of the next frame).
"""
function frame_idx(sidxs::Vararg{Int64,N})::Int64 where N
    hdr_size = cld(length(sidxs), 2) # 2 == sizeof(UInt64)/sizeof(UInt32)
    sidxs[1] - hdr_size
end

"""
    capnp_frame(::Type{T}, words::Vector{UInt64}, fidx; kwargs...)::T where {T}

Construct a `T` from the Capnp frame starting at index `fidx` of `words`.  Any
`kwargs` are passed on to the constructor.
"""
function capnp_frame(::Type{T}, words::Vector{UInt64}, fidx::Int64; kwargs...)::T where {T}
    @debug "frame @$fidx"
    sidxs = segment_idxs(words, fidx)
    T(words, sidxs[1], sidxs...; kwargs...)
end

# Default factory methods

const FactoryTuple = Tuple{Vector{UInt64}, Int64}

function default_factory(::Type{Tuple}, t::FactoryTuple)
    t
end

function default_factory(::Type{T}, t::FactoryTuple)::T where T
    T(t)
end

# No-data factory functions

function nodata_factory(::Type{T}, t::FactoryTuple)::T where T
    T(t; withdata=false)
end

function offset_factory(::Type{T}, t::FactoryTuple)::Tuple{T, Int64} where T
    fidx = t[2]
    (T(t; withdata=false), 8*(fidx-1))
end

function index_factory(::Type{T}, t::FactoryTuple)::Tuple{T, Int64} where T
    fidx = t[2]
    (T(t; withdata=false), fidx)
end

# CapnpReader

struct CapnpReader{T,F}
    words::Vector{UInt64}
end

"""
    CapnpReader(src)
    CapnpReader(type, src)
    CapnpReader(factory, type, src)

Construct a `CapnpReader{type,factory}` object for the data represented by
`src`, which can be an `AbstractString` (treated as a file name), an `IO`
onject, or a `Vector{UInt64}`.  If not given, `factory` defaults to
`default_factory` and `type` defaults to `Tuple`.
"""
function CapnpReader(factory::Function, ::Type{T}, words::Vector{UInt64}) where T
    CapnpReader{T,factory}(words)
end

function CapnpReader(::Type{T}, words::Vector{UInt64}) where T
    CapnpReader(default_factory, T, words)
end

function CapnpReader(words::Vector{UInt64})
    CapnpReader(Tuple, words)
end

function CapnpReader(factory::Function, ::Type{T}, src::IO) where T
    CapnpReader{T,factory}(mmap(src, Vector{UInt64}; shared=false))
end

function CapnpReader(factory::Function, ::Type{T}, src::AbstractString) where T
    ispath(src) || error("$src does not exist")
    isfile(src) || error("$src is not a file")
    CapnpReader{T,factory}(mmap(src, Vector{UInt64}; shared=false))
end

function CapnpReader(::Type{T}, src::Union{IO,AbstractString}) where T
    CapnpReader(default_factory, T, src)
end

function CapnpReader(src::Union{AbstractString,IO})
    CapnpReader(Tuple, src)
end

"""
    finalize(c::CapnpReader{T,F})

Calls `finalize` on `c.words` to "mummap" the data array (and close the
underlying file).
"""
function Base.finalize(c::CapnpReader{T,F}) where {T,F}
    finalize(c.words)
end

function Base.show(io::IO, c::CapnpReader{T,F}) where {T,F}
    print(io, "CapnpReader{$T,$F}($(length(c.words)) words)")
end

# Capnp frame iteration

function Base.iterate(iter::CapnpReader{T,F}, fidx::Int64=1) where {T,F}
    Base.isdone(iter, fidx) && return nothing

    seg_sizes = segment_sizes(iter.words, fidx)
    numsegs = length(seg_sizes)
    if numsegs == 2
        nextfidx = (fidx + 2 + seg_sizes[1] + seg_sizes[2]) % Int64
    else
        hdr_size = cld(numsegs+1, 2) # 2 == sizeof(UInt64)/sizeof(UInt32)
        nextfidx = (fidx + hdr_size + sum(seg_sizes)) % Int64
    end
    #@show fidx hdr_size seg_sizes nextfidx
    F(T, (iter.words, fidx)), nextfidx
end

function Base.IteratorSize(::Type{CapnpReader{T,F}}) where {T,F}
    Base.SizeUnknown()
end

function Base.isdone(iter::CapnpReader{T,F}, widx) where {T,F}
    widx > length(iter.words)
end

# eltype is return type of factory method, which can be anything for arbitrary
# factory functions.
function Base.IteratorEltype(::Type{CapnpReader{T,F}}) where {T,F}
    Base.EltypeUnknown()
end

# Default factory eltype

function Base.IteratorEltype(::Type{CapnpReader{T,default_factory}}) where {T}
    Base.HasEltype()
end

function Base.eltype(::Type{CapnpReader{T,default_factory}}) where {T}
    T
end

# No-data factory eltype

function Base.IteratorEltype(::Type{CapnpReader{T,nodata_factory}}) where {T}
    Base.HasEltype()
end

function Base.eltype(::Type{CapnpReader{T,nodata_factory}}) where {T}
    T
end

# Offset factory eltype

function Base.IteratorEltype(::Type{CapnpReader{T,offset_factory}}) where {T}
    Base.HasEltype()
end

function Base.eltype(::Type{CapnpReader{T,offset_factory}}) where {T}
    Tuple{T, Int64}
end

# Index factory eltype

function Base.IteratorEltype(::Type{CapnpReader{T,index_factory}}) where {T}
    Base.HasEltype()
end

function Base.eltype(::Type{CapnpReader{T,index_factory}}) where {T}
    Tuple{T, Int64}
end
