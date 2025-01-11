# Construct a NamedTuple from a Hit

"""
    NamedTuple(hit::Hit; kwargs...)

Construct a `NamedTuple` that is a flattened representation of `hit`. The keys
shown in the following table are always included.  Any given `kwargs` will
be added at the end of the `NamedTuple`.

| Key              | Value type | Description                                                                 |
|:-----------------|:-----------|:----------------------------------------------------------------------------|
| :frequency       | Float64    | `[S]` The frequency the hit starts at (MHz)                                 |
| :index           | Int32      | `[S]` The frequency bin the hit starts at (relative to the coarse channel)  |
| :driftSteps      | Int32      | `[S]` How many bins the hit drifts over                                     |
| :driftRate       | Float64    | `[S]` The drift rate (Hz/s)                                                 |
| :snr             | Float32    | `[S]` The signal-to-noise ratio for the hit                                 |
| :coarseChannel   | Int32      | `[S]` Which coarse channel this hit is in                                   |
| :beam            | Int32      | `[S]` Which beam this hit is in (-1 for incoherent beam)                    |
| :power           | Float32    | `[S]` Total power of the hit (counts)                                       |
| :incoherentPower | Float32    | `[S]` Total power of the hit in the incoherent beam (counts) or 0.0         |
| :sourceName      | String     | `[F]` Source name for the beam                                              |
| :fch1            | Float64    | `[F]` Frequency of first channel in `data` (MHz)                            |
| :foff            | Float64    | `[F]` Channel width of `data` (MHz)                                         |
| :tstart          | Float64    | `[F]` Start time of `data` (MJD)                                            |
| :tsamp           | Float64    | `[F]` Time step of `data` (seconds)                                         |
| :ra              | Float64    | `[F]` Right ascention of beam (hours)                                       |
| :dec             | Float64    | `[F]` Declination of beam (degrees)                                         |
| :telescopeId     | Int32      | `[F]` Telescope ID number                                                   |
| :numTimesteps    | Int32      | `[F]` Number of time samples in `data`                                      |
| :numChannels     | Int32      | `[F]` Number of frequency channels in `data`                                |
| :startChannel    | Int32      | `[F]` First channel of data is from this fine channel within coarse channel |

- `[S]` fields are from the Hit's `signal` field.
- `[F]` fields are from the Hit's `filterbank` field.

Example:

    nthit = NamedTuple(hit; fileindex=0; filename="vega.hits")
"""
function NamedTuple(h::Hit; kwargs...)
    return NamedTuple{(
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
        # Splat in kwarg keys
        keys(kwargs)...
    )}((
        # Signal fields
        getmissingfield(h.signal, :frequency),
        getmissingfield(h.signal, :index),
        getmissingfield(h.signal, :driftSteps),
        getmissingfield(h.signal, :driftRate),
        getmissingfield(h.signal, :snr),
        getmissingfield(h.signal, :coarseChannel),
        getmissingfield(h.signal, :beam),
        getmissingfield(h.signal, :power),
        getmissingfield(h.signal, :incoherentPower),
        # Filterbank fields
        getmissingfield(h.filterbank, :sourceName),
        getmissingfield(h.filterbank, :fch1),
        getmissingfield(h.filterbank, :foff),
        getmissingfield(h.filterbank, :tstart),
        getmissingfield(h.filterbank, :tsamp),
        getmissingfield(h.filterbank, :ra),
        getmissingfield(h.filterbank, :dec),
        getmissingfield(h.filterbank, :telescopeId),
        getmissingfield(h.filterbank, :numTimesteps),
        getmissingfield(h.filterbank, :numChannels),
        getmissingfield(h.filterbank, :startChannel),
        # Splat in kwarg values
        values(kwargs)...
    ))
end

# Deprecated old NamedTuple ctors having extra positional parameters
@deprecate(NamedTuple(hit::Hit, fileindex::Int64),
           NamedTuple(hit; fileindex))
@deprecate(NamedTuple(hit::Hit, hostname::String, filename::String),
           NamedTuple(hit; hostname, filename))
@deprecate(NamedTuple(hit::Hit, fileindex::Int64, hostname::String, filename::String),
           NamedTuple(hit; fileindex, hostname, filename))
@deprecate(NamedTuple(hit::Hit, data::Union{String, Matrix{Float32}}),
           NamedTuple(hit; data))
@deprecate(NamedTuple(hit::Hit, data::Union{String, Matrix{Float32}}, fileindex::Int64),
           NamedTuple(hit; data, fileindex))
@deprecate(NamedTuple(hit::Hit, data::Union{String, Matrix{Float32}}, hostname::String, filename::String),
           NamedTuple(hit; data, hostname, filename))
@deprecate(NamedTuple(hit::Hit, data::Union{String, Matrix{Float32}}, fileindex::Int64, hostname::String, filename::String),
           NamedTuple(hit; data, fileindex, hostname, filename))
