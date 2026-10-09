using LinearAlgebra

# Infrastructure only: no Nikolaev claim is evaluated here.
@assert VERSION == v"1.13.1"
a = [1.0, 2.0, 3.0]
b = [4.0, 5.0, 6.0]
@assert dot(a, b) == 32.0
println("PVE_JULIA_SMOKE_PASS version=", VERSION)
