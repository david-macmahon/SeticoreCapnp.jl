# Included by stamp.jl

struct StampsFile
    io::IO
    traversal_limit_in_words::Int64
end

"""
    StampsFile(fname::AbstractString; traversal_limit_in_words=2^30)
    StampsFile(fname::AbstractString, mode; traversal_limit_in_words=2^30)

Open `fname` and create a `StampsFile` struct that wraps the `IO` and supports
iterating over the Stamps in the file.  Each iteration of a `StampsFile` yields
a tuple of metadata (an `OrderedDict{Symbol,Any}`) and data (an
`Array{Float32,4}`) of a Stamp.
```
"""
function StampsFile(fname::AbstractString; traversal_limit_in_words=2^30)
    StampsFile(open(fname), traversal_limit_in_words)
end

function StampsFile(fname::AbstractString, mode; traversal_limit_in_words=2^30)
    StampsFile(open(fname, mode), traversal_limit_in_words)
end

# Iteration

function Base.iterate(sf::StampsFile, offset=lseek(sf.io))
    Base.isdone(sf, offset) && return nothing
    md = load_stamp(sf.io, offset; traversal_limit_in_words=sf.traversal_limit_in_words)
    md, lseek(sf.io)
end

function Base.IteratorSize(::Type{StampsFile})
    Base.SizeUnknown()
end

function Base.IteratorEltype(::Type{StampsFile})
    Base.HasEltype()
end

function Base.eltype(::Type{StampsFile})
    Tuple{OrderedDict{Symbol,Any}, Array{Float32,4}}
end

function Base.isdone(sf::StampsFile, offset=lseek(sf.io))
    offset == filesize(sf.io)
end
