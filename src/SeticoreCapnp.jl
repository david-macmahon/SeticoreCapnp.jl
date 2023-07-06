module SeticoreCapnp

export load_hits
export save_hits
export load_stamps

using PyCall
using DataFrames

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