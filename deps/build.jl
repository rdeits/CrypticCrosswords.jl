using DataDeps
using WordNet

@warn "The build process for CrypticCrosswords.jl will automatically download the WordNet 3.0, OpenOffice-MyThes, and SCOWL-wordlist-en_US-large corpora. Please see https://github.com/rdeits/CrypticCrosswords.jl#additional-license-information for information about the licenses for these corpora."

# The license issues are covered in the Readme
prev = get(ENV, "DATADEPS_ALWAYS_ACCEPT", nothing)
try
    ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"
    include("data_registration.jl")
    datadep"WordNet 3.0"
    datadep"OpenOffice-MyThes-1.0"
    datadep"SCOWL-wordlist-en_US-large"
finally
    if prev !== nothing
        ENV["DATADEPS_ALWAYS_ACCEPT"] = prev
    end
end
