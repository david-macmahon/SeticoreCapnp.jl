using SeticoreCapnp, Blio, RadioInterferometry, Dates

"""
Generates a GUPPI RAW header from a stamp file.
"""
function rawheader(stamp)
    s = NamedTuple(stamp)
    mjd = datetime2julian(unix2datetime(s.tstart)) - 2_400_000.5
    smjd = 24*60*60*(mjd%1)
    headerdict = Dict{Symbol, Any}(
        :blocsize => sizeof(stamp.data),
        :npol => s.numPolarizations,
        :obsnchan => s.numChannels*s.numAntennas,
        :nbits => 8,
        :obsfreq => s.fch1 + (s.numChannels - 1)*s.foff/2, # in MHz
        :obsbw => s.foff*s.numChannels, # in MHz
        :tbin => s.tsamp,
        :directio => 0,
        :pktidx => 0,
        :beam_id => s.beam,
        :nbeam => 1,
        :nants => s.numAntennas,
        :ra_str => deg2hmsstr(s.ra, hourwidth=2),
        :dec_str => deg2dmsstr(s.dec),
        :stt_imjd => floor(Int, mjd),
        :stt_smjd => floor(Int, smjd),
        :src_name => s.sourceName,
        :telescop => s.telescopeId)
    return GuppiRaw.Header(headerdict)
end