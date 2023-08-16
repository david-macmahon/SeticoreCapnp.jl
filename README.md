# SeticoreCapnp

A Julia package for reading `*.hits` and `*.stamps` files created by
[seticore](https://github.com/lacker/seticore.git).

## Getting started

This package is not yet registered, so you'll have to add it by URL.  You can
use the REPL's built-in package manager:

```
julia> ]
(@v1.9) pkg> add https://github.com/david-macmahon/SeticoreCapnp.jl
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

The `load_hits` and `load_stamps` functions both return a Vector of
`OrderedDict{Symbol,Any}` objects containing hit or stamp metadata from the
specified file as well as a Vector of Arrays containing the *Filterbank* data or
*RAW voltage* data associated with each hit or stamp.

By default, the `find_hits` function will only return unique hits, even if the
file contain duplicate hits.  This is to work around a bug in some versions of
`seticore` that output duplicate hits.  If the file is known to be
duplicate-free or if you want the duplicates, pass `unique=false` to
`find_hits`.

The metadata will also contain a `:fileoffset` key that can be used with the
singular name functions `load_hit` or `load_stamp` to (re-)load just that
individual hit or stamp from the input file.

## Hits

The `OrderedDict` for a hit contains these keys:

| Key            |  Value type     | Note                                                                         |
|:---------------|:----------------|:-----------------------------------------------------------------------------|
| :frequency     | Float64         | The frequency the hit starts at                                              |
| :index         | Int32           | The frequency bin the hit starts at (relative to the coarse channel)         |
| :driftSteps    | Int32           | How many bins the hit drifts over                                            |
| :driftRate     | Float64         | The drift rate in Hz/s                                                       |
| :snr           | Float32         | The signal-to-noise ratio for the hit                                        |
| :coarseChannel | Int32           | Which coarse channel this hit is in                                          |
| :beam          | Int32           | Which beam this hit is in (-1 for incoherent beam)                           |
| :sourceName    | String          | Source name for the beam                                                     |
| :fch1          | Float64         | Frequency of first channel in `data`                                         |
| :foff          | Float64         | Channel width of `data`                                                      |
| :tstart        | Float64         | Start time of `data`                                                         |
| :tsamp         | Float64         | Time step of `data`                                                          |
| :ra            | Float64         | Right ascention of beam (hours)                                              |
| :dec           | Float64         | Declination of beam (degrees)                                                |
| :telescopeId   | Int32           | Telescope ID number                                                          |
| :numTimesteps  | Int32           | Number of time samples in `data`                                             |
| :numChannels   | Int32           | Number of frequency channels in `data`                                       |
| :startChannel  | Int32           | First channel of data corresponds to this fine channel within coarse channel |
| :fileoffset    | Int64           | Offset from which this hit can be loaded                                     |

The data for each hit is a `Matrix{Float32}` sized as `(numChannels,
numTimesteps)`.

## Stamps

The `OrderedDict` for stamps contains these keys:

| Key               | Value type           | Note                                           |
|:------------------|:---------------------|:-----------------------------------------------|
| :seticoreVersion  | String               | Version of seticore                            |
| :sourceName       | String               | Source name of primary pointing                |
| :ra               | Float64              | Right ascension of primary pointing (hours)    |
| :dec              | Float64              | Declination of primary pointing (degrees)      |
| :fch1             | Float64              | Frequency of first channel in `data`           |
| :foff             | Float64              | Channel width of `data`                        |
| :tstart           | Float64              | Start time of `data`                           |
| :tsamp            | Float64              | Time step of `data`                            |
| :telescopeId      | Int32                | Telescope ID number                            |
| :coarseChannel    | Int32                | Coarse channel from which `data` was extracted |
| :fftSize          | Int32                | FFT size using to create channels in `data`    |
| :startChannel     | Int32                | First fine channel in `data`                   |
| :numTimesteps     | Int32                | Number of time samples in `data`               |
| :numChannels      | Int32                | Number of frequency channels in `data`         |
| :numPolarizations | Int32                | Number of polarizations in `data`              |
| :numAntennas      | Int32                | Number of antennas in `data`                   |
| :fileoffset       | Int64                | Offset from which this stamp can be loaded     |

The data for each stamp is an `Array{ComplexF32, 4}` sized as `(numAntennas,
numPolarizations, numChannels, numTimesteps)`.

## Native Julia interface

Being able to call the Python `capnp` package to read the Hits and Stamps
files leverages existing code and streamlines development time.  While the
translation between Julia and Python is easy and almost seamless, the overall
performance is unfortunately not good, which limits the scalability of this
approach.  For example, reading 1 million hits from a single Hits file took over
45 minutes!  Here is a table showing some timing and memory stats for reading
various numbers of hits from a single Hits file ranging from 10 hits to 1
million hits:

|  # Hits |   Time (s)  | Memory allocated | GC percentage |
|--------:|------------:|-----------------:|--------------:|
|      10 |    0.021294 |        4.678 MiB |        0.00 % |
|     100 |    0.256432 |       46.906 MiB |        6.91 % |
|    1000 |    2.492556 |      469.119 MiB |       10.58 % |
|   10000 |   24.844329 |        4.591 GiB |       10.29 % |
|  100000 |  269.365632 |       45.725 GiB |       15.51 % |
| 1000000 | 2783.571640 |      378.214 GiB |       26.36 % |

To speed things up, a rudamentary generic Capnp parser was written natively in
Julia and functions to parse Hits and Stamps using their current schemas were
hand coded (as opposed to being auto-generated from the `hit.capnp` and
`stamp.capnp` files).  Here are the timing and memory stats for the native Julia
parser for the same test cases as before:

|  # Hits |   Time (s)  | Memory allocated | GC percentage |
|--------:|------------:|-----------------:|--------------:|
|      10 |    0.000674 |      153.156 KiB |        0.00 % |
|     100 |    0.002079 |        1.491 MiB |        0.00 % |
|    1000 |    0.024269 |       14.922 MiB |        0.00 % |
|   10000 |    0.284377 |      149.433 MiB |       17.32 % |
|  100000 |    2.474949 |        1.456 GiB |        4.13 % |
| 1000000 |   21.077265 |       11.897 GiB |        6.44 % |

The native Julia Hits and Stamps parser is over two orders of magnitude faster
than using the Python parser from Julia!

To use the native Julia parser, create a `CapnpReader` object by passing a Hits
or Stamps filename to the constructor:

```julia
using SeticoreCapnp

hits_reader = CapnpReader("your_datafile.hits")
```

The `CapnpReader` object acts as a Julia iterator that provides information on
each iteration that can be used to construct Hit or Stamp object, as appropraite
for the data file being parsed.  This can be done by using any Julia function
that works with iterators.  For example, the `map` function can be used to
create a Vector of Hit objects:

```julia
# hits will be a Vector of Hit objects (aka Vector{Hit})
hits = map(SeticoreCapnp.Hit, hits_reader)
```

### Omitting data

By default, the `data` field of a Hit's Filterbank object or a Stamp is
populated with the relevant data from the Hits or Stamps file.  If the data
field is not immediately relevant, it is possible to omit populating it by
passing `withdata=false` as a keyword argument to the Hit or Stamp constructor
methods that accept `CapnpReader` parameters.  When `withdata=false` is passed
the `data` field will still be an Array of the appropriate type, but it will be
zero sized in all dimensions.

### Julia iterator tricks

Because `CapnpReader` acts like a Julia iterator, if can be used with standard
Julia iterator related functions.  For example, to load only the first `N` Hits,
one can use the `first` function:

```
first_N_hits = map(Hit, first(hits_reader, N))
```

Similarly, to get only the `N`th Hit, one can use `first` in combination with
`Iterators.drop`:

```
hit_N = Hit(first(Iterators.drop(hits_reader, N-1)))
```

These same techniques are equally applicable when working with Stamps files.

### Finalizing CapnpReader objects

`CapnpReader` uses `mmap` to access the data of the hits and stamps files.  This
creates an Array whose data get automatically paged into memory (i.e. read from
disk) as they are accessed.  The process must therefore hold open the underlying
file.  When the Array eventually gets finalized, the memory is "munmap"ed, which
closes the file.  For more control over when the file gets closed, it is
possible to `finalize` the `CapnpReader` object directly which will call
`finalize` on the data Array.

NB: Using the `CapnpReader` object after calling finalize on it is an error and
the process will segfault (i.e. crash)!

### Status of the native Julia interface

Currently the native Julia interface exists as a separate "alternate" way to
parse Hits and Stamps files.  The "standard" `load_hits` and `load_stamps`
functions currently use the Python-based technique for loading Hits and Stamps.
These functions will be changed to use the native Julia interface in a future
version given the performance benefits that the native Julia interface offers.