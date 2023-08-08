module Lseek

const SEEK_SET = 0
const SEEK_CUR = 1
const SEEK_END = 2

"""
    lseek(io::IO, offset=0, whence=SEEK_CUR)

Calls the system `lseek` function on `io`'s underlying file descriptor.  The
motivation for this function is to get the current position of the file
descriptor after external code (e.g. a C library) has advanced the file
descriptor's position unbeknownst to `io`.
"""
function lseek(io::IO, offset=0, whence=SEEK_CUR)::Int64
    @ccall lseek(fd(io)::Cint, offset::Cssize_t, whence::Cint)::Cssize_t
end

end # module Lseek
