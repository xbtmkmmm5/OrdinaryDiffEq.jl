using Test, SafeTestsets
root = normpath(joinpath(@__DIR__, "..", ".."))
for file in [
    "test/Regression_I/newton_krylov_roundoff.jl",
    "lib/OrdinaryDiffEqDifferentiation/test/krylov_linear_tolerance_tests.jl",
    "lib/OrdinaryDiffEqDifferentiation/test/warm_start_default_tests.jl",
    "lib/OrdinaryDiffEqNonlinearSolve/test/linear_solver_split_ode_tests.jl",
    "lib/OrdinaryDiffEqNonlinearSolve/test/default_krylov_preconditioner_tests.jl",
]
    @eval @safetestset $file begin
        include($(joinpath(root, file)))
    end
    flush(stdout)
end
