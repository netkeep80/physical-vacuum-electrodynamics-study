import Physlib.Electromagnetism.Kinematics.GaugeTransformation

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

end PVE.NIK0008
