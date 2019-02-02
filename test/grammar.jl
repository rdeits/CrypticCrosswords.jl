using CrypticCrosswords
const CC = CrypticCrosswords

@testset "Insertions" begin
    out = String[]
    CC.insertions!(out, "a", "b")
    @test isempty(out)

    empty!(out)
    CC.insertions!(out, "a", "bc")
    @test out == ["bac"]

    empty!(out)
    CC.insertions!(out, "", "bc")
    @test isempty(out)
end
