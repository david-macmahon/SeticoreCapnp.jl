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

"""
    load_hits(filename; kwargs...) -> meta::DataFrame, data::Vector{Array}

Load the `Hit`s from the given `filename` and return the metadata fields as a
`DataFrame` and the "Filterbank" waterfall data as a `Vector{Array}` whose
elements correspond one-to-one with the rows of the metadata DataFrame.  The
only supported `kwargs` is `traversal_limit_in_words` which sets the maximmum
size of a hit.  It default it 2^30 words.
"""
function load_hits(hits_filename; traversal_limit_in_words=2^30)
    hits = open(hits_filename) do io
        [Hit(h) for h in SeticoreCapnp.CapnpHit[].Hit.read_multiple(io; traversal_limit_in_words)]
    end
    isempty(hits) && return (DataFrame(), Matrix{Float32}[])

    sdf = DataFrame(getproperty.(hits, :signal))
    fdf = DataFrame(getproperty.(hits, :filterbank))
    # Omit redundant numTimesteps field from Signal rather than Filterbank
    # because it was added to Signal after it was part of Filterbank so some
    # hits files will not have Signal.numTimesteps.
    # Omit redundant coarseChannel and beam fields from Filterbank
    data = fdf.data
    select!(sdf, Not(:numTimesteps))
    select!(fdf, Not([:data, :coarseChannel, :beam]))
    hcat(sdf, fdf, makeunique=true), data
end
