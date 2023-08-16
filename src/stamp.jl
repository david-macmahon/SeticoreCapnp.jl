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
    Stamp(s)
Construct a `Stamp` from capnp object `s`.
"""
function Stamp(s)
    ntime = convert(Int32, s.numTimesteps)
    nchan = convert(Int32, s.numChannels)
    npol  = convert(Int32, s.numPolarizations)
    nant  = convert(Int32, s.numAntennas)
    datavec = convert(Vector{Float32}, s.data)
    datavecz = reinterpret(Complex{Float32}, datavec)
    # Added type assertions to make JET happy
    data = reshape(datavecz, Int64(nant)::Int64, Int64(npol)::Int64,
                             Int64(nchan)::Int64, Int64(ntime)::Int64)

    Stamp(
        convert(String,  s.seticoreVersion),
        convert(String,  s.sourceName),
        convert(Float64, s.ra),
        convert(Float64, s.dec),
        convert(Float64, s.fch1),
        convert(Float64, s.foff),
        convert(Float64, s.tstart),
        convert(Float64, s.tsamp),
        convert(Int32,   s.telescopeId),
        convert(Int32,   s.coarseChannel),
        convert(Int32,   s.fftSize),
        convert(Int32,   s.startChannel),
        Signal(s.signal),
        convert(Int32,   s.schan),
        convert(String,  s.obsid),
        ntime,
        nchan,
        npol,
        nant,
        data
    )
end

"""
    Stamp((words, fidx::Int64); withdata=true)
    Stamp(words, fidx::Int64; withdata=true)
    Stamp(words, widx::Int64, sidxs::Tuple{Int64,...}; withdata=true)

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
function Stamp(words::Vector{UInt64}, widx::Int64, sidxs::Tuple{Int64,Vararg{Int64}};
                    withdata=true)
    @debug "Stamp @$widx"

    ptype, offset, ndata, nptrs = parseword(words[widx])

    # A capnp Stamp is a struct with up to 11 (supported) words of data and
    # up to 5 pointers
    @assert ptype == CapnpStruct "ptype $ptype @$widx"
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
        load_data!(reinterpret(Float32, data), words, pidx+1, sidxs)
    else
        data = ComplexF32[;;;;]
    end

    seticoreVersion = nptrs > 2 ? load_string(words, pidx+2) : ""
    signal = nptrs > 3 ? Signal(words, pidx+3, sidxs) : nothing
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
    capnp_frame(Stamp, words, fidx; withdata)
end

function Stamp(t::Tuple{Vector{UInt64}, Int64}; withdata=true)
    Stamp(t...; withdata)
end


"""
    Stamp(d::AbstractDict, data::Array)

Construct a `Stamp` from `AbstractDict` object `d`, whose key type must be
`Symbol` or an `AbstractString`, and `data`.
"""
function Stamp(d::AbstractDict{T,Any}, data::Array{Float32}) where T<:Union{AbstractString,Symbol}
    Stamp(
        # Maybe these converts are not needed?
        convert(String,  d[T(:seticoreVersion)]),
        convert(String,  d[T(:sourceName)]),
        convert(Float64, d[T(:ra)]),
        convert(Float64, d[T(:dec)]),
        convert(Float64, d[T(:fch1)]),
        convert(Float64, d[T(:foff)]),
        convert(Float64, d[T(:tstart)]),
        convert(Float64, d[T(:tsamp)]),
        convert(Int32,   d[T(:telescopeId)]),
        convert(Int32,   d[T(:coarseChannel)]),
        convert(Int32,   d[T(:fftSize)]),
        convert(Int32,   d[T(:startChannel)]),
        Signal(d),
        convert(Int32,   d[T(:schan)]),
        convert(String,  d[T(:obsid)]),
        convert(Int32,   d[T(:numTimesteps)]),
        convert(Int32,   d[T(:numChannels)]),
        convert(Int32,   d[T(:numPolarizations)]),
        convert(Int32,   d[T(:numAntennas)]),
        data
    )
end

function getdata(s::Stamp)
    s.data
end

const StampDictFields = (
    :seticoreVersion,
    :sourceName,
    :ra,
    :dec,
    :fch1,
    :foff,
    :tstart,
    :tsamp,
    :telescopeId,
    :coarseChannel,
    :fftSize,
    :startChannel,
    :schan,
    :obsid,
    :numTimesteps,
    :numChannels,
    :numPolarizations,
    :numAntennas
)

function Core.NamedTuple(s::Stamp)
    NamedTuple(Iterators.flatten((
        (k=>getfield(s,        k) for k in StampDictFields),
        (k=>getfield(s.signal, k) for k in SignalDictFields)
    )))
end

# For offset_factory/index_factory output
function Core.NamedTuple(t::Tuple{Stamp,Int64}, key=:fileoffset)
    s, v = t
    NamedTuple(Iterators.flatten((
        (k=>getfield(s,        k) for k in StampDictFields),
        (k=>getfield(s.signal, k) for k in SignalDictFields),
        (key=>v,)
    )))
end

function OrderedCollections.OrderedDict{Symbol,Any}(s::Stamp)
    d = OrderedDict{Symbol,Any}(
        StampDictFields .=> getfield.(Ref(s), StampDictFields)
    )
    merge!(d, OrderedDict(s.signal))
end

function OrderedCollections.OrderedDict(s::Stamp)
    OrderedCollections.OrderedDict{Symbol,Any}(s)
end

"""
    load_stamp(filename, offset; kwargs...) -> OrderedDict, Array{ComplexF32,4}, Int64
    load_stamp(io::IO[, offset]; kwargs...) -> OrderedDict, Array{ComplexF32,4}, Int64

Load a single `Stamp` from the given `offset` (or current position) within
`filename` or `io` and return the metadata fields as an
`OrderedDict{Symbol,Any}`, the complex voltage data of the stamp as an
`Array{ComplexF32,4}`, and the offset from which the stanp was loaded.

The only supported `kwargs` is `traversal_limit_in_words` which sets the
maximmum size of a stamp.  It default it 2^30 words.
"""
function load_stamp(io::IO; traversal_limit_in_words=2^30)
    offset = lseek(io)
    stamp = Stamp(SeticoreCapnp.CapnpStamp[].Stamp.read(io; traversal_limit_in_words))
    data = getdata(stamp)

    meta = OrderedDict(stamp)
    # Merge the Signal fields as additional columns, omitting redundant
    # `coarseChannel` field (and already omitted `numTimesteps` field).
    sig = OrderedDict(stamp.signal)
    delete!(sig, :coarseChannel)
    merge!(meta, sig)

    meta, data, offset
end

function load_stamp(io::IO, offset; traversal_limit_in_words=2^30)
    seek(io, offset)
    load_stamp(io; traversal_limit_in_words)
end

function load_stamp(stamps_filename, offset; traversal_limit_in_words=2^30)
    open(stamps_filename) do io
        load_stamp(io, offset; traversal_limit_in_words)
    end
end

include("stampsfile.jl")

"""
    load_stamps(filename; kwargs...) -> Vector{OrderedDict}, Vector{Array{Float32,4}}

Load the `Stamp`s from the given `filename` and return the metadata fields as a
`Vector{OrderedDict{Symbol,Any}}` and the voltage data as a
`Vector{Array{ComplexF32,4}}` whose elements correspond one-to-one with the
entries of the metadata `Vector`.  The metadata entries includes a `:fileoffset`
entry whose value is the offset of the `Stamp` within the input file. This
offset can be used with `load_stamp` if desired.

The only supported `kwargs` is `traversal_limit_in_words` which sets the
maximmum size of a stamp.  It default it 2^30 words.
"""
function load_stamps(stamps_filename; traversal_limit_in_words=2^30)
    meta = OrderedDict{Symbol,Any}[]
    data = Array{ComplexF32,4}[]
    open(stamps_filename) do io
        for (m,d,o) in StampsFile(io, traversal_limit_in_words)
            m[:fileoffset] = o
            push!(meta, m)
            push!(data, d)
        end
    end

    meta, data
end
