using DataDeps

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
