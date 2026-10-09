# NIK-0007-C005
# Independent computational reproduction of the purely algebraic relation
# E = m*c^2 <-> m = E/c^2 for c != 0.
# This file does not assign a physical interpretation to m.

mass_from_energy(E, c) = E / c^2
energy_from_mass(m, c) = m * c^2

function assert_close(actual, expected; rtol=1e-12, atol=0.0)
    @assert isfinite(actual)
    @assert isapprox(actual, expected; rtol=rtol, atol=atol)
end

for m in (0.0, 1.0e-30, 1.0, -2.5, 3.7e12)
    for c in (1.0, 2.0, 299_792_458.0)
        E = energy_from_mass(m, c)
        assert_close(mass_from_energy(E, c), m; rtol=1e-12, atol=1e-30)
    end
end

# Dimensional-exponent check in the base dimensions (M, L, T):
# [E] = M L^2 T^-2, [c] = L T^-1, hence [E/c^2] = M.
energy_dim = (1, 2, -2)
velocity_dim = (0, 1, -1)
mass_dim = ntuple(i -> energy_dim[i] - 2 * velocity_dim[i], 3)
@assert mass_dim == (1, 0, 0)

# Reproducible reference value: mass-equivalent of one joule.
c0 = 299_792_458.0
one_joule_mass = mass_from_energy(1.0, c0)
assert_close(one_joule_mass, 1.1126500560536185e-17; rtol=1e-15)

println("NIK0007_C005_JULIA_PASS")
