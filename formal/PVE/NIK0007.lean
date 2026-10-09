import Physlib.Electromagnetism.Kinematics.GaugeTransformation

namespace PVE.NIK0007

/--
NIK-0007-C005: purely algebraic part of E = m*c^2.
If c is nonzero and E = m*c^2, then m = E/c^2.
This theorem says nothing about the physical meaning assigned to m.
-/
theorem c005_mass_from_energy
    (E m c : ℝ) (hc : c ≠ 0) (hE : E = m * c^2) :
    m = E / c^2 := by
  rw [hE]
  field_simp [hc]

/--
NIK-0007-C010: one wave that both transfers the audited quantity and has a
carrier is enough to refute the universal implication
"transfer -> no carrier".
-/
theorem c010_carrier_witness_refutes_universal_no_carrier
    {Wave : Type}
    (transfers hasCarrier : Wave → Prop)
    (w : Wave)
    (hTransfer : transfers w)
    (hCarrier : hasCarrier w) :
    ¬ (∀ x, transfers x → ¬ hasCarrier x) := by
  intro h
  exact (h w hTransfer) hCarrier

inductive AnalogyWave where
  | sound
  | electromagnetic

def analogyTransfers : AnalogyWave → Prop
  | .sound => True
  | .electromagnetic => True

def analogyHasCarrier : AnalogyWave → Prop
  | .sound => True
  | .electromagnetic => False

/--
NIK-0007-C011: the acoustic premises can be true while the target
electromagnetic carrier proposition is false. Therefore the acoustic analogy
alone does not logically entail an electromagnetic carrier.
-/
theorem c011_acoustic_analogy_does_not_entail_target_carrier :
    ¬ ((analogyTransfers .sound ∧
        analogyHasCarrier .sound ∧
        analogyTransfers .electromagnetic) →
       analogyHasCarrier .electromagnetic) := by
  intro h
  exact h ⟨trivial, trivial, trivial⟩

end PVE.NIK0007
