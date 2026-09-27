using Pkg, TOML
name = ARGS[1]
workspace = pwd()
root = name == "SimpleNonlinearSolve" ? joinpath(workspace,"nonlinear-dependency") : workspace
package = TOML.parsefile(joinpath(root, "lib", name, "Project.toml"))
deps = merge(package["deps"], package["extras"])
deps[name] = package["uuid"]
compat = Dict(k => v for (k,v) in package["compat"] if k == "julia" || haskey(deps,k))
env = joinpath(workspace, ".validation-env")
mkpath(env)
open(joinpath(env,"Project.toml"),"w") do io
    TOML.print(io, Dict("deps"=>deps,"compat"=>compat))
end
local_paths = Dict{String,String}()
function collect_local(n)
    haskey(local_paths,n) && return
    path = n in ("SimpleNonlinearSolve", "NonlinearSolveBase", "BracketingNonlinearSolve") ? joinpath(workspace,"nonlinear-dependency","lib",n) : joinpath(root,"lib",n)
    isfile(joinpath(path,"Project.toml")) || return
    local_paths[n] = path
    p = TOML.parsefile(joinpath(path,"Project.toml"))
    foreach(collect_local,keys(get(p,"deps",Dict())))
end
foreach(collect_local,keys(deps))
Pkg.activate(env)
Pkg.develop([PackageSpec(path=p) for p in values(local_paths)])
Pkg.instantiate(;allow_autoprecomp=false)
Pkg.status()
