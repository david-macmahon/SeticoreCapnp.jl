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

## Basic usage

`SeticoreCapnp` uses a `CapnpReader` object to read Hits or Stamps files created
by `seticore`.  Hits and stamps are represented as instances of the `Hit` and
`Stamp` types provided `SeticoreCapnp`.  The easiest way to read a Hits or
Stamps file is to pass the relevant type and filename to the `CapnpReader`
constructor.  For example, to create a `CapnpReader` that can be used to read
Hits from a file named `mydatafile.hits`:

```julia
using SeticoreCapnp

reader = CapnpReader(Hit, "mydatafile.hits")
```

With our `CapnpReader` we can now create Hits.  We could call the `Hit`
constructor ourselves, but it is generally easier and more efficient to iterate
through our `CapnpReader`.  Calling the `Hit` (or `Stamp`) constructor directly
is most useful when you want a specific one and you know its "frame index".
Here is a simple `for` loop that will read all the Hits of the file associated
with `reader`:

```julia
# Loop through all Hits in the file
for hit in reader
    # Do something with `hit`, which is an instance of `Hit`
end
```

### Julia iterator tricks

Because `CapnpReader` acts like a Julia iterator, if can be used with standard
Julia iterator related functions.  For example, to create a `Vector` (i.e. list)
of (up to) the first `N` Hits, one can use the `collect` the `first` functions:

```
hits = collect(first(reader, N))
```

Similarly, to get only the `N`th Hit, one can use `first` in combination with
`Iterators.drop`:

```
hit_N = Hit(first(Iterators.drop(hits_reader, N-1)))
```

These same techniques are equally applicable when working with Stamps files.

The `Hit` structs obtained from a `CapnpReader` contain fields that are
themselves structs.  The `hit.filterbank.data` field is a `Matrix{Float32}` that
contains a small spectrogram of the hit.  There are many more fields that make
up a `Hit`.

### Flattening Hits and Stamps

Sometimes it is convenient to represent a collection of Hits or Stamps as a
table or `DataFrame`.  To facilitate this, a `Hit` or `Stamp` instance can be
flattened to a `NamedTuple` by passing it to the `NamedTuple` constructor.  When
flattening a `Hit` or `Stamp` to a `NamedTuple`, only one copy of redundant
fields is retained.  In addition to the fields from the `Hit` or `Stamp`, you
can add additional fields to the `NamedTuple` by passing them as keyword
arguments to the `NamedTuple` constructor.

In earlier versions of this package the `NamedTuple` constructor was overloaded
with additional methods based on positional arguments, but these additional
`NamedTuple` constructor methods have been deprecated and replaced with the
keyword arguments approach.  This approach provides much more flexibility.

```julia
# Get a Vector of NamedTuples for (up to) the first 5 Hits.
# Note the `.` that turns this into a *broadcast*.
hit_nts = NamedTuple.(first(hit_reader, 5))
```

In the above example, `hit_nts` will be a `Vector{NamedTuple}`, which means
that it can be passed to the `DataFrame` constructor from the `DataFrames.jl`
package (or used with any other Julia package that supports the `Tables.jl`
interface).

#### Hits

A `NamedTuple` constructed from a `Hit` contains these keys:

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
| :ra              | Float64    | `[F]` Right ascension of beam (hours)                                       |
| :dec             | Float64    | `[F]` Declination of beam (degrees)                                         |
| :telescopeId     | Int32      | `[F]` Telescope ID number                                                   |
| :numTimesteps    | Int32      | `[F]` Number of time samples in `data`                                      |
| :numChannels     | Int32      | `[F]` Number of frequency channels in `data`                                |
| :startChannel    | Int32      | `[F]` First channel of data is from this fine channel within coarse channel |

#### Stamps

A `NamedTuple` constructed from a `Stamp` contains these keys:

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

### Extracting the `data`

Sometimes you just want to get at the data, specifically the `filterbank.data`
field of Hits or the `data` field of Stamps.  Here are a few of the many ways
that this can be done:

```julia
# Using the `map` function (use `Iterators.map` for a lazy version)
datas = map(h->h.filterbank.data, reader)

# Using a list comprehension
datas = [h.filterbank.data for h in reader]

# Using `push!` and a `for` loop
datas = Matrix{Float32}[]
for h in reader
    push!(datas, h.filterbank.data)
end
```

The variable `datas` is double pluralized to remind us that in each example it
is a list of data arrays.  For Hits, each data array is a `Matrix{Float32}`, so
`datas` will be a `Vector{Matrix{Float32}}`.  For Stamps, each data array is an
`Array{Complex{Float32},4}`, so `datas` will be a
`Vector{Array{Complex{Float32,4}}}`.

The `data` for each `Hit` is a `Matrix{Float32}` sized as `(numChannels,
numTimesteps)`.

The `data` for each `Stamp` is an `Array{ComplexF32, 4}` sized as `(numAntennas,
numPolarizations, numChannels, numTimesteps)`.

### Finalizing CapnpReader objects

`CapnpReader` uses `mmap` to access the data of the hits and stamps files.  This
creates an Array whose data get automatically paged into memory (i.e. read from
disk) as they are accessed.  The process must therefore hold open the underlying
file.  When the Array eventually gets finalized, the memory is "munmap"ed, which
closes the file.  For more control over when the file gets closed, it is
possible to `finalize` the `CapnpReader` object directly, which will call
`finalize` on the data Array, which will close the file.

NB: Using the `CapnpReader` object after calling finalize on it is an error and
the process will segfault (i.e. crash)!

## Advanced usage

The `CapnpReader` has another constructor that allows for very flexible
iteration through a Capnp file:

```julia
CapnpReader(f::Function ::Type{T}, fname::AbstractString)
```

This is the most generic `CapnpReader` constructor.  Iterating over
the returned object will call `f(T, t::Tuple{Vector{UInt64}, Int64})`
for each object in the Capnp file and return the result.  In this context, `f`
is a factory function that will load an object of type `T` from the file
(actually the `Vector` and `Int64` of the tuple) and then return the object or
some variation of it (e.g. the object and the file index from which it was
read).  Factory methods can use any constructor method of type `T`, such as to
pass keyword arguments.  A number of useful factory methods are defined in the
`SeticoreCapnp` module.

### Omitting data

By default, the `data` field of a Hit's Filterbank object or a Stamp is
populated with the relevant data from the Hits or Stamps file.  If the data
field is not immediately relevant, it is possible to omit populating it by
passing `withdata=false` as a keyword argument to the Hit or Stamp constructor.
When `withdata=false` is passed the `data` field will still be an Array of the
appropriate type, but it will be zero sized in all dimensions.  Not reading the
data for the `data` array speeds up the loading of the Hits or Stamps, which can
save on memory pressure and improve throughput in cases where the data are not
immediately relevant.

To create a `CapnpReader` object that will return `Stamp` instances with the
`data` field NOT populated, pass the `SeticoreCapnp.nodata_factory` function to
the `CapnpReader` constructor:

```julia
using SeticoreCapnp

nodata_reader = CapnpReader(SeticoreCapnp.nodata_factory, Stamp, "somefile.stamps")
```

Every `Stamp` obtained by iterating `nodata_reader` will have a `data` field
that is an empty 4-dimensional `Array`.  The same technique can be used with
`Hit` as well, where the resulting `Hit` instances will have an empty `Matrix`
(i.e. an empty 2-dimensional `Array`).

### More details

The CapnpReader type is now parameterized with a type parameter `T` and
a factory function parameter `F`: `CapnpReader{T,F}`. The type parameter
indicates the type of object that will be constructed from the Capnp
file on each iteration and the factory function will be used to perform
the construction.  The factory function need not return (just) an
instance of the type, but that is the most basic/common case.  Several
factory functions are provided, but the user can define their own
factory functions if desired.  A factory function must have a method
with a signature that matches this:

```julia
my_factory_function(::Type{T}, t::Tuple{Vector{UInt64}, Int64})
```

The `T` type may be an explicit type or a parameterized type.  If the
return type of the factory function is known, the user may provide a
method for `Base.IteratorEltype` that takes a
`::Type{CapnpReader{T,my_factory_function}}` type and returns
`Base.Eltype()` as well as a `Base.eltype` method that returns the type
returned by the factory function.  See the existing factory code in
`src/capnp.jl`.

The following factory methods are provided:

- `default_factory(::Type{Tuple}, t:Tuple{Vector{UInt64}, Int64})`

  Low level factory that simply returns `t`.

- `default_factory(::Type{T}, t:Tuple{Vector{UInt64}, Int64}) where T`

  Default factory that returns `T(t)`.

- `index_factory(::Type{T}, t:Tuple{Vector{UInt64}, Int64}) where T`

  Like `default_factory` but returns a `Tuple{T,Int64}` where the `Int64`
  is the one-based word (`UInt64`) index of the start of the frame from which
  the object was read.

- `nodata_factory(::Type{T}, t:Tuple{Vector{UInt64}, Int64}) where T`

  Like `default_factory` but passes `withdata=false` to omit data (i.e. the
  `data` field is an empty `Array`).  The `withdata` keyword is supported by the
  `Filterbank`, `Hit` and `Stamp` constructors.  Returns an instance of `T`.

- `nodata_index_factory(::Type{T}, t:Tuple{Vector{UInt64}, Int64}) where T`

  Like `index_factory` but also omits the data field like `nodata_factory`.

### More on flattening with index factory functions

When using `index_factory` or `nodata_index_factory`, the type returned by
iterating is a `Tuple{T, Int64}`, where `T` is typically `Hit` or `Stamp`.
These extra return values can be passed to the `NamedTuple` constructors for
`Hit` and `Stamp` to create additional fields in the `NamedTuple` instances.
Using `map` over the `CapnpReader` provides a way to create a Vector of
`NamedTuple`s with these addition fields:

```julia
# Create a CapnpReader that uese the nodata_index_factory
nodata_index_hit_reader = CapnpReader(nodata_index_factory, Hit, "myhits.hits")

# Create a Vector or NamedTuples with an extra fileindex field
nts = map(nodata_index_hit_reader) do (hit, fileindex)
    NamedTuple(hit; fileindex)
end

# Create a DataFrame from the NamedTuples
df = DataFrame(nts)

# Do it without retaining the Vector of NamedTuples
df1 = map(nodata_index_hit_reader) do (hit, fileindex)
    NamedTuple(hit; fileindex)
end |> DataFrame
```
