# SeticoreCapnp

A Julia package for reading `*.hits` and `*.stamps` files created by
[seticore](https://github.com/lacker/seticore.git).

## Getting started

This package is not yet registered, so you'll have to add it by URL.  You can
use the REPL's built-in package manager:

```
julia> ]
(@v1.8) pkg> add https://github.com/david-macmahon/SeticoreCapnp.jl
```

or call `Pkg` directly:

```julia
import Pkg
Pkg.add(url="https://github.com/david-macmahon/SeticoreCapnp.jl")
```

Once it is installed, you can use it like this:

```julia
using SeticoreCapnp

hits = SeticoreCapnp.load_hits("mydatafile.hits")
stamps = SeticoreCapnp.load_stamps("mydatafile.hits")
```

The `load_hits` and `load_stamps` functions return a
[`DataFrame`](https://dataframes.juliadata.org/stable/) object containing the
data from the specified file.

## Hits

The `DataFrame` for hits contains these columns:

| Name          |  Type           | Note                                                                         |
|:--------------|:----------------|:-----------------------------------------------------------------------------|
| frequency     | Float64         | The frequency the hit starts at                                              |
| index         | Int32           | The frequency bin the hit starts at (relative to the coarse channel)         |
| driftSteps    | Int32           | How many bins the hit drifts over                                            |
| driftRate     | Float64         | The drift rate in Hz/s                                                       |
| snr           | Float32         | The signal-to-noise ratio for the hit                                        |
| coarseChannel | Int32           | Which coarse channel this hit is in                                          |
| beam          | Int32           | Which beam this hit is in (-1 for incoherent beam)                           |
| sourceName    | String          | Source name for the beam                                                     |
| fch1          | Float64         | Frequency of first channel in `data`                                         |
| foff          | Float64         | Channel width of `data`                                                      |
| tstart        | Float64         | Start time of `data`                                                         |
| tsamp         | Float64         | Time step of `data`                                                          |
| ra            | Float64         | Right ascention of beam (hours)                                              |
| dec           | Float64         | Declination of beam (degrees)                                                |
| telescopeId   | Int32           | Telescope ID number                                                          |
| numTimesteps  | Int32           | Number of time samples in `data`                                             |
| numChannels   | Int32           | Number of frequency channels in `data`                                       |
| data          | Matrix{Float32} | Spectrogram data for hit, indexed as `[channel, timestep]`                   |
| startChannel  | Int32           | First channel of data corresponds to this fine channel within coarse channel |

## Stamps

The `DataFrame` for stamps contains these columns:

| Name            | Type                 | Note                                                                        |
|:----------------|:---------------------|:----------------------------------------------------------------------------|
| seticoreVersion | String               | Version of seticore                                                         |
| sourceName      | String               | Source name of primary pointing                                             |
| ra              | Float64              | Right ascension of primary pointing (hours)                                 |
| dec             | Float64              | Declination of primary pointing (degrees)                                   |
| fch1            | Float64              | Frequency of first channel in `data`                                        |
| foff            | Float64              | Channel width of `data`                                                     |
| tstart          | Float64              | Start time of `data`                                                        |
| tsamp           | Float64              | Time step of `data`                                                         |
| telescopeId     | Int32                | Telescope ID number                                                         |
| coarseChannel   | Int32                | Coarse channel from which `data` was extracted                              |
| fftSize         | Int32                | FFT size using to create channels in `data`                                 |
| startChannel    | Int32                | First fine channel in `data`                                                |
| numTimesteps    | Int32                | Number of time samples in `data`                                            |
| numChannels     | Int32                | Number of frequency channels in `data`                                      |
| numPolarities   | Int32                | Number of polarizations in `data`                                           |
| numAntennas     | Int32                | Number of antennas in `data`                                                |
| data            | Array{ComplexF32, 4} | Voltage data for stamp, indexed as `[antenna, polarization, channel, time]` |
