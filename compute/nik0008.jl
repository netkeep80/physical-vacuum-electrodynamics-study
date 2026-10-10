# NIK-0008 mathematical wave 1.
# Theory-first checks: literal Earth-rotation fixture, V/C magnitude,
# and magnetic moment of ideal rotating concentric charged shells.

const EARTH_OMEGA = 7.2921159e-5       # s^-1
const EARTH_RADIUS = 6_378_137.0       # m
const LIGHT_SPEED = 299_792_458.0      # m/s

surface_speed(omega, radius) = omega * radius
vc_ratio(v, c) = v / c
shell_moment(Q, omega, R) = Q * omega * R^2 / 3
capacitor_moment(Q, omega, a, b) =
    shell_moment(Q, omega, a) + shell_moment(-Q, omega, b)

function assert_close(actual, expected; rtol=1e-10, atol=1e-12)
    @assert isfinite(actual)
    @assert isapprox(actual, expected; rtol=rtol, atol=atol)
end

# C011: literal "full lag = Earth tangential rotation speed" fixture.
v_eq = surface_speed(EARTH_OMEGA, EARTH_RADIUS)
@assert 465.0 < v_eq < 466.0
@assert abs(v_eq - 300.0) > 160.0
println("NIK0008_C011_FIXTURE_SPEED=", v_eq)

# C013: explicit V/C scale for the same fixture.
epsilon = vc_ratio(v_eq, LIGHT_SPEED)
@assert 1.5e-6 < epsilon < 1.6e-6
println("NIK0008_C013_V_OVER_C=", epsilon)

# C014: midpoint surface integration of m_z = (1/2) ∫ (r × K)_z dA
# for a uniformly charged shell rotating around z.
function shell_moment_numeric(Q, omega, R; ntheta=1200, nphi=720)
    sigma = Q / (4pi * R^2)
    dtheta = pi / ntheta
    dphi = 2pi / nphi
    total = 0.0
    for i in 0:ntheta-1
        theta = (i + 0.5) * dtheta
        # (r × K)_z = sigma * omega * R^2 * sin(theta)^2
        integrand = sigma * omega * R^2 * sin(theta)^2
        dA_theta = R^2 * sin(theta) * dtheta
        # integrand is phi-independent; still integrate the full phi measure.
        total += 0.5 * integrand * dA_theta * (nphi * dphi)
    end
    total
end

for (Q, omega, R) in ((1.0, 1.0, 1.0), (3.0, 4.0, 2.0), (-2.5, 0.7, 1.3))
    numeric = shell_moment_numeric(Q, omega, R)
    analytic = shell_moment(Q, omega, R)
    assert_close(numeric, analytic; rtol=2e-6)
end

Q, omega, a, b = 3.0, 4.0, 1.0, 2.0
m_total = capacitor_moment(Q, omega, a, b)
assert_close(m_total, (Q * omega / 3) * (a^2 - b^2))
@assert m_total != 0.0
@assert capacitor_moment(Q, 0.0, a, b) == 0.0
@assert capacitor_moment(Q, omega, a, a) == 0.0

println("NIK0008_C014_CAPACITOR_MOMENT=", m_total)

# C007: finite witness for non-unique model identification.
function uniquely_identifies(predictions, target, observation)
    matching = [model for (model, observations) in predictions if observation in observations]
    length(matching) == 1 && only(matching) == target
end

sagnac_predictions = Dict(
    :nikolaev_preferred_frame => Set([:sagnac_shift]),
    :special_relativity => Set([:sagnac_shift]),
)
@assert !uniquely_identifies(sagnac_predictions, :nikolaev_preferred_frame, :sagnac_shift)
println("NIK0008_C007_NONUNIQUE_LOGIC=PASS")

# C012: published Michelson–Gale fringe values.
mg_observed = 0.230
mg_observed_error = 0.005
mg_calculated = 0.236
mg_calculated_error = 0.002
mg_obs_lo, mg_obs_hi = mg_observed - mg_observed_error, mg_observed + mg_observed_error
mg_calc_lo, mg_calc_hi = mg_calculated - mg_calculated_error, mg_calculated + mg_calculated_error
@assert mg_obs_lo > 0
@assert max(mg_obs_lo, mg_calc_lo) <= min(mg_obs_hi, mg_calc_hi)
println("NIK0008_C012_OBS_INTERVAL=", (mg_obs_lo, mg_obs_hi))
println("NIK0008_C012_CALC_INTERVAL=", (mg_calc_lo, mg_calc_hi))


# C016: SU661656A1 uses sample motion relative to a fixed magnet.
# This is a deliberately minimal 1D Lorentz/Hall kinematic witness,
# NOT a quantitative derivation of any claimed Earth-specific anomaly.
relative_hall_signal(gain, drift, sample_speed, magnet_speed) =
    gain * (drift + sample_speed - magnet_speed)

for (gain, drift, sample_speed, magnet_speed, shift) in (
    (2.0, 0.3, 4.0, -1.0, 7.0),
    (-3.0, -0.4, 0.2, 1.5, -11.0),
    (0.75, 1e-5, -5e-4, 3e-4, 100.0),
    (0.0, 2.0, -4.0, 3.0, 8.0),
)
    baseline = relative_hall_signal(gain, drift, sample_speed, magnet_speed)
    shifted = relative_hall_signal(gain, drift, sample_speed + shift, magnet_speed + shift)
    assert_close(shifted, baseline; rtol=1e-9)
    assert_close(relative_hall_signal(gain, drift, magnet_speed - drift, magnet_speed), 0.0)
    assert_close(gain * (-drift), -(gain * drift))
end
println("NIK0008_C016_HALL_RELATIVE_FRAME_WITNESS=PASS")


# C014: a second independent midpoint quadrature, in u=cos(theta),
# tests the exact polar integral that is proved in Lean 4.
function shell_moment_polar_numeric(Q, omega, R; n=10_000)
    du = 2 / n
    integrated = 0.0
    for j in 0:n-1
        u = -1 + (j + 0.5) * du
        integrated += (1 - u^2) * du
    end
    (Q * omega * R^2 / 4) * integrated
end

for (Q, omega, R) in ((1.0, 1.0, 1.0), (3.0, 4.0, 2.0), (-2.5, 0.7, 1.3))
    assert_close(shell_moment_polar_numeric(Q, omega, R),
                 shell_moment(Q, omega, R); rtol=1e-7)
end
@assert isapprox(shell_moment_polar_numeric(3.0, 4.0, 1.0) +
                 shell_moment_polar_numeric(-3.0, 4.0, 2.0),
                 capacitor_moment(3.0, 4.0, 1.0, 2.0); rtol=1e-7)
println("NIK0008_C014_POLAR_INTEGRAL=PASS")


# C014 / independent full Cartesian cross-product and geometric surface
# Jacobian. No pre-reduction of the z integrand or area element to 1-u²
# is used in this computation.
function cross3(a, b)
    (a[2]*b[3]-a[3]*b[2],
     a[3]*b[1]-a[1]*b[3],
     a[1]*b[2]-a[2]*b[1])
end
norm3(v) = sqrt(sum(x -> x*x, v))

function shell_moment_cartesian_surface(Q, omega, R; nu=400, nphi=64)
    @assert R > 0
    sigma = Q / (4pi*R^2)
    du = 2 / nu
    dphi = 2pi / nphi
    m = 0.0
    max_jacobian_error = 0.0
    for iu in 0:nu-1
        u = -1 + (iu+0.5)*du
        t = sqrt(1-u*u)
        for iphi in 0:nphi-1
            phi = (iphi+0.5)*dphi
            cp, sp = cos(phi), sin(phi)
            r = (R*t*cp, R*t*sp, R*u)
            omega_vec = (0.0, 0.0, omega)
            rotated = cross3(omega_vec, r)
            K = (sigma*rotated[1], sigma*rotated[2], sigma*rotated[3])
            drdu = (-R*u/t*cp, -R*u/t*sp, R)
            drdphi = (-R*t*sp, R*t*cp, 0.0)
            darea_du_dphi = norm3(cross3(drdu, drdphi))
            max_jacobian_error = max(max_jacobian_error, abs(darea_du_dphi-R^2))
            m += 0.5*cross3(r,K)[3] * darea_du_dphi * du * dphi
        end
    end
    @assert max_jacobian_error < 1e-10 * max(1.0, R^2)
    m
end

for (Q, omega, R) in ((1.0, 1.0, 1.0), (3.0, 4.0, 2.0), (-2.5, 0.7, 1.3))
    assert_close(shell_moment_cartesian_surface(Q, omega, R),
                 shell_moment(Q, omega, R); rtol=1e-5)
end
assert_close(shell_moment_cartesian_surface(3.0,4.0,1.0) +
             shell_moment_cartesian_surface(-3.0,4.0,2.0),
             capacitor_moment(3.0,4.0,1.0,2.0); rtol=1e-5)
println("NIK0008_C014_3D_SURFACE_CROSS_PRODUCT=PASS")


# C014: independent pole-cap quadrature on BOTH ends of u=cos(theta).
# The exact fraction of the full polar integral is (3/2)eps²-(1/2)eps³.
# This controls endpoint contributions, but is NOT a Lean surface-measure theorem.
function c014_polar_cap_fraction_numeric(eps; n=10000)
    @assert 0.0 <= eps <= 1.0
    du = eps/n
    south = 0.0
    north = 0.0
    for i in 0:n-1
        south_u = -1 + (i+0.5)*du
        north_u = 1-eps + (i+0.5)*du
        south += (1-south_u^2)*du
        north += (1-north_u^2)*du
    end
    (south+north)/(4/3)
end
for cap_eps in (0.0, 0.001, 0.03, 0.2, 1.0)
    exact = 1.5*cap_eps^2 - 0.5*cap_eps^3
    assert_close(c014_polar_cap_fraction_numeric(cap_eps), exact;
                 rtol=1e-6, atol=1e-10)
end
println("NIK0008_C014_POLE_CAPS=PASS")


# C014 / independent six-face cubed-sphere quadrature. This is an
# independently parameterized surface integral, not the earlier
# u=cos(theta)/phi construction and not a Lean measure theorem.
function c014_cubed_sphere_surface(Q, omega, R; n=96)
    @assert R > 0 && isfinite(R) && n >= 2
    sigma = Q/(4pi*R^2)
    delta = 2/n
    area = 0.0
    moment = 0.0
    Ix, Iy, Iz = 0.0, 0.0, 0.0
    max_jac_relative_error = 0.0
    for axis in 1:3
        ia = mod1(axis+1,3)
        ib = mod1(axis+2,3)
        for side in (-1.0,1.0), i in 0:n-1, j in 0:n-1
            a = -1 + (i+0.5)*delta
            b = -1 + (j+0.5)*delta
            v = zeros(3)
            ea = zeros(3)
            eb = zeros(3)
            v[axis] = side
            v[ia], v[ib] = a, b
            ea[ia] = 1.0
            eb[ib] = 1.0
            D = norm3(v)
            point = ntuple(k -> R*v[k]/D, 3)
            drda = ntuple(k -> R*(ea[k]/D-v[k]*a/D^3), 3)
            drdb = ntuple(k -> R*(eb[k]/D-v[k]*b/D^3), 3)
            jac = norm3(cross3(drda, drdb))
            expected_jac = R^2/D^3
            max_jac_relative_error = max(max_jac_relative_error,
                                          abs(jac-expected_jac)/expected_jac)
            K = ntuple(k -> sigma*cross3((0.0,0.0,omega),point)[k], 3)
            darea = jac*delta^2
            area += darea
            moment += 0.5*cross3(point,K)[3]*darea
            Ix += point[1]^2*darea
            Iy += point[2]^2*darea
            Iz += point[3]^2*darea
        end
    end
    @assert max_jac_relative_error < 2e-12
    (; area, moment, Ix, Iy, Iz, max_jac_relative_error)
end

let previous_area_error = Inf
for n in (12,24,48,96)
    result = c014_cubed_sphere_surface(3.0,4.0,2.0;n=n)
    area_error = abs(result.area/(4pi*4)-1)
    moment_error = abs(result.moment/shell_moment(3.0,4.0,2.0)-1)
    @assert area_error < previous_area_error && moment_error < 4e-3
    if isfinite(previous_area_error)
        @assert area_error < 0.3*previous_area_error
    end
    previous_area_error = area_error
    assert_close(result.Ix,result.Iy;rtol=1e-10)
    assert_close(result.Iy,result.Iz;rtol=1e-10)
end
end # explicit Julia local scope for refinement accumulator
for (q,w,radius) in ((1.0,1.0,1.0),(-2.5,0.7,1.3),
                     (4.0,-3.0,0.25),(3.0,0.0,2.0))
    value = c014_cubed_sphere_surface(q,w,radius;n=96)
    assert_close(value.area,4pi*radius^2;rtol=3.5e-5)
    assert_close(value.moment,shell_moment(q,w,radius);rtol=3.5e-5)
end
for (q,w) in ((0.0,4.0),(4.0,0.0))
    result = c014_cubed_sphere_surface(q,w,1.0;n=24)
    assert_close(result.moment,0.0)
end
println("NIK0008_C014_CUBED_SPHERE_INDEPENDENT_QUADRATURE=PASS")

println("NIK0008_JULIA_PASS")
