import Base: ==
import Base: hash

function ==(s1::T, s2::T) where T <: AbstractCapnpStruct
    all(f->getfield(s1, f) == getfield(s2, f), fieldnames(T))
end

function hash(s::T, h::UInt=zero(UInt)) where T<: AbstractCapnpStruct
    foldr(hash, getfield.(Ref(s), fieldnames(T)), init=h)
end