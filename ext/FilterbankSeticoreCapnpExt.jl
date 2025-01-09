module FilterbankSeticoreCapnpExt

using SeticoreCapnp: Hit
import Blio.Filterbank.Header

"""
Construct a Filterbank.Header from a SeticoreCapnp.Hit object.
"""
function Header(h::Hit)
    f = h.filterbank

    headerdict = Dict{Symbol, Any}(
        # Int32s
        :telescop_id => f.telescopeId.
        :ibeam => f.beam
        # Int64s
        :nbits => 32,
        :nsamples => f.numTimesteps,
        :nchans => f.numChannels
        :nifs => 1,
        # Strings
        :source_name => f.sourceName,
        # Float64s
        :tstart => f.tstart,
        :tsamp => s.tsamp,
        :fch1 => f.fch1, # in MHz
        :foff => f.foff, # in MHz
        # Angles
        :src_raj => s.ra,
        :src_dej => s.dec
    )

    return Header(headerdict)
end

end # module FilterbankSeticoreCapnpExt