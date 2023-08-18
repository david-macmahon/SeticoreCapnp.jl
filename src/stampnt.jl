# Stamp NamedTuple types

"""
`StampNamedTuple` is a `NamedTuple` type for a `Stamp`.  It contains these keys:

| Key               | Value type | Note                                                                     |
|:------------------|:-----------|:-------------------------------------------------------------------------|
| :seticoreVersion  | String     | Version of seticore                                                      |
| :sourceName       | String     | Source name of primary pointing                                          |
| :ra               | Float64    | Right ascension of primary pointing (hours)                              |
| :dec              | Float64    | Declination of primary pointing (degrees)                                |
| :fch1             | Float64    | Frequency of first channel in `data` (MHz)                               |
| :foff             | Float64    | Channel width of `data` (MHz)                                            |
| :tstart           | Float64    | Start time of `data` (MHz)                                               |
| :tsamp            | Float64    | Time step of `data` (seconds)                                            |
| :telescopeId      | Int32      | Telescope ID number                                                      |
| :coarseChannel    | Int32      | Coarse channel from which `data` was extracted                           |
| :fftSize          | Int32      | FFT size using to create channels in `data`                              |
| :startChannel     | Int32      | First fine channel in `data`                                             |
| :numTimesteps     | Int32      | Number of time samples in `data`                                         |
| :numChannels      | Int32      | Number of frequency channels in `data`                                   |
| :numPolarizations | Int32      | Number of polarizations in `data`                                        |
| :numAntennas      | Int32      | Number of antennas in `data`                                             |
| :frequency        | Float64    | [S] The frequency the hit starts at (MHz)                                |
| :index            | Int32      | [S] The frequency bin the hit starts at (relative to the coarse channel) |
| :driftSteps       | Int32      | [S] How many bins the hit drifts over                                    |
| :driftRate        | Float64    | [S] The drift rate (Hz/s)                                                |
| :snr              | Float32    | [S] The signal-to-noise ratio for the hit                                |
| :beam             | Int32      | [S] Which beam this hit is in (-1 for incoherent beam)                   |
| :power            | Float32    | [S] Total power of the hit (counts)                                      |
| :incoherentPower  | Float32    | [S] Total power of the hit in the incoherent beam (counts) or 0.0        |

- Fields with `[S]` are from the `signal` field of the highest SNR `Hit`
  associated with this `Stamp`.

The `numAntennas`, `numPolarizations`, `numChannels`, and `numTimesteps` fields
give the dimensions of the `data` array of the `Stamp`, though the `data` field
is not included in the `NamedTuple`.
"""
const StampNamedTuple = NamedTuple{(
    # Stamp fields
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
    :numTimesteps,
    :numChannels,
    :numPolarizations,
    :numAntennas,
    # Signal fields
    :frequency,
    :index,
    :driftSteps,
    :driftRate,
    :snr,
    :beam,
    :power,
    :incoherentPower
), Tuple{
    # Stamp fields
    String,  # seticoreVersion,
    String,  # sourceName,
    Float64, # ra,
    Float64, # dec,
    Float64, # fch1,
    Float64, # foff,
    Float64, # tstart,
    Float64, # tsamp,
    Int32,   # telescopeId,
    Int32,   # coarseChannel,
    Int32,   # fftSize,
    Int32,   # startChannel,
    Int32,   # numTimesteps,
    Int32,   # numChannels,
    Int32,   # numPolarizations,
    Int32,   # numAntennas,
    # Signal fields
    Float64, # frequency
    Int32,   # index
    Int32,   # driftSteps
    Float64, # driftRate
    Float32, # snr
    Int32,   # beam
    Float32, # power
    Float32  # incoherentPower
}}

function Core.NamedTuple(s::Stamp)::StampNamedTuple
    StampNamedTuple((
        # Stamp fields
        s.seticoreVersion,
        s.sourceName,
        s.ra,
        s.dec,
        s.fch1,
        s.foff,
        s.tstart,
        s.tsamp,
        s.telescopeId,
        s.coarseChannel,
        s.fftSize,
        s.startChannel,
        s.numTimesteps,
        s.numChannels,
        s.numPolarizations,
        s.numAntennas,
        # Signal fields
        s.signal.frequency,
        s.signal.index,
        s.signal.driftSteps,
        s.signal.driftRate,
        s.signal.snr,
        s.signal.beam,
        s.signal.power,
        s.signal.incoherentPower
    ))
end

"""
`StampIndexNamedTuple` is the same as `StampNamedTuple`, but with an extra
`fileindex::Int64` field at the end.
"""
const StampIndexNamedTuple = NamedTuple{(
    # Stamp fields
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
    :numTimesteps,
    :numChannels,
    :numPolarizations,
    :numAntennas,
    # Signal fields
    :frequency,
    :index,
    :driftSteps,
    :driftRate,
    :snr,
    :beam,
    :power,
    :incoherentPower,
    # Index field
    :fileindex
), Tuple{
    # Stamp fields
    String,  # seticoreVersion,
    String,  # sourceName,
    Float64, # ra,
    Float64, # dec,
    Float64, # fch1,
    Float64, # foff,
    Float64, # tstart,
    Float64, # tsamp,
    Int32,   # telescopeId,
    Int32,   # coarseChannel,
    Int32,   # fftSize,
    Int32,   # startChannel,
    Int32,   # numTimesteps,
    Int32,   # numChannels,
    Int32,   # numPolarizations,
    Int32,   # numAntennas,
    # Signal fields
    Float64, # frequency
    Int32,   # index
    Int32,   # driftSteps
    Float64, # driftRate
    Float32, # snr
    Int32,   # beam
    Float32, # power
    Float32, # incoherentPower
    # Index field
    Int64    # fileindex
}}

function Core.NamedTuple(si::Tuple{Stamp,Int64})::StampIndexNamedTuple
    s, i = si
    HitIndexNamedTuple((
        # Stamp fields
        s.seticoreVersion,
        s.sourceName,
        s.ra,
        s.dec,
        s.fch1,
        s.foff,
        s.tstart,
        s.tsamp,
        s.telescopeId,
        s.coarseChannel,
        s.fftSize,
        s.startChannel,
        s.numTimesteps,
        s.numChannels,
        s.numPolarizations,
        s.numAntennas,
        # Signal fields
        s.signal.frequency,
        s.signal.index,
        s.signal.driftSteps,
        s.signal.driftRate,
        s.signal.snr,
        s.signal.beam,
        s.signal.power,
        s.signal.incoherentPower,
        # Index field
        i
    ))
end