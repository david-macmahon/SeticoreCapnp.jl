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
  signal::Signal

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
    ntime = convert(Int32, s.numTimesteps)
    nchan = convert(Int32, s.numChannels)
    npol  = convert(Int32, s.numPolarizations)
    nant  = convert(Int32, s.numAntennas)
    datavec = convert(Vector{Float32}, s.data)
    datavecz = reinterpret(Complex{Float32}, datavec)
    data = reshape(datavecz, Int64(nant), Int64(npol), Int64(nchan), Int64(ntime))

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
    load_stamps(filename) -> DataFrame

Load the `Stamp`s from the given `filename` and return the metadata fields as a
`DataFrame` and the Stamp `data` fields as a `Vector{Array}` whose elements
correspond one-to-one with the rows of the metadata DataFrame.  The only
supported `kwargs` is `traversal_limit_in_words` which sets the maximmum size of
a stamp.  It default it 2^30 words.
"""
function load_stamps(stamps_filename; traversal_limit_in_words=2^30)
    df = open(stamps_filename) do io
        [Stamp(s) for s in SeticoreCapnp.CapnpStamp[].Stamp.read_multiple(io; traversal_limit_in_words)]
    end |> DataFrame
    # Store the Signal fields as additional columns, omitting redundant
    # `coarseChannel` and `numTimesteps` fields.
    data = df.data
    sigdf = DataFrame(df.signal)
    select!(df, Not([:data, :signal]))
    select!(sigdf, Not([:coarseChannel, :numTimesteps]))
    hcat(df, sigdf, makeunique=true), data
end
