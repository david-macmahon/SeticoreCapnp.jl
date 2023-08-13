# Included by hit.jl

struct HitsFile
    io::IO
    traversal_limit_in_words::Int64
end

"""
    HitsFile(fname::AbstractString; traversal_limit_in_words=2^30)
    HitsFile(fname::AbstractString, mode; traversal_limit_in_words=2^30)

Open `fname` and create a `HitsFile` struct that wraps the `IO` and supports
iterating over the Hits in the file.  Each iteration of a `HitsFile` yields a
tuple of metadata (an `OrderedDict{Symbol,Any}`) and data (a `Matrix{Float32}`)
of a Hit.
```
"""
function HitsFile(fname::AbstractString; traversal_limit_in_words=2^30)
    HitsFile(open(fname), traversal_limit_in_words)
end

function HitsFile(fname::AbstractString, mode; traversal_limit_in_words=2^30)
    HitsFile(open(fname, mode), traversal_limit_in_words)
end

# Iteration

function Base.iterate(hf::HitsFile, offset=lseek(hf.io))
    Base.isdone(hf, offset) && return nothing
    md = load_hit(hf.io, offset; traversal_limit_in_words=hf.traversal_limit_in_words)
    md, lseek(hf.io)
end

function Base.IteratorSize(::Type{HitsFile})
    Base.SizeUnknown()
end

function Base.IteratorEltype(::Type{HitsFile})
    Base.HasEltype()
end

function Base.eltype(::Type{HitsFile})
    Tuple{OrderedDict{Symbol,Any}, Matrix{Float32}, Int64}
end

function Base.isdone(hf::HitsFile, offset=lseek(hf.io))
    offset == filesize(hf.io)
end
