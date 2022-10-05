module SeticoreCapnp

export load_hits
export load_stamps

using PythonCall
using DataFrames

const CapnpHit = Ref{Py}()
const CapnpStamp = Ref{Py}()

function __init__()
    capnp = pyimport("capnp")
    CapnpHit[] = capnp.load(joinpath(@__DIR__, "hit.capnp"))
    CapnpStamp[] = capnp.load(joinpath(@__DIR__, "stamp.capnp"))
    nothing
end

include("hit.jl")
include("stamp.jl")

end # module SeticoreCapnp