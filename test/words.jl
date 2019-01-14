@testset "Straddling words" begin
    phrase = "abc de fghi"
    @test sort(CrypticCrosswords.straddling_words(phrase, x -> true)) == [
        "bcdef",
        "bcdefg",
        "bcdefgh",
        "cdef",
        "cdefg",
        "cdefgh",
    ]

    @test CrypticCrosswords.straddling_words("abcde", x -> true) == String[]

    @test CrypticCrosswords.straddling_words("ab cd", x -> true) == ["bc"]
end
