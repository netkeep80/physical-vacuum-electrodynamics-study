type Vec3 = readonly [number, number, number];

function dot(a: Vec3, b: Vec3): number {
  return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

function cross(a: Vec3, b: Vec3): Vec3 {
  return [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];
}

function add(a: Vec3, b: Vec3): Vec3 {
  return [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
}

function assertNear(actual: number, expected: number, label: string, tolerance = 1e-12): void {
  if (!Number.isFinite(actual) || Math.abs(actual - expected) > tolerance) {
    throw new Error(`${label}: expected ${expected}, got ${actual}`);
  }
}

function assertVecNear(actual: Vec3, expected: Vec3, label: string, tolerance = 1e-12): void {
  for (let i = 0; i < 3; i += 1) {
    assertNear(actual[i], expected[i], `${label}[${i}]`, tolerance);
  }
}

const a: Vec3 = [1, 2, 3];
const b: Vec3 = [4, -5, 6];

assertNear(dot(a, b), 12, "dot product");
assertVecNear(cross(a, b), [27, 6, -13], "cross product");
assertVecNear(add(cross(a, b), cross(b, a)), [0, 0, 0], "cross antisymmetry");
assertNear(dot(a, cross(a, b)), 0, "cross orthogonal to left operand");
assertNear(dot(b, cross(a, b)), 0, "cross orthogonal to right operand");

console.log("TS_NUMERIC_SMOKE_PASS");
