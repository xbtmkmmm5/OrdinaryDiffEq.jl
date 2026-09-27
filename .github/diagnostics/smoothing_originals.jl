using Test, SafeTestsets
root = normpath(joinpath(@__DIR__, "..", ".."))
files = if only(ARGS) == "roundoff"
    ["test/Regression_I/newton_krylov_roundoff.jl",
     "lib/OrdinaryDiffEqDifferentiation/test/krylov_linear_tolerance_tests.jl",
     "lib/OrdinaryDiffEqDifferentiation/test/warm_start_default_tests.jl",
     "lib/OrdinaryDiffEqNonlinearSolve/test/linear_solver_split_ode_tests.jl",
     "lib/OrdinaryDiffEqNonlinearSolve/test/default_krylov_preconditioner_tests.jl"]
else
    ["lib/OrdinaryDiffEqSDIRK/test/tableau_consistency_tests.jl",
     "lib/OrdinaryDiffEqSDIRK/test/predictor_tests.jl",
     "lib/OrdinaryDiffEqSDIRK/test/sdirk_convergence_tests.jl",
     "lib/OrdinaryDiffEqSDIRK/test/dae_esdirk_test.jl"]
end
for file in files
    @eval @safetestset $file begin
        include($(joinpath(root, file)))
    end
    flush(stdout)
end
