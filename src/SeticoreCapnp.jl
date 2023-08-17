module SeticoreCapnp

export CapnpReader, Hit, Stamp
export save_hits

using Mmap
using PyCall

include("capnp.jl")

const CapnpHit = Ref{PyObject}()
const CapnpStamp = Ref{PyObject}()

function __init__()
    capnp = pyimport("capnp")
    CapnpHit[] = capnp.load(joinpath(@__DIR__, "hit.capnp"))
    CapnpStamp[] = capnp.load(joinpath(@__DIR__, "stamp.capnp"))
    nothing
end

include("hit.jl")
include("stamp.jl")

end # module SeticoreCapnp
