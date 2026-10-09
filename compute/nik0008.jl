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

println("NIK0008_JULIA_PASS")
