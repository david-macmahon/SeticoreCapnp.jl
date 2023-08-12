# Juliafication of hit.capnp

"""
The `Signal` struct contains information about a linear signal we found.  Some
of this is redundant if the `Filterbank` is present, so that the `Signal` is
still useful on its own.
"""
struct Signal
    """
    The frequency the hit starts at
    """
    frequency::Float64
  
    """
    Which frequency bin the hit starts at.
    This is relative to the coarse channel.
    """
    index::Int32
  
    """
    How many bins the hit drifts over.  This counts the drift distance over the
    full rounded-up power-of-two time range.
    """
    driftSteps::Int32
  
    """
    The drift rate in Hz/s
    """
    driftRate::Float64
  
    """
    The signal-to-noise ratio for the hit
    ```
    snr = (power - median) / stdev
    ````
    """
    snr::Float32
  
    """
    Which coarse channel this hit is in
    """
    coarseChannel::Int32
  
    """
    Which beam this hit is in. -1 for incoherent beam, or no beam
    """
    beam::Int32

    """
    The number of timesteps in the associated filterbank.
    This does *not* use rounded-up-to-a-power-of-two timesteps.
    """
    numTimesteps::Int32

    """
    The total power that is normalized to calculate snr.
    ```
    snr = (power - median) / stdev
    ````
    """
    power::Float32

    """
    # The total power for the same signal, calculated incoherently.
    """
    incoherentPower::Float32
end

"""
    Signal(s)
Construct a `Signal` from capnp object `s`.
"""
function Signal(s)
    Signal(
        convert(Float64, s.frequency),
        convert(Int32,   s.index),
        convert(Int32,   s.driftSteps),
        convert(Float64, s.driftRate),
        convert(Float32, s.snr),
        convert(Int32,   s.coarseChannel),
        convert(Int32,   s.beam),
        convert(Int32,   s.numTimesteps),
        convert(Float32, s.power),
        convert(Float32, s.incoherentPower),
    )
end

"""
    Signal(d::AbstractDict)

Construct a `Signal` from `AbstractDict` object `d`, whose key type must be
`Symbol` or an `AbstractString`.
"""
function Signal(d::AbstractDict{T,Any}) where T<:Union{AbstractString,Symbol}
    Signal(
        # Maybe these converts are not needed?
        convert(Float64, d[T(:frequency)]),
        convert(Int32,   d[T(:index)]),
        convert(Int32,   d[T(:driftSteps)]),
        convert(Float64, d[T(:driftRate)]),
        convert(Float32, d[T(:snr)]),
        convert(Int32,   d[T(:coarseChannel)]),
        convert(Int32,   d[T(:beam)]),
        convert(Int32,   d[T(:numTimesteps)]),
        convert(Float32, d[T(:power)]),
        convert(Float32, d[T(:incoherentPower)]),
    )
end

# Omit redundant numTimesteps field from Signal Dict rather than Filterbank Dict
# because it was added to Signal after it was part of Filterbank so some hits
# files will not have Signal.numTimesteps.
const SignalDictFields = (
    :frequency,
    :index,
    :driftSteps,
    :driftRate,
    :snr,
    :coarseChannel,
    :beam,
    :power,
    :incoherentPower
)

function OrderedCollections.OrderedDict{Symbol,Any}(s::Signal)
    OrderedDict{Symbol,Any}(
        SignalDictFields .=> getfield.(Ref(s), SignalDictFields)
    )
end

function OrderedCollections.OrderedDict(s::Signal)
    OrderedCollections.OrderedDict{Symbol,Any}(s)
end

"""
The `Filterbank` struct contains a smaller slice of the larger filterbank that
we originally found this hit in.
"""
struct Filterbank
    # These fields are like the ones found in FBH5 files.
    sourceName::String
    fch1::Float64
    foff::Float64
    tstart::Float64
    tsamp::Float64
    ra::Float64  # Hours
    dec::Float64 # Degrees
    telescopeId::Int32
    numTimesteps::Int32
    numChannels::Int32

    # The format is a column-major array, indexed by [channel, timestep].
    data::Matrix{Float32}

    # Additional fields that don't correspond to FBH5 headers

    # Which of the coarse channels in the file this hit is in
    coarseChannel::Int32

    # Column zero in the data corresponds to this column in the whole coarse channel
    startChannel::Int32

    # Which beam this data is from. -1 for incoherent beam, or no beam
    beam::Int32
end

"""
    Filterbank(f)
Construct a `Filterbank` from capnp object `f`.
"""
function Filterbank(f)
    ntime = convert(Int32, f.numTimesteps)
    nchan = convert(Int32, f.numChannels)
    datavec = convert(Vector{Float32}, f.data)
    data = reshape(datavec, Int64(nchan), Int64(ntime))

    Filterbank(
        convert(String,  f.sourceName),
        convert(Float64, f.fch1),
        convert(Float64, f.foff),
        convert(Float64, f.tstart),
        convert(Float64, f.tsamp),
        convert(Float64, f.ra),
        convert(Float64, f.dec),
        convert(Int32,   f.telescopeId),
        ntime,
        nchan,
        data,
        convert(Int32,   f.coarseChannel),
        convert(Int32,   f.startChannel),
        convert(Int32,   f.beam)
    )
end

"""
    Filterbank(d::AbstractDict, data::Array)

Construct a `Filterbank` from `AbstractDict` object `d`, whose key type must be
`Symbol` or an `AbstractString`, and `data`.
"""
function Filterbank(d::AbstractDict{T,Any}, data::Array{Float32}) where T<:Union{AbstractString,Symbol}
    Filterbank(
        # Maybe these converts are not needed?
        convert(String,  d[T(:sourceName)]),
        convert(Float64, d[T(:fch1)]),
        convert(Float64, d[T(:foff)]),
        convert(Float64, d[T(:tstart)]),
        convert(Float64, d[T(:tsamp)]),
        convert(Float64, d[T(:ra)]),
        convert(Float64, d[T(:dec)]),
        convert(Int32,   d[T(:telescopeId)]),
        convert(Int32,   d[T(:numTimesteps)]),
        convert(Int32,   d[T(:numChannels)]),
        data,
        convert(Int32,   d[T(:coarseChannel)]),
        convert(Int32,   d[T(:startChannel)]),
        convert(Int32,   d[T(:beam)])
    )
end

function getdata(f::Filterbank)
    f.data
end

function getdata(::Nothing)
    Float32[;;]
end

# Omit data and redundant coarseChannel and beam fields from Filterbank Dict
const FilterbankDictFields = (
    :sourceName,
    :fch1,
    :foff,
    :tstart,
    :tsamp,
    :ra,
    :dec,
    :telescopeId,
    :numTimesteps,
    :numChannels,
    :startChannel,
)

function OrderedCollections.OrderedDict{Symbol,Any}(f::Filterbank)
    OrderedDict{Symbol,Any}(
        FilterbankDictFields .=> getfield.(Ref(f), FilterbankDictFields)
    )
end

function OrderedCollections.OrderedDict(f::Filterbank)
    OrderedCollections.OrderedDict{Symbol,Any}(f)
end

"""
A hit without a signal indicates that we looked for a hit here and didn't find one.
A hit without a filterbank indicates that to save space we didn't store any filterbank
data in this file; it should be available elsewhere.
"""
struct Hit
    signal::Union{Nothing,Signal}
    filterbank::Union{Nothing,Filterbank}
end

"""
    Hit(h)
Construct a `Hit` from capnp object `h`.
"""
function Hit(h)
    Hit(
        Signal(h.signal),
        Filterbank(h.filterbank)
    )
end

function getdata(h::Hit)
    getdata(h.filterbank)
end

function OrderedCollections.OrderedDict{Symbol,Any}(h::Hit)
    if h.signal === nothing && h.filterbank === nothing
        OrderedDict{Symbol,Any}()
    elseif h.signal === nothing
        OrderedDict(h.filterbank)
    elseif h.filterbank === nothing
        OrderedDict(h.signal)
    else
        merge(OrderedDict(h.signal), OrderedDict(h.filterbank))
    end
end

function OrderedCollections.OrderedDict(h::Hit)
    OrderedCollections.OrderedDict{Symbol,Any}(h)
end

"""
    load_hit(filename, offset; kwargs...) -> OrderedDict, Matrix{Float32}
    load_hit(io::IO[, offset]; kwargs...) -> OrderedDict, Matrix{Float32}

Load a single `Hit` from the given `offset` (or current position) within
`filename` or `io` and return the metadata fields as an
`OrderedDict{Symbol,Any}` and the "Filterbank" waterfall data as a
`Matrix{Float32}`.  The metadat includes a `:fileoffset` entry whose value is
`offset`.

The only supported `kwargs` is `traversal_limit_in_words` which sets the
maximmum size of a hit.  It default it 2^30 words.
"""
function load_hit(io::IO; traversal_limit_in_words=2^30)
    offset = lseek(io)
    hit = Hit(SeticoreCapnp.CapnpHit[].Hit.read(io; traversal_limit_in_words))
    data = getdata(hit)

    meta = OrderedDict(hit)
    meta[:fileoffset] = offset

    meta, data
end

function load_hit(io::IO, offset; traversal_limit_in_words=2^30)
    seek(io, offset)
    load_hit(io; traversal_limit_in_words)
end

function load_hit(hits_filename, offset; traversal_limit_in_words=2^30)
    open(hits_filename) do io
        load_hit(io, offset; traversal_limit_in_words)
    end
end

"""
    foreach_hit(f, filename; kwargs...)

For each `Hit` in the given `filename`, call `f` passing 
`OrderedDict{Symbol,Any}` metadata the "Filterbank" waterfall `Matrix` data.
The metadat includes a `:fileoffset` entry whose value is the offset of the
`Hit` within the input file. This offset can be used with `load_hit` if desired.

The only supported `kwargs` is `traversal_limit_in_words` which sets the
maximmum size of a hit.  It default it 2^30 words.
"""
function foreach_hit(f, hits_filename; traversal_limit_in_words=2^30)
    # TODO Make this into a proper Julia iterator
    n = filesize(hits_filename)
    open(hits_filename) do io
        while lseek(io) < n
            m, d = load_hit(io; traversal_limit_in_words)
            f(m, d)
            # Break if io's fd did not advance (should "never" happen)
            # (avoids pathological infinite loop)
            lseek(io) == m[:fileoffset] && break
        end
    end
    nothing
end

"""
    load_hits(filename; kwargs...) -> Vector{OrderedDict}, Vector{Matrix}

Load the `Hit`s from the given `filename` and return the metadata fields as a
`Vector{OrderedDict{Symbol,Any}}` and the "Filterbank" waterfall data as a
`Vector{Matrix}` whose elements correspond one-to-one with the entries of the
metadata `Vector`.  The metadata entries include a `:fileoffset` entry whose
value is the offset of the `Hit` within the input file. This offset can be used
with `load_hit` if desired.

The only supported `kwargs` is `traversal_limit_in_words` which sets the
maximmum size of a hit.  It default it 2^30 words.
"""
function load_hits(hits_filename; traversal_limit_in_words=2^30)
    meta = OrderedDict{Symbol,Any}[]
    data = Matrix{Float32}[]
    foreach_hit(hits_filename; traversal_limit_in_words) do m,d
        push!(meta, m)
        push!(data, d)
    end

    meta, data
end

function save_hits(hits_filename, hits::Vector{<:AbstractDict}, data::Vector{Matrix{Float32}})
    capnp = SeticoreCapnp.CapnpHit[]
    open(hits_filename, "w+") do io
        for (h, d) in zip(hits, data)
            s = capnp.Signal(; filter(kv->first(kv) in fieldnames(Signal), h)...)
            f = capnp.Filterbank(; filter(kv->first(kv) in fieldnames(Filterbank), h)...)
            dlist = f.init(:data, length(d))
            for i in eachindex(d)
                dlist[i] = d[i]
            end
            capnphit = capnp.Hit(; signal=s, filterbank=f)
            capnphit.write(io)
        end
    end
end
