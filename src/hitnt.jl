# Hit NamedTuple types

# This let block defines and exports 8 NamedTuple type aliases for Hits and
# defines NamedTuple constructors for them.  The `data_field_type` type allows
# for the data field to be a Matrix{Float32} or a String (e.g. a Base64 encoded
# Matrix{Float32}).

let data_field_type = Union{String, Matrix{Float32}}, alias_names_types = (
    ("HitNamedTuple",                (                                       ), (                                      )),
    ("HitIndexNamedTuple",           (       :fileindex,                     ), (                 Int64,               )),
    ("HitDataNamedTuple",            (:data,                                 ), (data_field_type,                      )),
    ("HitDataIndexNamedTuple",       (:data, :fileindex,                     ), (data_field_type, Int64,               )),
    ("HitGlobalNamedTuple",          (                   :hostname, :filename), (                        String, String)),
    ("HitIndexGlobalNamedTuple",     (       :fileindex, :hostname, :filename), (                 Int64, String, String)),
    ("HitDataGlobalNamedTuple",      (:data,             :hostname, :filename), (data_field_type,        String, String)),
    ("HitDataIndexGlobalNamedTuple", (:data, :fileindex, :hostname, :filename), (data_field_type, Int64, String, String)),
)

for (alias, names, types) in alias_names_types
@eval begin
export $(Symbol(alias))

"""
`$($alias)` is a `NamedTuple` type for a `Hit`.  It contains these keys:

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
| :data            | (see text) | `[D]` Data array of hit's Filterbank "swatch"                               |
| :fileindex       | Int64      | `[I]` Word index of hit within hits file                                    |
| :hostname        | String     | `[G]` Hostname on which the hits file resides                               |
| :filename        | String     | `[G]` Full path of the hits file                                            |

- `[S]` fields are from the Hit's `signal` field.
- `[F]` fields are from the Hit's `filterbank` field.
- `[D]` field  is only present in `HitData*NamedTuple` types.
- `[I]` field  is only present in `Hit*Index*NamedTuple` types.
- `[G]` fields is only present in `Hit*GlobalNamedTuple` types.

The `numChannels` and `numTimesteps` fields give the dimensions of the `data`
field of the `Hit`.  It is possible, though unusual, for the `data` field of the
`HitData*NamedTuple` to have different dimensions.  The `data` field is a
`Union{String,Matrix{Float32}}` to allow it to be passed as a `Matrix{Float32}`
or a `String` (e.g. a base64 encoded `Matrix{Float32}`).
"""
const $(Symbol(alias)) = NamedTuple{(
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
    $names...
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
    $types...
}}

# Named Tuple constructor
function Core.NamedTuple(h::Hit, $(map(nt->Meta.parse(join(nt, "::")), zip(names, types))...))::$(Symbol(alias))
    $(Symbol(alias))((
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
        # Extra fields
        $(Symbol.(names)...)
    ))
end

end # @eval
end # for
end # let