using Test, SafeTestsets, Pkg, SciMLTesting
const TEST_GROUP = "Core"
groups = Dict(
    "foundation" => ["developer_api_tests.jl", "newton_tests.jl", "predictor_tests.jl", "sparse_dae_initialization_tests.jl", "linear_nonlinear_tests.jl", "linear_solver_tests.jl", "linear_solver_split_ode_tests.jl", "default_krylov_preconditioner_tests.jl"],
    "mass_matrix" => ["mass_matrix_tests.jl", "wprototype_tests.jl", "dae_initialization_tests.jl", "checkinit_tests.jl", "nested_ad_nlsolvealg_tests.jl"],
    "iteration" => ["nsa_jacobian_reuse_tests.jl", "homotopy_nlsolve_tests.jl", "homotopy_default_nlsolve_tests.jl", "nsa_sparse_tests.jl", "nsa_matrixfree_tests.jl", "nsa_lhl_split_w_tests.jl", "nsa_krylov_tolerance_tests.jl", "nsa_smooth_est_tests.jl", "nsa_stale_w_reuse_tests.jl", "nsa_stats_tests.jl", "nsa_polyalg_tests.jl"],
    "convergence" => ["nsa_noinit_tests.jl", "nsa_conditioning_tests.jl", "nsa_residual_convergence_tests.jl", "nsa_dae_tests.jl", "nsa_nlstep_data_field_tests.jl"],
)
base = joinpath(pwd(), "lib", "OrdinaryDiffEqNonlinearSolve", "test")
for file in groups[only(ARGS)]
    @eval @safetestset $file begin
        include($(joinpath(base, file)))
    end
    flush(stdout)
    flush(stderr)
end
