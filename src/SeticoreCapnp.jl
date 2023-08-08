module SeticoreCapnp

export load_hits, load_hit
export save_hits
export load_stamps, load_stamp

using PyCall
using OrderedCollections

include("lseek.jl")
using .Lseek: lseek

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
