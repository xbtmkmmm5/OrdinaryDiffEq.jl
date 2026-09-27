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
elseif mode != "source"
    error("Unknown diagnostic mode")
end
original = read(joinpath(pwd(), "lib", "OrdinaryDiffEqNonlinearSolve", "test", "nsa_jacobian_reuse_tests.jl"), String)
setup = first(split(original, "@testset \"dt-only W updates reuse the stored Jacobian\""))
include_string(Main, setup)
staleprob = ODEProblem(rober!, [1.0, 0.0, 0.0], (0.0, 1.0e11), [0.04, 3.0e7, 1.0e4])
for (label, alg) in (("NLNewton", KenCarp4()), ("NonlinearSolveAlg", KenCarp4(nlsolve=nsa)))
    elapsed = @elapsed sol = solve(staleprob, alg; reltol=1.0e-9, abstol=1.0e-12)
    println((; mode, label, elapsed, retcode=sol.retcode, final=sol.u[end], stats=sol.stats))
    flush(stdout)
end
