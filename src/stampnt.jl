# Construct a NamedTuple from a Stamp

"""
    NamedTuple(stamp::Stamp; kwargs...)

Construct a `NamedTuple` that is a flattened representation of `stamp`. The keys
shown in the following table are always included.  Any given `kwargs` will
be added at the end of the `NamedTuple`.

| Key               | Value type | Note                                                                       |
|:------------------|:-----------|:---------------------------------------------------------------------------|
| :seticoreVersion  | String     | Version of seticore                                                        |
| :sourceName       | String     | Source name of primary pointing                                            |
| :ra               | Float64    | Right ascension of primary pointing (hours)                                |
| :dec              | Float64    | Declination of primary pointing (degrees)                                  |
| :fch1             | Float64    | Frequency of first channel in `data` (MHz)                                 |
| :foff             | Float64    | Channel width of `data` (MHz)                                              |
| :tstart           | Float64    | Start time of `data` (MHz)                                                 |
| :tsamp            | Float64    | Time step of `data` (seconds)                                              |
| :telescopeId      | Int32      | Telescope ID number                                                        |
| :coarseChannel    | Int32      | Coarse channel from which `data` was extracted                             |
| :fftSize          | Int32      | FFT size using to create channels in `data`                                |
| :startChannel     | Int32      | First fine channel in `data`                                               |
| :numTimesteps     | Int32      | Number of time samples in `data`                                           |
| :numChannels      | Int32      | Number of frequency channels in `data`                                     |
| :numPolarizations | Int32      | Number of polarizations in `data`                                          |
| :numAntennas      | Int32      | Number of antennas in `data`                                               |
| :frequency        | Float64    | `[S]` The frequency the hit starts at (MHz)                                |
| :index            | Int32      | `[S]` The frequency bin the hit starts at (relative to the coarse channel) |
| :driftSteps       | Int32      | `[S]` How many bins the hit drifts over                                    |
| :driftRate        | Float64    | `[S]` The drift rate (Hz/s)                                                |
| :snr              | Float32    | `[S]` The signal-to-noise ratio for the hit                                |
| :beam             | Int32      | `[S]` Which beam this hit is in (-1 for incoherent beam)                   |
| :power            | Float32    | `[S]` Total power of the hit (counts)                                      |
| :incoherentPower  | Float32    | `[S]` Total power of the hit in the incoherent beam (counts) or 0.0        |

- `[S]` fields are from the `signal` field of the highest SNR `Hit` associated
  with this `Stamp`.

Example:

    nthit = NamedTuple(hit; fileindex=0; filename="vega.hits")
"""
function NamedTuple(s::Stamp; kwargs...)
    return NamedTuple{(
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
        # Splat in kwarg keys
        keys(kwargs)...
    )}((
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
        getmissingfield(s.signal, :frequency),
        getmissingfield(s.signal, :index),
        getmissingfield(s.signal, :driftSteps),
        getmissingfield(s.signal, :driftRate),
        getmissingfield(s.signal, :snr),
        getmissingfield(s.signal, :beam),
        getmissingfield(s.signal, :power),
        getmissingfield(s.signal, :incoherentPower),
        # Splat in kwarg values
        values(kwargs)...
    ))
end

# Deprecated old NamedTuple ctors having extra positional parameters
@deprecate(NamedTuple(stamp::Stamp, fileindex::Int64),
           NamedTuple(stamp; fileindex))
@deprecate(NamedTuple(stamp::Stamp, hostname::String, filename::String),
           NamedTuple(stamp; hostname, filename))
@deprecate(NamedTuple(stamp::Stamp, fileindex::Int64, hostname::String, filename::String),
           NamedTuple(stamp; fileindex, hostname, filename))
@deprecate(NamedTuple(stamp::Stamp, data::Union{String, Matrix{Float32}}),
           NamedTuple(stamp; data))
@deprecate(NamedTuple(stamp::Stamp, data::Union{String, Matrix{Float32}}, fileindex::Int64),
           NamedTuple(stamp; data, fileindex))
@deprecate(NamedTuple(stamp::Stamp, data::Union{String, Matrix{Float32}}, hostname::String, filename::String),
           NamedTuple(stamp; data, hostname, filename))
@deprecate(NamedTuple(stamp::Stamp, data::Union{String, Matrix{Float32}}, fileindex::Int64, hostname::String, filename::String),
           NamedTuple(stamp; data, fileindex, hostname, filename))
