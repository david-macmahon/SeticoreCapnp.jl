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
  The first post-FFT channel that we extracted.  So column "zero" in `data`
  corresponds to this column in the original post-FFT data.  This will not
  exactly match `startChannel`` in a hit, because we combine adjacent hits and
  may use different window sizes. But if you consider the intervals
  `[startChannel, startChannel + numChannels)`, the interval for the stamp
  should overlap with the interval for any relevant hits.

  !!! note
      Currently zero based!
  """
  startChannel::Int32

  # Dimensions of the data
  numTimesteps::Int32
  numChannels::Int32
  numPolarities::Int32
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
    ntime = pyconvert(Int32, s.numTimesteps)
    nchan = pyconvert(Int32, s.numChannels)
    npol  = pyconvert(Int32, s.numPolarities)
    nant  = pyconvert(Int32, s.numAntennas)
    datavec = pyconvert(Vector{Float32}, pylist(s.data))
    datavecz = reinterpret(Complex{Float32}, datavec)
    data = reshape(datavecz, Int64(nant), Int64(npol), Int64(nchan), Int64(ntime))

    Stamp(
        pyconvert(String,  s.seticoreVersion),
        pyconvert(String,  s.sourceName),
        pyconvert(Float64, s.ra),
        pyconvert(Float64, s.dec),
        pyconvert(Float64, s.fch1),
        pyconvert(Float64, s.foff),
        pyconvert(Float64, s.tstart),
        pyconvert(Float64, s.tsamp),
        pyconvert(Int32,   s.telescopeId),
        pyconvert(Int32,   s.coarseChannel),
        pyconvert(Int32,   s.fftSize),
        pyconvert(Int32,   s.startChannel),
        ntime,
        nchan,
        npol,
        nant,
        data
    )
end

"""
    load_stamps(filename) -> DataFrame
Load the `Stamp`s from the given `filename` and return as a `DataFrame`.
"""
function load_stamps(stamps_filename)
    open(stamps_filename) do io
        [Stamp(s) for s in SeticoreCapnp.CapnpStamp[].Stamp.read_multiple(io)]
    end |> DataFrame
end