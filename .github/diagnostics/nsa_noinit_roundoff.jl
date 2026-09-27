using OrdinaryDiffEqNonlinearSolve
p=joinpath(dirname(pathof(OrdinaryDiffEqNonlinearSolve)), "newton.jl")
code=match(r"(?s)@muladd function compute_step!\(nlsolver::NLSolver\{<:NonlinearSolveAlg, true\}, integrator\)\n.*?\nend", read(p,String)).match
old="if !SciMLBase.successful_retcode(innersol.retcode)\n            return convert(eltype(atmp), Inf)"
@eval OrdinaryDiffEqNonlinearSolve @noinline function _noinit_roundoff_candidate(nlsolver, innersol)
    (; cache, tmp, method) = nlsolver
    innersol.retcode === SciMLBase.ReturnCode.MaxIters || return false
    method === COEFFICIENT_MULTISTEP && cache.W !== nothing || return false
    all(isfinite, innersol.u) || return false
    nlcache = cache.cache
    residual = similar(innersol.u)
    nlcache.prob.f(residual, innersol.u, nlcache.prob.p)
    inner_abstol = NonlinearSolveBase.get_abstol(nlcache)
    for i in eachindex(residual, tmp, cache.k)
        ri = residual[i]
        mass_term = tmp[i] + cache.k[i] - ri
        rounding_scale = max(abs(tmp[i]), abs(cache.k[i]), abs(mass_term))
        bound = max(inner_abstol, roundoff_level(typeof(real(ri))) * rounding_scale)
        isfinite(ri) && isfinite(bound) && abs(ri) <= bound || return false
    end
    return true
end
new=raw"""if !SciMLBase.successful_retcode(innersol.retcode)
            _noinit_roundoff_candidate(nlsolver, innersol) || return convert(eltype(atmp), Inf)"""
occursin(old,code)||error("missing branch")
Base.include_string(OrdinaryDiffEqNonlinearSolve,replace(code,old=>new),p)
