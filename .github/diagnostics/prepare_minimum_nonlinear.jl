using Pkg, TOML
workspace = pwd()
fixed = joinpath(workspace, ".validation-simple")
cp(joinpath(workspace, "nonlinear-dependency", "lib", "SimpleNonlinearSolve"), fixed)
p = TOML.parsefile(joinpath(fixed, "Project.toml"))
pop!(p, "sources", nothing)
open(io -> TOML.print(io, p), joinpath(fixed, "Project.toml"), "w")
project = joinpath(workspace, "lib", "OrdinaryDiffEqNonlinearSolve", "Project.toml")
p = TOML.parsefile(project)
p["sources"]["SimpleNonlinearSolve"] = Dict("path"=>"../../.validation-simple")
open(io -> TOML.print(io, p), project, "w")
skip = [v isa AbstractString ? v : first(v) for v in values(Pkg.Types.stdlibs())]
append!(skip, [basename(path) for path in readdir(joinpath(workspace,"lib");join=true) if isfile(joinpath(path,"Project.toml"))])
push!(skip, "SimpleNonlinearSolve")
open(ENV["GITHUB_ENV"], "a") do io
    println(io,"DOWNGRADE_SKIP=",join(sort!(unique!(skip)),","))
end
