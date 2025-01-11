module SeticoreCapnp

export CapnpReader, Hit, Stamp
export save_hits

using Mmap
using PyCall
import Core: NamedTuple

abstract type AbstractCapnpStruct end

include("capnp.jl")
include("equality.jl")

const CapnpHit = Ref{PyObject}()
const CapnpStamp = Ref{PyObject}()

function __init__()
    capnp = pyimport("capnp")
    CapnpHit[] = capnp.load(joinpath(@__DIR__, "hit.capnp"))
    CapnpStamp[] = capnp.load(joinpath(@__DIR__, "stamp.capnp"))
    nothing
end

function getmissingfield(maybemissing, fieldsym)
    ismissing(maybemissing) ? missing : getfield(maybemissing, fieldsym)
end

include("hit.jl")
include("stamp.jl")

end # module SeticoreCapnp
