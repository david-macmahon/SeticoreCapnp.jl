# Juliafication of hit.capnp

"""
The `Signal` struct contains information about a linear signal we found.  Some
of this is redundant if the `Filterbank` is present, so that the `Signal` is
still useful on its own.
"""
struct Signal <: AbstractCapnpStruct
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
    Signal(words::Vector{UInt64}, widx::Int64, sidxs::Vararg{Int64,N})

Construct a `Signal` from Capnp `words` starting at `widx` using segment indices
`sidxs`.
"""
function Signal(words::Vector{UInt64}, widx::Int64, _::Vararg{Int64,N}) where N
    @debug "Signal @$widx"

    # A capnp Signal is a struct with up to 6 (supported) words of data and zero
    # pointers
    offset, ndata, nptrs = parseword_struct(words[widx])
    @assert 0 < ndata <= 6 "ndata $ndata @$widx"
    @assert nptrs == 0 "nptrs $nptrs @$widx"

    # Data index
    didx = widx + 1 + offset

    frequency       =               load_value(Float64, words, didx,   1)
    index           = (ndata > 1) ? load_value(Int32,   words, didx+1, 1) : Int32(0)
    driftSteps      = (ndata > 1) ? load_value(Int32,   words, didx+1, 2) : Int32(0)
    driftRate       = (ndata > 2) ? load_value(Float64, words, didx+2, 1) : 0.0
    snr             = (ndata > 3) ? load_value(Float32, words, didx+3, 1) : 0.0f0
    coarseChannel   = (ndata > 3) ? load_value(Int32,   words, didx+3, 2) : Int32(0)
    beam            = (ndata > 4) ? load_value(Int32,   words, didx+4, 1) : Int32(0)
    numTimesteps    = (ndata > 4) ? load_value(Int32,   words, didx+4, 2) : Int32(0)
    power           = (ndata > 5) ? load_value(Float32, words, didx+5, 1) : 0.0f0
    incoherentPower = (ndata > 5) ? load_value(Float32, words, didx+5, 2) : 0.0f0

    Signal(
        frequency,
        index,
        driftSteps,
        driftRate,
        snr,
        coarseChannel,
        beam,
        numTimesteps,
        power,
        incoherentPower
    )
end

"""
The `Filterbank` struct contains a smaller slice of the larger filterbank that
we originally found this hit in.
"""
struct Filterbank <: AbstractCapnpStruct
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
    Filterbank(words::Vector{UInt64}, widx::Int64, sidxs::Vararg{Int64,N})

Construct a `Filterbank` from Capnp `words` starting at `widx` using segment
indices `sidxs`.
"""
function Filterbank(words::Vector{UInt64}, widx::Int64, sidxs::Vararg{Int64,N};
                    withdata=true) where N
    @debug "Filterbank @$widx"

    # A capnp Filterbank is a struct with up to 9 (supported) words of data and
    # 2 pointers (sourceName and data)
    offset, ndata, nptrs = parseword_struct(words[widx])
    @assert 0 < ndata <= 9 "ndata $ndata @$widx"
    @assert nptrs == 2 "nptrs $nptrs @$widx"

    # Data index
    didx = widx + 1 + offset

    fch1          =               load_value(Float64, words, didx,   1)
    foff          = (ndata > 1) ? load_value(Float64, words, didx+1, 1) : 0.0
    tstart        = (ndata > 2) ? load_value(Float64, words, didx+2, 1) : 0.0
    tsamp         = (ndata > 3) ? load_value(Float64, words, didx+3, 1) : 0.0
    ra            = (ndata > 4) ? load_value(Float64, words, didx+4, 1) : 0.0
    dec           = (ndata > 5) ? load_value(Float64, words, didx+5, 1) : 0.0
    telescopeId   = (ndata > 6) ? load_value(Int32,   words, didx+6, 1) : Int32(0)
    numTimesteps  = (ndata > 6) ? load_value(Int32,   words, didx+6, 2) : Int32(0)
    numChannels   = (ndata > 7) ? load_value(Int32,   words, didx+7, 1) : Int32(0)
    coarseChannel = (ndata > 7) ? load_value(Int32,   words, didx+7, 2) : Int32(0)
    startChannel  = (ndata > 8) ? load_value(Int32,   words, didx+8, 1) : Int32(0)
    beam          = (ndata > 8) ? load_value(Int32,   words, didx+8, 2) : Int32(0)

    # Pointer index
    pidx = didx + ndata

    sourceName = load_string(words, pidx)
    if withdata
        data = Matrix{Float32}(undef, numChannels, numTimesteps)
        load_data!(data, words, pidx+1, sidxs...)
    else
        data = Float32[;;]
    end

    Filterbank(
        sourceName,
        fch1,
        foff,
        tstart,
        tsamp,
        ra,
        dec,
        telescopeId,
        numTimesteps,
        numChannels,
        data,
        coarseChannel,
        startChannel,
        beam
    )
end

function getdata(f::Filterbank)
    f.data
end

function getdata(::Nothing)
    Float32[;;]
end

"""
A hit without a signal indicates that we looked for a hit here and didn't find one.
A hit without a filterbank indicates that to save space we didn't store any filterbank
data in this file; it should be available elsewhere.
"""
struct Hit <: AbstractCapnpStruct
    signal::Union{Nothing,Signal}
    filterbank::Union{Nothing,Filterbank}
end

"""
    Hit((words, fidx::Int64); withdata=true)
    Hit(words, fidx::Int64; withdata=true)
    Hit(words, widx::Int64, sidxs::Vararg{Int64,N}; withdata=true)

Construct a Hit object by parsing the Capnp frame starting at `words[fidx]` and
having segment indices of `words` given by `sidxs`.  The methods with `fidx`
call `capnp_frame` which calls the Hit constructor that takes `widx` and
`sidxs`.  For the methods with `fidx`, `words` and `fidx` can be passed as a
tuple (e.g. as returned by iterating over a CapnpReader) or as individual
parameters.  The first Capnp "pointer" of the frame is at `words[sidxs[1]]`.
The first Capnp pointer for the Hit being constructed is at `words[widx]`, which
may very well be the same as `words[sidxs[1]]`.

The `withdata` keyword argument dictates whether the Hit's Filterbank component
will have a populated `data` field (`withdata=true`) or an empty `data`
field (`withdata=false`).
"""
function Hit(words::Vector{UInt64}, widx::Int64, sidxs::Vararg{Int64,N};
             withdata=true) where N
    @debug "Hit @$widx"

    # A capnp Hit is a struct with zero data values and two pointers (structs)
    offset, ndata, nptrs = parseword_struct(words[widx])
    @assert ndata == 0 "ndata $ndata @$widx"
    @assert nptrs == 2 "nptrs $nptrs @$widx"

    # Pointer index
    pidx = widx + 1 + offset + ndata

    signal     = Signal(    words, pidx,   sidxs...)
    filterbank = Filterbank(words, pidx+1, sidxs...; withdata)

    Hit(signal, filterbank)
end

function Hit(words::Vector{UInt64}, fidx::Int64; withdata=true)
    # The expected nuumber of segments is 2 so in that case we provide a
    # non-dynamically dispatched branch.
    numsegs = load_value(UInt32, words, fidx, 1) + 1
    if numsegs == 2
        hdr_size = cld(numsegs+1, 2)
        s1idx = fidx + hdr_size
        s2idx = s1idx + load_value(UInt32, words, fidx, 2)
        nfidx = s2idx + load_value(UInt32, words, fidx, 3)
        Hit(words, s1idx, s1idx, s2idx, nfidx; withdata)
    else
        capnp_frame(Hit, words, fidx; withdata)
    end
end

function Hit(t::Tuple{Vector{UInt64}, Int64}; withdata=true)
    Hit(t...; withdata)
end

function Hit(reader::CapnpReader, fidx::Int64; withdata=true)
    Hit(reader.words, fidx; withdata)
end

function getdata(h::Hit)
    getdata(h.filterbank)
end

include("hitnt.jl")

function save_hit(io, hit::Hit)
    data = hit.filterbank.data
    @assert length(data) > 0 "cannot save Hit with no data"

    capnp = SeticoreCapnp.CapnpHit[]
    s = capnp.Signal(; (k=>getfield(hit.signal, k) for k in fieldnames(Signal))...)
    f = capnp.Filterbank(; (k=>getfield(hit.filterbank, k) for k in fieldnames(Filterbank) if k != :data)...)
    dlist = f.init(:data, length(data))
    for i in eachindex(data)
        dlist[i] = data[i]
    end
    capnphit = capnp.Hit(; signal=s, filterbank=f)
    capnphit.write(io)
end

function save_hits(hits_filename, hits::Vector{Hit})
    open(hits_filename, "w+") do io
        for h in hits
            save_hit(io, h)
        end
    end
end
