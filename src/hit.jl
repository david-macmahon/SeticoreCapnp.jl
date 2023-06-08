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
    How many bins the hit drifts over
    """
    driftSteps::Int32
  
    """
    The drift rate in Hz/s
    """
    driftRate::Float64
  
    """
    The signal-to-noise ratio for the hit
    """
    snr::Float32
  
    """
    Which coarse channel this hit is in
    """
    coarseChannel::Int32
  
    """
    Which beam this hit is in. -1 for incoherent beam
    """
    beam::Int32
end

"""
    Signal(s)
Construct a `Signal` from capnp object `s`.
"""
function Signal(s)
    Signal(
        pyconvert(Float64, s.frequency),
        pyconvert(Int32,   s.index),
        pyconvert(Int32,   s.driftSteps),
        pyconvert(Float64, s.driftRate),
        pyconvert(Float32, s.snr),
        pyconvert(Int32,   s.coarseChannel),
        pyconvert(Int32,   s.beam)
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

    # Which beam this data is from. -1 for incoherent beam
    beam::Int32
end

"""
    Filterbank(f)
Construct a `Filterbank` from capnp object `f`.
"""
function Filterbank(f)
    ntime = pyconvert(Int32, f.numTimesteps)
    nchan = pyconvert(Int32, f.numChannels)
    datavec = pyconvert(Vector{Float32}, pylist(f.data))
    data = reshape(datavec, Int64(nchan), Int64(ntime))

    Filterbank(
        pyconvert(String,          f.sourceName),
        pyconvert(Float64,         f.fch1),
        pyconvert(Float64,         f.foff),
        pyconvert(Float64,         f.tstart),
        pyconvert(Float64,         f.tsamp),
        pyconvert(Float64,         f.ra),
        pyconvert(Float64,         f.dec),
        pyconvert(Int32,           f.telescopeId),
        ntime,
        nchan,
        data,
        pyconvert(Int32,           f.coarseChannel),
        pyconvert(Int32,           f.startChannel),
        pyconvert(Int32,           f.beam)
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
    load_hits(filename) -> DataFrame
Load the `Hit`s from the given `filename` and return as a `DataFrame`.
"""
function load_hits(hits_filename)
    hits = open(hits_filename) do io
        [Hit(h) for h in SeticoreCapnp.CapnpHit[].Hit.read_multiple(io)]
    end
    sdf = DataFrame(getproperty.(hits, :signal))
    fdf = DataFrame(getproperty.(hits, :filterbank))
    # Omit redundant coarseChannel and beam fields from Filterbank
    hcat(sdf, fdf[!, Not([:coarseChannel, :beam])], makeunique=true)
end