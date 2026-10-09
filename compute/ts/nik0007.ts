export {};

// NIK-0007-C005
// Numerical regression/property checks for the purely algebraic relation
// E = m*c^2 <-> m = E/c^2 for c != 0.
// No physical interpretation of m is asserted here.

type Dim3 = readonly [number, number, number];

function energyFromMass(m: number, c: number): number {
  return m * c * c;
}

function massFromEnergy(E: number, c: number): number {
  if (c === 0) {
    throw new Error("c must be nonzero");
  }
  return E / (c * c);
}

function assertNear(actual: number, expected: number, label: string, rtol = 1e-12, atol = 0): void {
  const error = Math.abs(actual - expected);
  const limit = atol + rtol * Math.abs(expected);
  if (!Number.isFinite(actual) || error > limit) {
    throw new Error(`${label}: expected ${expected}, got ${actual}, error=${error}, limit=${limit}`);
  }
}

const masses = [0, 1e-30, 1, -2.5, 3.7e12];
const speeds = [1, 2, 299_792_458];

for (const m of masses) {
  for (const c of speeds) {
    const E = energyFromMass(m, c);
    assertNear(massFromEnergy(E, c), m, `round-trip m=${m}, c=${c}`, 1e-12, 1e-30);
  }
}

let zeroRejected = false;
try {
  massFromEnergy(1, 0);
} catch {
  zeroRejected = true;
}
if (!zeroRejected) {
  throw new Error("c=0 must be rejected because division by c^2 is undefined");
}

const energyDim: Dim3 = [1, 2, -2];
const velocityDim: Dim3 = [0, 1, -1];
const quotientDim: Dim3 = [
  energyDim[0] - 2 * velocityDim[0],
  energyDim[1] - 2 * velocityDim[1],
  energyDim[2] - 2 * velocityDim[2],
];
if (quotientDim[0] !== 1 || quotientDim[1] !== 0 || quotientDim[2] !== 0) {
  throw new Error(`E/c^2 dimension mismatch: ${quotientDim.join(",")}`);
}

const c0 = 299_792_458;
assertNear(massFromEnergy(1, c0), 1.1126500560536185e-17, "one joule mass-equivalent", 1e-15);

console.log("NIK0007_C005_TYPESCRIPT_PASS");
