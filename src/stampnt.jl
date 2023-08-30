# Stamp NamedTuple types

# This let block defines and exports 8 NamedTuple type aliases for Stamp and
# defines NamedTuple constructors for them.

let data_field_type = Union{String, Array{Float32,4}}, alias_names_types = (
    ("StampNamedTuple",                (                                       ), (                                      )),
    ("StampIndexNamedTuple",           (       :fileindex,                     ), (                 Int64,               )),
    ("StampDataNamedTuple",            (:data,                                 ), (data_field_type,                      )),
    ("StampDataIndexNamedTuple",       (:data, :fileindex,                     ), (data_field_type, Int64,               )),
    ("StampGlobalNamedTuple",          (                   :hostname, :filename), (                        String, String)),
    ("StampIndexGlobalNamedTuple",     (       :fileindex, :hostname, :filename), (                 Int64, String, String)),
    ("StampDataGlobalNamedTuple",      (:data,             :hostname, :filename), (data_field_type,        String, String)),
    ("StampDataIndexGlobalNamedTuple", (:data, :fileindex, :hostname, :filename), (data_field_type, Int64, String, String)),
)

for (alias, names, types) in alias_names_types
@eval begin
export $(Symbol(alias))

"""
`$($alias)` is a `NamedTuple` type for a `Stamp`.  It contains these keys:

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
| :data             | (see text) | `[D]` Data array of stamp                                                  |
| :fileindex        | Int64      | `[I]` Word index of stamp within stamps file                               |
| :hostname         | String     | `[G]` Hostname on which the stamps file resides                            |
| :filename         | String     | `[G]` Full path of the stamps file                                         |

- `[S]` fields are from the `signal` field of the highest SNR `Hit` associated
  with this `Stamp`.
- `[D]` field  is only present in `StampData*NamedTuple` types.
- `[I]` field  is only present in `Stamp*Index*NamedTuple` types.
- `[G]` fields is only present in `Stamp*GlobalNamedTuple` types.

The `numAntennas`, `numPolarizations`, `numChannels`, and `numTimesteps` fields
give the dimensions of the `data` array of the `Stamp`.  It is possible, though
unusual, for the `data` field of the `StampData*NamedTuple` to have different
dimensions.  The `data` field is a `Union{String,Array{Float32,4}}` to allow it
to be passed as an `Array{Float32,4}` or a `String` (e.g. a base64 encoded
`Array{Float32,4}`).
"""
const $(Symbol(alias)) = NamedTuple{(
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
    $names...
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
    $types...
}}

# Named Tuple constructor
function Core.NamedTuple(s::Stamp, $(map(nt->Meta.parse(join(nt, "::")), zip(names, types))...))::$(Symbol(alias))
    $(Symbol(alias))((
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
        $(Symbol.(names)...)
    ))
end

end # @eval
end # for
end # let