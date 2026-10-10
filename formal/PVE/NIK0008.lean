import Physlib.Electromagnetism.Kinematics.GaugeTransformation
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.Geometry.Euclidean.Volume.Measure
import Mathlib.Analysis.Normed.Module.Ball.Pointwise
import Mathlib.MeasureTheory.Integral.Bochner.Basic

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
    (intervalIntegrable_const)
    (intervalIntegral.intervalIntegrable_pow (2 : ℕ))]
  rw [integral_one, integral_pow]
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


/--
C014 / geometrical step toward the 3D surface-current integral.

For a rigid rotation about z, K = sigma (omega × r) has Cartesian
components Kx = -sigma*omega*y, Ky = sigma*omega*x.
The z-component of the magnetic dipole integrand is
(1/2)(r × K)_z = (x*Ky-y*Kx)/2.
-/
noncomputable def c014_cartesianMomentDensity
    (sigma omega x y : ℝ) : ℝ :=
  (x * (sigma * omega * x) - y * (-sigma * omega * y)) / 2

theorem c014_cartesianMomentDensity_eq
    (sigma omega x y : ℝ) :
    c014_cartesianMomentDensity sigma omega x y =
      (sigma * omega / 2) * (x^2 + y^2) := by
  unfold c014_cartesianMomentDensity
  ring

/--
A sphere point represented by x=R*t*c, y=R*t*s, z=R*u.
The hypotheses c²+s²=1 and t²+u²=1 explicitly encode the geometry;
they do NOT assert a surface area measure or Jacobian.
-/
theorem c014_sphere_parameter_radius
    (R t c s u : ℝ)
    (hc : c^2 + s^2 = 1)
    (htu : t^2 + u^2 = 1) :
    (R*t*c)^2 + (R*t*s)^2 + (R*u)^2 = R^2 := by
  calc
    (R*t*c)^2 + (R*t*s)^2 + (R*u)^2 =
        R^2 * (t^2*(c^2+s^2) + u^2) := by ring
    _ = R^2 * (t^2 + u^2) := by rw [hc]; ring
    _ = R^2 := by rw [htu]; ring

/--
The full 3D Cartesian current density reduces to the exact polar
integrand at every sphere point, independently of azimuth. This removes
the prior assumption about the form of the magnetic dipole integrand,
but does not prove the surface measure/Jacobian transformation.
-/
theorem c014_cartesian_density_to_polar
    (sigma omega R t c s u : ℝ)
    (hc : c^2 + s^2 = 1)
    (htu : t^2 + u^2 = 1) :
    c014_cartesianMomentDensity sigma omega (R*t*c) (R*t*s) =
      (sigma * omega * R^2 / 2) * (1 - u^2) := by
  calc
    c014_cartesianMomentDensity sigma omega (R*t*c) (R*t*s) =
        (sigma * omega / 2) * ((R*t*c)^2 + (R*t*s)^2) := by
          exact c014_cartesianMomentDensity_eq sigma omega (R*t*c) (R*t*s)
    _ = (sigma * omega * R^2 / 2) * (t^2 * (c^2+s^2)) := by ring
    _ = (sigma * omega * R^2 / 2) * t^2 := by rw [hc]; ring
    _ = (sigma * omega * R^2 / 2) * (1 - u^2) := by
      have ht : t^2 = 1 - u^2 := by linarith
      rw [ht]


/--
For r(u,phi)=(R*t*c,R*t*s,R*u), where t=sqrt(1-u²),
c=cos(phi), s=sin(phi), put h=1/t on the open polar patch t>0.
The tangent vectors are
  dr/du=(-R*u*h*c,-R*u*h*s,R),
  dr/dphi=(-R*t*s,R*t*c,0).
Their three cross-product components are established algebraically below.
The derivative identities are explicit premises here.
-/
theorem c014_sphere_tangent_cross_components
    (R t c s u h : ℝ)
    (hc : c^2 + s^2 = 1) (hinv : h*t = 1) :
    ((-R*u*h*s)*0 - R*(R*t*c) = -R^2*t*c) ∧
    (R*(-R*t*s) - (-R*u*h*c)*0 = -R^2*t*s) ∧
    ((-R*u*h*c)*(R*t*c) - (-R*u*h*s)*(-R*t*s) = -R^2*u) := by
  constructor
  · ring
  constructor
  · ring
  calc
    (-R*u*h*c)*(R*t*c) - (-R*u*h*s)*(-R*t*s) =
        -R^2*u*(h*t)*(c^2+s^2) := by ring
    _ = -R^2*u := by rw [hc, hinv]; ring

/--
Exact squared surface Jacobian for the normalized spherical patch:
|dr/du × dr/dphi|² = R⁴, at every nonsingular parameter point.
This closes the algebraic geometry step but does not by itself formalize
the measure-theoretic surface change-of-variables theorem.
-/
theorem c014_spherical_area_jacobian_squared
    (R t c s u : ℝ)
    (hc : c^2 + s^2 = 1) (htu : t^2 + u^2 = 1) :
    (-R^2*t*c)^2 + (-R^2*t*s)^2 + (-R^2*u)^2 =
      (R^2)^2 := by
  calc
    (-R^2*t*c)^2 + (-R^2*t*s)^2 + (-R^2*u)^2 =
        R^4*(t^2*(c^2+s^2) + u^2) := by ring
    _ = R^4*(t^2 + u^2) := by rw [hc]; ring
    _ = (R^2)^2 := by rw [htu]; ring

/--
Pointwise density times the (geometrically established) spherical
surface Jacobian R²; φ disappears because the charge is homogeneous.
-/
theorem c014_cartesian_surface_density_to_u
    (sigma omega R t c s u : ℝ)
    (hc : c^2 + s^2 = 1) (htu : t^2 + u^2 = 1) :
    c014_cartesianMomentDensity sigma omega (R*t*c) (R*t*s) * R^2 =
      (sigma*omega*R^4/2)*(1-u^2) := by
  rw [c014_cartesian_density_to_polar sigma omega R t c s u hc htu]
  ring


/--
C014 / pole-cap control. For 0 ≤ eps ≤ 1, the excluded north and south
polar caps are u ∈ [1-eps,1] and u ∈ [-1,-1+eps]. This computes their
exact contribution to the already established POLAR integral. It does
not identify the intrinsic sphere surface measure with its chart measure.
-/
noncomputable def c014_polarCapIntegral (eps : ℝ) : ℝ :=
  (∫ u in (-1 : ℝ)..(-1 + eps), (1 - u^2)) +
  (∫ u in (1 - eps)..(1 : ℝ), (1 - u^2))

theorem c014_polarCapIntegral_exact (eps : ℝ) :
    c014_polarCapIntegral eps = 2 * eps^2 - (2 / 3 : ℝ) * eps^3 := by
  have hsouth :
      (∫ u in (-1 : ℝ)..(-1 + eps), (1 - u^2)) =
        eps^2 - eps^3 / 3 := by
    rw [intervalIntegral.integral_sub
      (intervalIntegrable_const)
      (intervalIntegral.intervalIntegrable_pow (2 : ℕ))]
    rw [integral_one, integral_pow]
    ring
  have hnorth :
      (∫ u in (1 - eps)..(1 : ℝ), (1 - u^2)) =
        eps^2 - eps^3 / 3 := by
    rw [intervalIntegral.integral_sub
      (intervalIntegrable_const)
      (intervalIntegral.intervalIntegrable_pow (2 : ℕ))]
    rw [integral_one, integral_pow]
    ring
  unfold c014_polarCapIntegral
  rw [hsouth, hnorth]
  ring

/-- Pole caps occupy the exact fraction (3/2)eps²-(1/2)eps³ of the
    normalized full polar magnetic-moment integral 4/3. -/
theorem c014_polarCapFraction_exact (eps : ℝ) :
    (3 / 4 : ℝ) * c014_polarCapIntegral eps =
      (3 / 2 : ℝ) * eps^2 - (1 / 2 : ℝ) * eps^3 := by
  rw [c014_polarCapIntegral_exact]
  ring


/--
C014 / symmetry-based reduction for any independently constructed spherical
surface measure. Here Ix,Iy,Iz denote SECOND MOMENT INTEGRALS of coordinates
against that measure, not free-standing pointwise coordinates.

The hypotheses Ix=Iy, Iy=Iz must eventually follow from proved
measure-preserving axis permutations; the moment sum must follow from the
sphere equation and a finite, integrable intrinsic surface measure.

This lemma closes only the algebraic step. It does not establish any of
those measure-theoretic premises.
-/
theorem c014_isotropic_second_moment
    (Ix Iy Iz area R : ℝ)
    (hxy : Ix = Iy)
    (hyz : Iy = Iz)
    (hsum : Ix + Iy + Iz = R^2 * area) :
    Ix + Iy = (2 / 3 : ℝ) * R^2 * area := by
  nlinarith [hxy, hyz, hsum]

/--
If the true surface measure has area area, if its second moments satisfy
isotropy and the sphere constraint, and if Q=σ*area is the total shell
charge, then the CARTESIAN dipole current integral reduces to Q ω R²/3.
No chart Jacobian, intrinsic-measure normalization, or symmetry property
is silently assumed by this theorem.
-/
theorem c014_intrinsic_moment_from_isotropy
    (sigma omega Q R area Ix Iy Iz : ℝ)
    (hcharge : Q = sigma * area)
    (hxy : Ix = Iy)
    (hyz : Iy = Iz)
    (hsum : Ix + Iy + Iz = R^2 * area) :
    (sigma * omega / 2) * (Ix + Iy) = Q * omega * R^2 / 3 := by
  rw [c014_isotropic_second_moment Ix Iy Iz area R hxy hyz hsum]
  rw [hcharge]
  ring

/--
Two-shell consequence, still conditional on separately obtained shell
moments for both signed charge layers. This is an algebraic superposition
check, not an independent field-equation or coordinate-frame proof.
-/
theorem c014_two_shells_from_intrinsic_moments
    (Q omega a b inner outer : ℝ)
    (hinner : inner = Q * omega * a^2 / 3)
    (houter : outer = (-Q) * omega * b^2 / 3) :
    inner + outer = (Q * omega / 3) * (a^2 - b^2) := by
  rw [hinner, houter]
  ring


/--
C014 / independent geometric normalization of the *unit* Euclidean
sphere measure from ambient 3D volume (Haar radial disintegration).
Unlike the prior polar-chart approach, the measure is not introduced
as the pushforward of the desired u/phi surface integral.
-/
theorem c014_unit_sphere_measure_ambient_volume :
    ((MeasureTheory.volume :
        MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).toSphere) Set.univ =
      (3 : ENNReal) * MeasureTheory.volume
        (Metric.ball (0 : EuclideanSpace ℝ (Fin 3)) 1) := by
  simp [MeasureTheory.Measure.toSphere_apply_univ, finrank_euclideanSpace]

/--
Normalization of the unit Euclidean sphere measure in real units.
The volume of the unit ball (4 pi / 3) is the mathematical input
of the *ambient* three-dimensional measure, not an assumed surface
area formula. Does not prove metric-sphere invariance or R-scaling.
-/
theorem c014_unit_sphere_measure_area :
    ((MeasureTheory.volume :
        MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).toSphere).real
      Set.univ = 4 * Real.pi := by
  rw [MeasureTheory.Measure.toSphere_real_apply_univ]
  simp [MeasureTheory.measureReal_def, EuclideanSpace.volume_ball_fin_three,
    finrank_euclideanSpace]
  rw [ENNReal.toReal_ofReal (by positivity : 0 ≤ Real.pi * 4 / 3)]
  ring

open scoped MeasureTheory Pointwise


set_option maxHeartbeats 1000000

/--
C014 / radius scaling of the independently defined Euclidean Hausdorff
two-dimensional surface measure in the actual Euclidean ℓ² ambient space.

Unlike the existing Haar-derived *unit-sphere* mass theorem, this lemma
starts with the standard 2D Euclidean Hausdorff measure μHE[2]. It proves
the geometric R² scaling for R>0, without assuming the unit-sphere mass
or identifying μHE[2] with the Haar-induced measure.

The remaining bridge μHE[2](S₁)=4π and invariance of the coordinate
second moments remain explicit open obligations of issue #76.
-/
theorem c014_euclidean_hausdorff_sphere_radius_scale
    (R : ℝ) (hR : 0 < R) :
    (μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3)))
      (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R) =
      ‖R‖₊ ^ 2 •
        (μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3)))
          (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1) := by
  have hRne : R ≠ 0 := ne_of_gt hR
  have hSphere :
      R • Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1 =
        Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R := by
    simpa only [smul_zero, mul_one, Real.norm_eq_abs, abs_of_pos hR] using
      (_root_.smul_sphere' hRne
        (0 : EuclideanSpace ℝ (Fin 3)) (1 : ℝ))
  rw [← hSphere]
  exact MeasureTheory.Measure.euclideanHausdorffMeasure_smul₀ 2 hRne _


/--
For C014, a permutation of the three Cartesian coordinate axes is
realized by a *genuine Euclidean linear isometry*. The ambient space
is explicitly EuclideanSpace ℝ (Fin 3), with its ℓ² norm. The proof
does not substitute the sup-norm on ordinary functions Fin 3 → ℝ.
-/
noncomputable def c014_cartesian_axis_permutation (e : Fin 3 ≃ Fin 3) :
    EuclideanSpace ℝ (Fin 3) ≃ₗᵢ[ℝ] EuclideanSpace ℝ (Fin 3) :=
  LinearIsometryEquiv.piLpCongrLeft 2 ℝ ℝ e

/--
The standard *2D Euclidean Hausdorff measure* in ambient 3D Euclidean
space is invariant under each Cartesian axis permutation. This is a
measure-theoretic theorem, not a property inferred from numerical tests.
-/
theorem c014_axis_permutation_preserves_hausdorff_measure
    (e : Fin 3 ≃ Fin 3) :
    MeasureTheory.MeasurePreserving (c014_cartesian_axis_permutation e)
      (μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3)))
      (μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))) := by
  exact (c014_cartesian_axis_permutation e).toIsometryEquiv
    |>.measurePreserving_euclideanHausdorffMeasure 2

/--
Any permutation of coordinate axes maps the actual geometric sphere
of arbitrary radius R to itself; negative/zero R are allowed here.
-/
theorem c014_axis_permutation_preserves_sphere
    (e : Fin 3 ≃ Fin 3) (R : ℝ) :
    c014_cartesian_axis_permutation e ''
      Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R =
      Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R := by
  rw [(c014_cartesian_axis_permutation e).image_sphere]
  simp


/--
For C014, the standard Euclidean 2-dimensional Hausdorff measure,
*restricted to the geometric sphere*, is preserved by any Cartesian
coordinate permutation. The result combines actual ambient measure
invariance, the exact sphere-preimage theorem, and the genuine
restriction/pushforward measure identity; no surface-normalization
factor is assumed.
-/
theorem c014_axis_permutation_preserves_restricted_sphere_measure
    (e : Fin 3 ≃ Fin 3) (R : ℝ) :
    MeasureTheory.MeasurePreserving (c014_cartesian_axis_permutation e)
      ((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))
      ((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R)) := by
  let iso := c014_cartesian_axis_permutation e
  let μ : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3)) := μHE[2]
  let s : Set (EuclideanSpace ℝ (Fin 3)) :=
    Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R
  have hs : MeasurableSet s := Metric.isClosed_sphere.measurableSet
  have hpre : iso ⁻¹' s = s := by
    dsimp [s]
    rw [iso.preimage_sphere]
    simp
  have hbase : μ.map iso = μ :=
    (c014_axis_permutation_preserves_hausdorff_measure e).map_eq
  refine ⟨iso.continuous.measurable, ?_⟩
  change (μ.restrict s).map iso = μ.restrict s
  calc
    (μ.restrict s).map iso = (μ.map iso).restrict s := by
      rw [MeasureTheory.Measure.restrict_map iso.continuous.measurable hs]
      rw [hpre]
    _ = μ.restrict s := by rw [hbase]


/--
The surface integral of any real-valued function is invariant under
an axis permutation. This is a **true measure-theoretic change of
variables**, not an algebraic second-moment assumption. It relies on
the proved invariance of the *sphere-restricted* Hausdorff measure.
-/
theorem c014_spherical_integral_axis_permutation
    (e : Fin 3 ≃ Fin 3) (R : ℝ)
    (f : EuclideanSpace ℝ (Fin 3) → ℝ) :
    (∫ x, f (c014_cartesian_axis_permutation e x)
      ∂((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))) =
    (∫ x, f x
      ∂((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))) := by
  exact (c014_axis_permutation_preserves_restricted_sphere_measure e R).integral_comp
    (c014_cartesian_axis_permutation e).toHomeomorph.measurableEmbedding f

/--
An axis permutation acts on Euclidean-space coordinates by inverse
permutation. This uses the ℓ² Euclidean PiLp, not an unnormed function.
-/
theorem c014_axis_permutation_coordinate
    (e : Fin 3 ≃ Fin 3)
    (x : EuclideanSpace ℝ (Fin 3)) (j : Fin 3) :
    (c014_cartesian_axis_permutation e x) j = x (e.symm j) := by
  rfl

/--
The x², y², z² surface moments of the same *standard* Euclidean
Hausdorff-restricted sphere measure are pairwise equal for arbitrary
radius R. This is an unconditional equality of Lean's Bochner integrals;
finiteness of the mass and explicit unit-sphere normalization remain
separate mathematical obligations. The statement does not assume
Ix=Iy=Iz as hypotheses.
-/
theorem c014_spherical_second_moments_equal
    (R : ℝ) (i j : Fin 3) :
    (∫ x : EuclideanSpace ℝ (Fin 3), (x i)^2
      ∂((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))) =
    (∫ x : EuclideanSpace ℝ (Fin 3), (x j)^2
      ∂((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))) := by
  let e : Fin 3 ≃ Fin 3 := Equiv.swap i j
  have hcoord (x : EuclideanSpace ℝ (Fin 3)) :
      (c014_cartesian_axis_permutation e x) j = x i := by
    rw [c014_axis_permutation_coordinate]
    simp [e]
  calc
    (∫ x : EuclideanSpace ℝ (Fin 3), (x i)^2
      ∂((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))) =
    (∫ x : EuclideanSpace ℝ (Fin 3),
      ((c014_cartesian_axis_permutation e x) j)^2
      ∂((μHE[2] : MeasureTheory.Measure (EuclideanSpace ℝ (Fin 3))).restrict
        (Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) R))) := by
      congr 1
      funext x
      rw [hcoord x]
    _ = _ := c014_spherical_integral_axis_permutation e R (fun x => (x j)^2)

end PVE.NIK0008
