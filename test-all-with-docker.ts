#!/usr/bin/env bun
import { $ } from "bun";
import { resolve } from "path";

const packages = [
  { name: "yoga-redis", dir: "packages/yoga-redis" },
  { name: "yoga-postgres", dir: "packages/yoga-postgres" },
  { name: "yoga-scylladb", dir: "packages/yoga-scylladb" }
];

console.log("🧪 Running all integration tests with Docker\n");

let totalPassed = 0;
let totalFailed = 0;

for (const pkg of packages) {
  console.log(`\n${"=".repeat(60)}`);
  console.log(`📦 Testing: ${pkg.name}`);
  console.log("=".repeat(60));

  const pkgDir = resolve(import.meta.dir, pkg.dir);
  const testScript = resolve(pkgDir, "test-with-docker.ts");

  try {
    await $`bun run ${testScript}`;
    totalPassed++;
    console.log(`\n✅ ${pkg.name} tests passed`);
  } catch (error) {
    totalFailed++;
    console.error(`\n❌ ${pkg.name} tests failed`);
  }
}

console.log(`\n${"=".repeat(60)}`);
console.log("📊 Test Summary");
console.log("=".repeat(60));
console.log(`✅ Passed: ${totalPassed}/${packages.length}`);
console.log(`❌ Failed: ${totalFailed}/${packages.length}`);

if (totalFailed > 0) {
  console.log("\n❌ Some tests failed");
  process.exit(1);
} else {
  console.log("\n✅ All tests passed!");
  process.exit(0);
}
