export {};

// NIK-0008 mathematical wave 1.

const EARTH_OMEGA = 7.2921159e-5;
const EARTH_RADIUS = 6_378_137;
const LIGHT_SPEED = 299_792_458;

function surfaceSpeed(omega: number, radius: number): number {
  return omega * radius;
}
function vcRatio(v: number, c: number): number {
  if (c === 0) throw new Error("C must be nonzero");
  return v / c;
}
function shellMoment(Q: number, omega: number, R: number): number {
  return Q * omega * R * R / 3;
}
function capacitorMoment(Q: number, omega: number, a: number, b: number): number {
  return shellMoment(Q, omega, a) + shellMoment(-Q, omega, b);
}
function assertNear(actual: number, expected: number, label: string, rtol = 1e-10, atol = 1e-12): void {
  const err = Math.abs(actual - expected);
  const lim = atol + rtol * Math.abs(expected);
  if (!Number.isFinite(actual) || err > lim) {
    throw new Error(`${label}: expected ${expected}, got ${actual}, err=${err}, lim=${lim}`);
  }
}

// C011 fixture.
const vEq = surfaceSpeed(EARTH_OMEGA, EARTH_RADIUS);
if (!(vEq > 465 && vEq < 466)) throw new Error(`unexpected fixture Earth speed: ${vEq}`);
if (!(Math.abs(vEq - 300) > 160)) throw new Error("300 m/s unexpectedly close to the literal fixture");

// C013 V/C.
const epsilon = vcRatio(vEq, LIGHT_SPEED);
if (!(epsilon > 1.5e-6 && epsilon < 1.6e-6)) throw new Error(`unexpected V/C: ${epsilon}`);
let zeroCRejected = false;
try { vcRatio(1, 0); } catch { zeroCRejected = true; }
if (!zeroCRejected) throw new Error("C=0 must be rejected");

// C014 independent midpoint integration of the rotating shell magnetic moment.
function shellMomentNumeric(Q: number, omega: number, R: number, nTheta = 20000): number {
  const sigma = Q / (4 * Math.PI * R * R);
  const dTheta = Math.PI / nTheta;
  let total = 0;
  for (let i = 0; i < nTheta; i += 1) {
    const theta = (i + 0.5) * dTheta;
    const integrand = sigma * omega * R * R * Math.sin(theta) ** 2;
    const dAThetaIntegratedOverPhi = R * R * Math.sin(theta) * dTheta * 2 * Math.PI;
    total += 0.5 * integrand * dAThetaIntegratedOverPhi;
  }
  return total;
}

for (const [Q, omega, R] of [[1,1,1],[3,4,2],[-2.5,0.7,1.3]] as const) {
  assertNear(shellMomentNumeric(Q, omega, R), shellMoment(Q, omega, R), "shell moment quadrature", 2e-8);
}

const Q = 3, omega = 4, a = 1, b = 2;
const totalMoment = capacitorMoment(Q, omega, a, b);
assertNear(totalMoment, (Q * omega / 3) * (a * a - b * b), "capacitor moment");
if (totalMoment === 0) throw new Error("nondegenerate rotating capacitor moment must be nonzero");
if (capacitorMoment(Q, 0, a, b) !== 0) throw new Error("zero rotation must give zero moment");
if (capacitorMoment(Q, omega, a, a) !== 0) throw new Error("equal radii must cancel the ideal shell moments");

console.log("NIK0008_C011_FIXTURE_SPEED=" + vEq);
console.log("NIK0008_C013_V_OVER_C=" + epsilon);
console.log("NIK0008_C014_CAPACITOR_MOMENT=" + totalMoment);

// C007: finite witness for non-unique model identification.
function uniquelyIdentifies(
  predictions: Map<string, Set<string>>,
  target: string,
  observation: string,
): boolean {
  const matching = [...predictions.entries()]
    .filter(([, observations]) => observations.has(observation))
    .map(([model]) => model);
  return matching.length === 1 && matching[0] === target;
}

const sagnacPredictions = new Map<string, Set<string>>([
  ["nikolaev_preferred_frame", new Set(["sagnac_shift"])],
  ["special_relativity", new Set(["sagnac_shift"])],
]);
if (uniquelyIdentifies(sagnacPredictions, "nikolaev_preferred_frame", "sagnac_shift")) {
  throw new Error("Sagnac observation was incorrectly treated as uniquely identifying one model");
}

// C012: published Michelson–Gale fringe values.
const mgObserved = 0.230;
const mgObservedError = 0.005;
const mgCalculated = 0.236;
const mgCalculatedError = 0.002;
const mgObsLo = mgObserved - mgObservedError;
const mgObsHi = mgObserved + mgObservedError;
const mgCalcLo = mgCalculated - mgCalculatedError;
const mgCalcHi = mgCalculated + mgCalculatedError;
if (!(mgObsLo > 0)) throw new Error("Michelson–Gale observed interval unexpectedly includes zero");
if (!(Math.max(mgObsLo, mgCalcLo) <= Math.min(mgObsHi, mgCalcHi))) {
  throw new Error("Michelson–Gale observed/calculated intervals unexpectedly do not overlap");
}
console.log("NIK0008_C007_NONUNIQUE_LOGIC=PASS");
console.log("NIK0008_C012_OBS_INTERVAL=" + mgObsLo + "," + mgObsHi);
console.log("NIK0008_C012_CALC_INTERVAL=" + mgCalcLo + "," + mgCalcHi);


// C016: conditional 1D kinematic witness for patent SU661656A1.
// It does NOT establish the physical validity of a privileged Earth frame.
function relativeHallSignal(
  gain: number, drift: number, sampleSpeed: number, magnetSpeed: number,
): number {
  return gain * (drift + sampleSpeed - magnetSpeed);
}

const hallCases = [
  [2, 0.3, 4, -1, 7],
  [-3, -0.4, 0.2, 1.5, -11],
  [0.75, 1e-5, -5e-4, 3e-4, 100],
  [0, 2, -4, 3, 8],
] as const;

for (const [gain, drift, sampleSpeed, magnetSpeed, shift] of hallCases) {
  const before = relativeHallSignal(gain, drift, sampleSpeed, magnetSpeed);
  const after = relativeHallSignal(gain, drift, sampleSpeed + shift, magnetSpeed + shift);
  assertNear(after, before, "Hall same-reference-frame shift", 1e-9);
  assertNear(relativeHallSignal(gain, drift, magnetSpeed - drift, magnetSpeed), 0,
    "Hall relative-speed cancellation", 1e-9);
  assertNear(gain * -drift, -(gain * drift), "Hall relative-speed reversal");
}
console.log("NIK0008_C016_HALL_RELATIVE_FRAME_WITNESS=PASS");


// C014: independent quadrature after u = cos(theta) verifies the
// explicit one-dimensional polar integral formalized in Lean.
function shellMomentPolarNumeric(Q: number, omega: number, R: number, n = 20000): number {
  const du = 2 / n;
  let integral = 0;
  for (let j = 0; j < n; ++j) {
    const u = -1 + (j + 0.5) * du;
    integral += (1 - u * u) * du;
  }
  return Q * omega * R * R * integral / 4;
}
for (const [q, w, radius] of [[1, 1, 1], [3, 4, 2], [-2.5, 0.7, 1.3]] as const) {
  assertNear(shellMomentPolarNumeric(q, w, radius), shellMoment(q, w, radius),
    "shell polar integral", 1e-8);
}
assertNear(shellMomentPolarNumeric(3, 4, 1) + shellMomentPolarNumeric(-3, 4, 2),
  capacitorMoment(3, 4, 1, 2), "capacitor polar integral", 1e-8);
console.log("NIK0008_C014_POLAR_INTEGRAL=PASS");


// C014 / independent Cartesian surface-current quadrature with the
// actual parameterization tangent-vector cross product as area Jacobian.
// Its 3D integrand is not replaced by the known 1D polar formula.
type Vec3 = readonly [number, number, number];
function cross3(a: Vec3, b: Vec3): Vec3 {
  return [a[1]*b[2]-a[2]*b[1],
          a[2]*b[0]-a[0]*b[2],
          a[0]*b[1]-a[1]*b[0]];
}
function norm3(a: Vec3): number {
  return Math.hypot(a[0], a[1], a[2]);
}
function shellMomentCartesianSurface(Q: number, omega: number, R: number,
                                      nU = 400, nPhi = 64): number {
  if (!(R > 0)) throw new Error("3D Cartesian shell radius must be positive");
  const sigma = Q / (4*Math.PI*R*R);
  const du = 2/nU, dphi = 2*Math.PI/nPhi;
  let m = 0, maxJacError = 0;
  for (let i = 0; i < nU; i++) {
    const u = -1 + (i+0.5)*du;
    const t = Math.sqrt(1-u*u);
    for (let j = 0; j < nPhi; j++) {
      const phi = (j+0.5)*dphi, c = Math.cos(phi), s = Math.sin(phi);
      const r: Vec3 = [R*t*c, R*t*s, R*u];
      const rotated = cross3([0,0,omega], r);
      const K: Vec3 = [sigma*rotated[0],sigma*rotated[1],sigma*rotated[2]];
      const drdu: Vec3 = [-R*u/t*c, -R*u/t*s, R];
      const drdphi: Vec3 = [-R*t*s, R*t*c, 0];
      const jacobian = norm3(cross3(drdu, drdphi));
      maxJacError = Math.max(maxJacError, Math.abs(jacobian-R*R));
      m += 0.5*cross3(r,K)[2]*jacobian*du*dphi;
    }
  }
  if (!(maxJacError < 1e-10*Math.max(1,R*R))) throw new Error("surface Jacobian regression");
  return m;
}
for (const [q,w,r] of [[1,1,1],[3,4,2],[-2.5,0.7,1.3]] as const) {
  assertNear(shellMomentCartesianSurface(q,w,r),shellMoment(q,w,r),
             "3D Cartesian shell moment",1e-5);
}
assertNear(shellMomentCartesianSurface(3,4,1)+shellMomentCartesianSurface(-3,4,2),
           capacitorMoment(3,4,1,2),"3D Cartesian capacitor moment",1e-5);
console.log("NIK0008_C014_3D_SURFACE_CROSS_PRODUCT=PASS");

console.log("NIK0008_TYPESCRIPT_PASS");
