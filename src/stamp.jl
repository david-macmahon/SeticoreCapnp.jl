# Juliafication of stamp.capnp

"""
A "postage stamp" of data extracted from a larger set of raw data.
This data has been upchannelized with an FFT but is still multi-antenna
complex voltages.
"""
struct Stamp
  """
  The seticore version that generated this data.
  """
  seticoreVersion::String

  """
  Source of the boresight target.
  """
  sourceName::String
  """
  RA of the boresight target (hours).
  """
  ra::Float64
  """
  Declination of the boresight target (degrees).
  """
  dec::Float64

  # Other standard metadata found in FBH5 files.
  # This metadata applies specifically to the postage stamp itself, not the larger
  # file we extracted it from.
  fch1::Float64
  foff::Float64
  tstart::Float64
  tsamp::Float64
  telescopeId::Int32

  # Metadata describing how exactly we extracted this stamp.

  """
  The coarse channel in the original file that we extracted data from.
  Matches coarseChannel in the hit.

  !!! note
      Currently zero based!
  """
  coarseChannel::Int32

  """
  The size of FFT we used to create fine channels.
  """
  fftSize::Int32

  """
  The first post-FFT channel that we extracted.  So the first column in `data`
  corresponds to this column in the original post-FFT data.  This will not
  exactly match startChannel in a hit, because we combine adjacent hits and may
  use different window sizes. But if you consider the intervals [startChannel,
  startChannel + numChannels), the interval for the stamp should overlap with
  the interval for any relevant hits.

  !!! note
      Currently zero based!
  """
  startChannel::Int32

  """
  Metadata for the best hit we found for this stamp.
  Not populated for stamps extracted with the `seticore` CLI tool.
  """
  signal::Union{Signal,Nothing}

  """
  Where the raw file starts in the complete input band (e.g. in the beamforming
  recipe).  Metadata copied from the input RAW file.  Needed to match up this
  stamp to the beamforming recipe file.
  """
  schan::Int32

  """
  `OBSID` (OBServation ID) field from the input RAW file.  Metadata copied from
  the input raw file.  Needed to match up this stamp to the beamforming recipe
  file.
  """
  obsid::String

  # Dimensions of the data
  numTimesteps::Int32
  numChannels::Int32
  numPolarizations::Int32
  numAntennas::Int32

  """
  An array of complex voltages.
  Indexed as `[antenna, polarization, channel, time]`
  """
  data::Array{Complex{Float32}, 4}
end

"""
    Stamp((words, fidx::Int64); withdata=true)
    Stamp(words, fidx::Int64; withdata=true)
    Stamp(words, widx::Int64, sidxs::Vararg{Int64,N}; withdata=true)

Construct a Stamp object by parsing the Capnp frame starting at `words[fidx]`
and having segment indices of `words` given by `sidxs`.  The methods with `fidx`
call `capnp_frame` which calls the Stamp constructor that takes `widx` and
`sidxs`.  For the methods with `fidx`, `words` and `fidx` can be passed as a
tuple (e.g. as returned by iterating over a CapnpReader) or as individual
parameters.  The first Capnp "pointer" of the frame is at `words[sidxs[1]]`.
The first Capnp pointer for the Stamp being constructed is at `words[widx]`,
which may very well be the same as `words[sidxs[1]]`.

The `withdata` keyword argument dictates whether the Stamp's Filterbank
component will have a populated `data` field (`withdata=true`) or an empty
`data` field (`withdata=false`).
"""
function Stamp(words::Vector{UInt64}, widx::Int64, sidxs::Vararg{Int64,N};
                    withdata=true) where N
    @debug "Stamp @$widx"

    # A capnp Stamp is a struct with up to 11 (supported) words of data and
    # up to 5 pointers
    offset, ndata, nptrs = parseword_struct(words[widx])
    @assert 0 < ndata <= 11 "ndata $ndata @$widx"
    @assert 0 < nptrs <=  5 "nptrs $nptrs @$widx"

    # Data index
    didx = widx + 1 + offset

    ra               =                load_value(Float64, words, didx,    1)
    dec              = (ndata >  1) ? load_value(Float64, words, didx+ 1, 1) : 0.0
    fch1             = (ndata >  2) ? load_value(Float64, words, didx+ 2, 1) : 0.0
    foff             = (ndata >  3) ? load_value(Float64, words, didx+ 3, 1) : 0.0
    tstart           = (ndata >  4) ? load_value(Float64, words, didx+ 4, 1) : 0.0
    tsamp            = (ndata >  5) ? load_value(Float64, words, didx+ 5, 1) : 0.0
    telescopeId      = (ndata >  6) ? load_value(Int32,   words, didx+ 6, 1) : Int32(0)
    numTimesteps     = (ndata >  6) ? load_value(Int32,   words, didx+ 6, 2) : Int32(0)
    numChannels      = (ndata >  7) ? load_value(Int32,   words, didx+ 7, 1) : Int32(0)
    numPolarizations = (ndata >  7) ? load_value(Int32,   words, didx+ 7, 2) : Int32(0)
    numAntennas      = (ndata >  8) ? load_value(Int32,   words, didx+ 8, 1) : Int32(0)
    coarseChannel    = (ndata >  8) ? load_value(Int32,   words, didx+ 8, 2) : Int32(0)
    fftSize          = (ndata >  9) ? load_value(Int32,   words, didx+ 9, 1) : Int32(0)
    startChannel     = (ndata >  9) ? load_value(Int32,   words, didx+ 9, 2) : Int32(0)
    schan            = (ndata > 10) ? load_value(Int32,   words, didx+10, 1) : Int32(0)

    # Pointer index
    pidx = didx + ndata

    sourceName = load_string(words, pidx)
    if withdata && nptrs > 1
        data = Array{ComplexF32,4}(undef, numAntennas, numPolarizations,
                                          numChannels, numTimesteps)
        load_data!(reinterpret(Float32, data), words, pidx+1, sidxs...)
    else
        data = ComplexF32[;;;;]
    end

    seticoreVersion = nptrs > 2 ? load_string(words, pidx+2) : ""
    signal = nptrs > 3 ? Signal(words, pidx+3, sidxs...) : nothing
    obsid = nptrs > 4 ? load_string(words, pidx+4) : ""

    Stamp(
        seticoreVersion,
        sourceName,
        ra,
        dec,
        fch1,
        foff,
        tstart,
        tsamp,
        telescopeId,
        coarseChannel,
        fftSize,
        startChannel,
        signal,
        schan,
        obsid,
        numTimesteps,
        numChannels,
        numPolarizations,
        numAntennas,
        data
    )
end

function Stamp(words::Vector{UInt64}, fidx::Int64; withdata=true)
    # The expected nuumber of segments is 2 so in that case we provide a
    # non-dynamically dispatched branch.
    numsegs = load_value(UInt32, words, fidx, 1) + 1
    if numsegs == 2
        hdr_size = cld(numsegs+1, 2)
        s1idx = fidx + hdr_size
        s2idx = s1idx + load_value(UInt32, words, fidx, 2)
        nfidx = s2idx + load_value(UInt32, words, fidx, 3)
        Stamp(words, s1idx, s1idx, s2idx, nfidx; withdata)
    else
        capnp_frame(Stamp, words, fidx; withdata)
    end
end

function Stamp(t::Tuple{Vector{UInt64}, Int64}; withdata=true)
    Stamp(t...; withdata)
end

function Stamp(reader::CapnpReader, fidx::Int64; withdata=true)
    Stamp(reader.words, fidx; withdata)
end

function getdata(s::Stamp)
    s.data
end

include("stampnt.jl")
