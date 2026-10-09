import Physlib.Electromagnetism.Kinematics.GaugeTransformation

namespace PVE

/--
Neutral infrastructure smoke theorem.
It exists only to prove that the project can compile a theorem while importing
the pinned physics library. It is not a Nikolaev scientific claim.
-/
theorem verificationKernelSmoke (x : ℝ) : x + 0 = x := by
  simp

end PVE
