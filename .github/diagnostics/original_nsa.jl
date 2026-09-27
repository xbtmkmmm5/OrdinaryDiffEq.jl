using Test
mode = get(ARGS, 1, "source")
suite = get(ARGS, 2, "reuse")
if mode != "source"
    prefix = first(split(read(joinpath(@__DIR__, "nsa_reuse.jl"), String), "original = read"))
    include_string(Main, prefix)
end
files = suite == "reuse" ? ["nsa_jacobian_reuse_tests.jl"] : ["nsa_noinit_tests.jl", "nsa_conditioning_tests.jl", "nsa_residual_convergence_tests.jl", "nsa_dae_tests.jl", "nsa_nlstep_data_field_tests.jl"]
for file in files
    @testset "$file" begin
        m = Module(gensym(:OriginalTests))
        Base.include(m, abspath("lib/OrdinaryDiffEqNonlinearSolve/test", file))
    end
end
