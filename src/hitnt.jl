# Hit NamedTuple types

"""
`HitNamedTuple` is a `NamedTuple` type for a `Hit`.  It contains these keys:

| Key              | Value type | Description                                                               |
|:-----------------|:-----------|:--------------------------------------------------------------------------|
| :frequency       | Float64    | [S] The frequency the hit starts at (MHz)                                 |
| :index           | Int32      | [S] The frequency bin the hit starts at (relative to the coarse channel)  |
| :driftSteps      | Int32      | [S] How many bins the hit drifts over                                     |
| :driftRate       | Float64    | [S] The drift rate (Hz/s)                                                 |
| :snr             | Float32    | [S] The signal-to-noise ratio for the hit                                 |
| :coarseChannel   | Int32      | [S] Which coarse channel this hit is in                                   |
| :beam            | Int32      | [S] Which beam this hit is in (-1 for incoherent beam)                    |
| :power           | Float32    | [S] Total power of the hit (counts)                                       |
| :incoherentPower | Float32    | [S] Total power of the hit in the incoherent beam (counts) or 0.0         |
| :sourceName      | String     | [F] Source name for the beam                                              |
| :fch1            | Float64    | [F] Frequency of first channel in `data` (MHz)                            |
| :foff            | Float64    | [F] Channel width of `data` (MHz)                                         |
| :tstart          | Float64    | [F] Start time of `data` (MJD)                                            |
| :tsamp           | Float64    | [F] Time step of `data` (seconds)                                         |
| :ra              | Float64    | [F] Right ascention of beam (hours)                                       |
| :dec             | Float64    | [F] Declination of beam (degrees)                                         |
| :telescopeId     | Int32      | [F] Telescope ID number                                                   |
| :numTimesteps    | Int32      | [F] Number of time samples in `data`                                      |
| :numChannels     | Int32      | [F] Number of frequency channels in `data`                                |
| :startChannel    | Int32      | [F] First channel of data is from this fine channel within coarse channel |

- Fields with `[S]` are from the Hit's `signal` field.
- Fields with `[F]` are from the Hit's `filterbank` field.

The `numChannels` and `numTimesteps` fields give the dimensions of the `data`
field of the `Hit`, though the `data` field is not included in the
`HitNamedTuple`.
"""
const HitNamedTuple = NamedTuple{(
    # Signal fields
    :frequency,
    :index,
    :driftSteps,
    :driftRate,
    :snr,
    :coarseChannel,
    :beam,
    :power,
    :incoherentPower,
    # Filterbank fields
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
    :startChannel
), Tuple{
    # Signal fields
    Float64, # frequency
    Int32,   # index
    Int32,   # driftSteps
    Float64, # driftRate
    Float32, # snr
    Int32,   # coarseChannel
    Int32,   # beam
    Float32, # power
    Float32, # incoherentPower
    # Filterbank fields
    String,  # sourceName
    Float64, # fch1
    Float64, # foff
    Float64, # tstart
    Float64, # tsamp
    Float64, # ra
    Float64, # dec
    Int32,   # telescopeId
    Int32,   # numTimesteps
    Int32,   # numChannels
    Int32    # startChannel
}}

function Core.NamedTuple(h::Hit)::HitNamedTuple
    HitNamedTuple((
        # Signal fields
        h.signal.frequency,
        h.signal.index,
        h.signal.driftSteps,
        h.signal.driftRate,
        h.signal.snr,
        h.signal.coarseChannel,
        h.signal.beam,
        h.signal.power,
        h.signal.incoherentPower,
        # Filterbank fields
        h.filterbank.sourceName,
        h.filterbank.fch1,
        h.filterbank.foff,
        h.filterbank.tstart,
        h.filterbank.tsamp,
        h.filterbank.ra,
        h.filterbank.dec,
        h.filterbank.telescopeId,
        h.filterbank.numTimesteps,
        h.filterbank.numChannels,
        h.filterbank.startChannel
    ))
end

"""
`HitIndexNamedTuple` is the same as `HitNamedTuple`, but with an extra
`fileindex::Int64` field at the end.
"""
const HitIndexNamedTuple = NamedTuple{(
    # Signal fields
    :frequency,
    :index,
    :driftSteps,
    :driftRate,
    :snr,
    :coarseChannel,
    :beam,
    :power,
    :incoherentPower,
    # Filterbank fields
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
    # Index field
    :fileindex
), Tuple{
    # Signal fields
    Float64, # frequency
    Int32,   # index
    Int32,   # driftSteps
    Float64, # driftRate
    Float32, # snr
    Int32,   # coarseChannel
    Int32,   # beam
    Float32, # power
    Float32, # incoherentPower
    # Filterbank fields
    String,  # sourceName
    Float64, # fch1
    Float64, # foff
    Float64, # tstart
    Float64, # tsamp
    Float64, # ra
    Float64, # dec
    Int32,   # telescopeId
    Int32,   # numTimesteps
    Int32,   # numChannels
    Int32,   # startChannel
    # Index field
    Int64    # fileindex
}}

function Core.NamedTuple(hi::Tuple{Hit,Int64})::HitIndexNamedTuple
    h, i = hi
    HitIndexNamedTuple((
        # Signal fields
        h.signal.frequency,
        h.signal.index,
        h.signal.driftSteps,
        h.signal.driftRate,
        h.signal.snr,
        h.signal.coarseChannel,
        h.signal.beam,
        h.signal.power,
        h.signal.incoherentPower,
        # Filterbank fields
        h.filterbank.sourceName,
        h.filterbank.fch1,
        h.filterbank.foff,
        h.filterbank.tstart,
        h.filterbank.tsamp,
        h.filterbank.ra,
        h.filterbank.dec,
        h.filterbank.telescopeId,
        h.filterbank.numTimesteps,
        h.filterbank.numChannels,
        h.filterbank.startChannel,
        # Index field
        i
    ))
end