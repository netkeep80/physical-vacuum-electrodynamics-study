import Physlib.Electromagnetism.Kinematics.GaugeTransformation
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

namespace PVE.NIK0008

/-- Fixture angular velocity, s⁻¹ (radians dimensionless): 7.2921159e-5. -/
noncomputable def earthOmega : ℝ := 72921159 / 1000000000000

/-- Fixture equatorial radius, m: 6 378 137. -/
def earthRadius : ℝ := 6378137

/-- Tangential speed v = ωR for the explicit fixture. -/
noncomputable def earthSurfaceSpeed : ℝ := earthOmega * earthRadius

/--
NIK-0008-C011: with the explicit fixture above, the literal tangential speed
corresponding to "full lag from Earth's rotation" is between 465 and 466 m/s,
not near 300 m/s. This theorem is conditional on identifying the claimed
"full lag" with ωR; the book does not show its own derivation of 300 m/s.
-/
theorem c011_fixture_surface_speed :
    465 < earthSurfaceSpeed ∧ earthSurfaceSpeed < 466 := by
  norm_num [earthSurfaceSpeed, earthOmega, earthRadius]

/-- Fixture vacuum light speed, m/s. -/
def lightSpeed : ℝ := 299792458

/-- Dimensionless kinematic ratio V/C for the same fixture. -/
noncomputable def earthVC : ℝ := earthSurfaceSpeed / lightSpeed

/--
NIK-0008-C013: the explicit Earth-rotation fixture gives a V/C parameter
between 1.5e-6 and 1.6e-6.
-/
theorem c013_fixture_v_over_c :
    (15 : ℝ) / 10000000 < earthVC ∧ earthVC < (16 : ℝ) / 10000000 := by
  norm_num [earthVC, earthSurfaceSpeed, earthOmega, earthRadius, lightSpeed]

/-- Magnetic dipole moment of an ideal uniformly charged rotating spherical shell. -/
noncomputable def shellMoment (Q ω R : ℝ) : ℝ := Q * ω * R^2 / 3

/--
Two concentric capacitor shells carry +Q at radius a and -Q at radius b,
and rotate with the same angular velocity ω.
-/
noncomputable def capacitorMoment (Q ω a b : ℝ) : ℝ :=
  shellMoment Q ω a + shellMoment (-Q) ω b

/--
NIK-0008-C014: under the stated ideal shell-moment model, the total magnetic
moment is Q*ω/3*(a²-b²). Thus opposite total charges do not generally cancel
the rotational magnetic moment when their radii differ.
-/
theorem c014_capacitor_moment_formula (Q ω a b : ℝ) :
    capacitorMoment Q ω a b = (Q * ω / 3) * (a^2 - b^2) := by
  simp [capacitorMoment, shellMoment]
  ring

/--
For nonzero charge, nonzero rotation and unequal squared radii, the ideal
rotating spherical capacitor has nonzero magnetic dipole moment.
-/
theorem c014_capacitor_moment_nonzero
    (Q ω a b : ℝ)
    (hQ : Q ≠ 0) (hω : ω ≠ 0) (hr : a^2 ≠ b^2) :
    capacitorMoment Q ω a b ≠ 0 := by
  rw [c014_capacitor_moment_formula]
  exact mul_ne_zero (div_ne_zero (mul_ne_zero hQ hω) (by norm_num)) (sub_ne_zero.mpr hr)

/--
A homogeneous linear field transformation maps an exactly zero local EM
field to zero. This captures only the zero-field part of the "move the
detector outside a static ideal capacitor" scenario.
-/
abbrev EMField := Fin 6 → ℝ

theorem c014_zero_field_remains_zero
    (T : EMField →ₗ[ℝ] EMField) :
    T 0 = 0 := by
  exact map_zero T


/--
NIK-0008-C007: an observation cannot uniquely identify a target model if a
different model predicts the same observation. This is a purely logical
identifiability lemma; the physical premise that an alternative model predicts
the Sagnac effect is supplied separately by literature evidence.
-/
def uniquelyIdentifies {Model Observation : Type}
    (predicts : Model → Observation → Prop) (target : Model) (obs : Observation) : Prop :=
  ∀ model, predicts model obs → model = target

theorem c007_not_unique_if_alternative_predicts
    {Model Observation : Type}
    (predicts : Model → Observation → Prop)
    (target alternative : Model)
    (obs : Observation)
    (hDifferent : alternative ≠ target)
    (hAlternative : predicts alternative obs) :
    ¬ uniquelyIdentifies predicts target obs := by
  intro hUnique
  exact hDifferent (hUnique alternative hAlternative)

/--
NIK-0008-C012: Michelson–Gale's published central shift 0.230 with ±0.005
uncertainty is strictly nonzero.
-/
theorem c012_michelson_gale_observed_interval_nonzero :
    (0 : ℝ) < (230 : ℝ) / 1000 - (5 : ℝ) / 1000 := by
  norm_num

/--
The published observed interval 0.230±0.005 overlaps the calculated
0.236±0.002 interval. This checks only the reported arithmetic, not the
physical interpretation of the experiment.
-/
theorem c012_michelson_gale_intervals_overlap :
    ((236 : ℝ) / 1000 - (2 : ℝ) / 1000 ≤
      (230 : ℝ) / 1000 + (5 : ℝ) / 1000) ∧
    ((230 : ℝ) / 1000 - (5 : ℝ) / 1000 ≤
      (236 : ℝ) / 1000 + (2 : ℝ) / 1000) := by
  norm_num


/--
NIK-0008-C016: minimal one-dimensional kinematic witness for the Hall-device
patent SU661656A1. "drift" is the signed carrier speed relative to the
sample, "sample" and "magnet" are signed speeds in an arbitrary common
coordinate system. "gain" collects the fixed Hall-geometry and field factors.

This is NOT a derivation of Nikolaev's alleged Earth-specific anomaly.
It checks whether the patent's cancellation setup can, by itself,
identify a privileged frame. It cannot: a common velocity shift of
sample and magnet leaves the signal invariant.
-/
noncomputable def relativeHallSignal (gain drift sample magnet : ℝ) : ℝ :=
  gain * (drift + sample - magnet)

theorem c016_hall_common_frame_shift
    (gain drift sample magnet shift : ℝ) :
    relativeHallSignal gain drift (sample + shift) (magnet + shift) =
      relativeHallSignal gain drift sample magnet := by
  unfold relativeHallSignal
  ring

/-- The device's null method is compatible with relative carrier/magnet motion. -/
theorem c016_hall_null_at_relative_speed_cancel
    (gain drift magnet : ℝ) :
    relativeHallSignal gain drift (magnet - drift) magnet = 0 := by
  unfold relativeHallSignal
  ring

/-- Reversing the signed relative carrier velocity reverses the witness signal. -/
theorem c016_hall_signal_odd
    (gain relativeSpeed : ℝ) :
    gain * (-relativeSpeed) = -(gain * relativeSpeed) := by
  ring


/--
NIK-0008-C014: exact polar-angle surface-current integral after
u = cos(theta). With sigma = Q/(4 pi R²) and the rotating-shell
surface current K = sigma*(omega × r), the z-component of
(1/2) ∫ (r × K) dA reduces to:
(Q omega R²/4) ∫[-1,1] (1-u²) du.

This lemma computes the remaining 1D integral in Lean. The reduction
from the physical surface-current model to the polar integral remains
an explicit geometric premise, not an implicit Lean theorem.
-/
theorem c014_polar_integral_value :
    (∫ u in (-1 : ℝ)..1, (1 - u^2)) = (4 : ℝ) / 3 := by
  rw [intervalIntegral.integral_sub
    (intervalIntegral.intervalIntegrable_const (1 : ℝ))
    (intervalIntegral.intervalIntegrable_pow (2 : ℕ))]
  rw [intervalIntegral.integral_one, intervalIntegral.integral_pow]
  norm_num

noncomputable def shellMomentFromPolarIntegral (Q ω R : ℝ) : ℝ :=
  (Q * ω * R^2 / 4) * (∫ u in (-1 : ℝ)..1, (1 - u^2))

/-- Conditional derivation from exact polar current integral to shellMoment. -/
theorem c014_shell_moment_from_polar_integral (Q ω R : ℝ) :
    shellMomentFromPolarIntegral Q ω R = shellMoment Q ω R := by
  rw [shellMomentFromPolarIntegral, c014_polar_integral_value]
  unfold shellMoment
  ring

/-- The resulting capacitor moment requires no new shell-moment axiom. -/
theorem c014_capacitor_moment_from_integrals (Q ω a b : ℝ) :
    shellMomentFromPolarIntegral Q ω a +
      shellMomentFromPolarIntegral (-Q) ω b =
      (Q * ω / 3) * (a^2 - b^2) := by
  rw [c014_shell_moment_from_polar_integral, c014_shell_moment_from_polar_integral]
  exact c014_capacitor_moment_formula Q ω a b

end PVE.NIK0008
