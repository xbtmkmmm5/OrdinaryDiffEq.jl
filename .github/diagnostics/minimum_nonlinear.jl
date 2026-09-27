using Pkg, TOML
name = only(ARGS)
workspace = pwd()
package_dir = joinpath(workspace, "lib", name)
package = TOML.parsefile(joinpath(package_dir, "Project.toml"))
# The downgrade action records the minimum resolution in the Manifest. Starting a
# new resolve from Project compat bounds would silently select current versions.
manifest = TOML.parsefile(joinpath(package_dir, "Manifest.toml"))
resolved = Dict(name => only(entries)["version"] for (name, entries) in manifest["deps"] if haskey(only(entries), "version"))
deps = merge(package["deps"], package["extras"])
deps[name] = package["uuid"]
for dep in keys(deps)
    haskey(manifest["deps"], dep) || error("Downgrade manifest is missing test dependency $dep")
end
compat = Dict(k => v for (k,v) in package["compat"] if k == "julia" || haskey(deps,k))
for entries in values(manifest["deps"]), entry in entries
    if haskey(entry, "path")
        entry["path"] = abspath(package_dir, entry["path"])
    end
end
env = joinpath(workspace, ".validation-env")
mkpath(env)
project_file = joinpath(env,"Project.toml")
open(io -> TOML.print(io, Dict("deps"=>deps, "compat"=>compat)), project_file, "w")
manifest["project_hash"] = Pkg.Types.project_resolve_hash(Pkg.Types.read_project(project_file))
open(io -> TOML.print(io, manifest), joinpath(env,"Manifest.toml"), "w")
Pkg.activate(env)
Pkg.instantiate(;allow_autoprecomp=false)
after = TOML.parsefile(joinpath(env,"Manifest.toml"))
for (dep, version) in resolved
    actual = only(after["deps"][dep])["version"]
    actual == version || error("Downgraded version changed for $dep: $version -> $actual")
end
println("Verified unchanged downgrade resolution for ", length(resolved), " versioned dependencies")
Pkg.status()
