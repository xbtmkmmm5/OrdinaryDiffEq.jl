using OrdinaryDiffEqCore, OrdinaryDiffEqNonlinearSolve
using LinearAlgebra, SciMLBase
mode = get(ARGS, 1, "source")
if mode == "no_rounding"
    p = joinpath(dirname(pathof(OrdinaryDiffEqCore)), "integrators", "integrator_utils.jl")
    code = match(r"(?s)function calc_dt_propose!\(integrator, dtnew\).*?    return nothing\nend", read(p, String)).match
    code = replace(code, "if integrator.opts.adaptive &&" => "if false && integrator.opts.adaptive &&")
    Base.include_string(OrdinaryDiffEqCore, code, p)
elseif mode == "no_stall"
    @eval OrdinaryDiffEqNonlinearSolve stalled_inner_step(nlcache, ndisp, nz, fnorm_prev, γΔt) = false
elseif mode == "raw_direction"
    p = joinpath(dirname(pathof(OrdinaryDiffEqNonlinearSolve)), "newton.jl")
    code = match(r"(?s)@muladd function compute_step!\(nlsolver::NLSolver\{<:NonlinearSolveAlg, true\}, integrator\)\n.*?\nend", read(p, String)).match
    old = "@.. broadcast = false atmp = z - ztmp"
    occursin(old, code) || error("Expected displacement calculation was not found")
    code = replace(code, old => "direction = SciMLBase.get_du(nlcache)\n        @.. broadcast = false atmp = -direction")
    Base.include_string(OrdinaryDiffEqNonlinearSolve, code, p)
elseif mode == "fma_residual"
    p = joinpath(dirname(pathof(OrdinaryDiffEqNonlinearSolve)), "newton.jl")
    code = match(r"(?s)function _compute_rhs!\(\n        tmp::Array, ztmp::Array, ustep::Array, γ, α, tstep, k,\n.*?\nend", read(p, String)).match
    code = replace(code, "(dt * k[i] - z[i]) * invγdt" => "muladd(dt, k[i], -z[i]) * invγdt", "(dt * k[i] - ztmp[i]) * invγdt" => "muladd(dt, k[i], -ztmp[i]) * invγdt")
    Base.include_string(OrdinaryDiffEqNonlinearSolve, code, p)
elseif mode != "source"
    error("Unknown diagnostic mode")
end
original = read(abspath("lib/OrdinaryDiffEqNonlinearSolve/test/nsa_jacobian_reuse_tests.jl"), String)
setup = first(split(original, "@testset \"dt-only W updates reuse the stored Jacobian\""))
include_string(Main, setup)
staleprob = ODEProblem(rober!, [1.0, 0.0, 0.0], (0.0, 1.0e11), [0.04, 3.0e7, 1.0e4])
for (label, alg) in (("NLNewton", KenCarp4()), ("NonlinearSolveAlg", KenCarp4(nlsolve=nsa)))
    elapsed = @elapsed sol = solve(staleprob, alg; reltol=1.0e-9, abstol=1.0e-12)
    println((; mode, label, elapsed, retcode=sol.retcode, final=sol.u[end], stats=sol.stats))
    bins = Dict{Int,Int}()
    for t in sol.t[2:end]
        bucket = floor(Int, log10(t))
        bins[bucket] = get(bins, bucket, 0) + 1
    end
    println("time decades: ", sort(collect(bins); by=first))
    flush(stdout)
end
