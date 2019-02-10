using CrypticCrosswords
const CC = CrypticCrosswords

@testset "Insertions" begin
    out = String[]
    buffer = Vector{Char}()
    CC.insertions!(out, buffer, "a", "b")
    @test isempty(out)

    empty!(out)
    CC.insertions!(out, buffer, "a", "bc")
    @test out == ["bac"]

    empty!(out)
    CC.insertions!(out, buffer, "", "bc")
    @test isempty(out)
end
