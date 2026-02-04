#!/usr/bin/env bun
import { $ } from "bun";
import { join } from "path";

const PACKAGES_WITH_TESTS = [
  "yoga-redis",        // Requires Docker (Redis on port 6380)
  "yoga-postgres",     // Requires Docker (Postgres on port 5433)
  "yoga-scylladb",     // Requires Docker (ScyllaDB on port 9043)
  "yoga-sqlite",       // No Docker needed ✅
  "yoga-fastify",      // No Docker needed ✅
  "yoga-pino",         // No Docker needed ✅
  "yoga-jaeger",       // No Docker needed ✅
  // "yoga-opentelemetry",  // FFI issues with @opentelemetry/resources
  // "yoga-bun-sqlite",  // Requires Bun runtime (not Node.js)
  // "yoga-node-sqlite",  // Requires better-sqlite3 native module
];

interface TestResult {
  package: string;
  passed: boolean;
  duration: number;
  error?: string;
}

async function testPackage(pkg: string): Promise<TestResult> {
  const start = Date.now();
  const workspaceRoot = import.meta.dir;

  console.log(`\n${"━".repeat(60)}`);
  console.log(`📦 Testing ${pkg}...`);
  console.log("━".repeat(60));

  try {
    // Run from workspace root to resolve Om packages correctly
    await $`cd ${workspaceRoot} && bunx spago test -p ${pkg}`;
    const duration = Date.now() - start;
    console.log(`✅ ${pkg} tests passed (${duration}ms)`);
    return { package: pkg, passed: true, duration };
  } catch (error) {
    const duration = Date.now() - start;
    console.error(`❌ ${pkg} tests failed (${duration}ms)`);
    console.error(`Error output available above ↑`);
    return {
      package: pkg,
      passed: false,
      duration,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

async function runAllTests() {
  console.log("🧪 Running yoga-bindings integration tests...\n");

  const results: TestResult[] = [];

  for (const pkg of PACKAGES_WITH_TESTS) {
    const result = await testPackage(pkg);
    results.push(result);
  }

  // Print summary
  console.log(`\n${"━".repeat(60)}`);
  console.log("📊 Test Summary");
  console.log("━".repeat(60));

  const passed = results.filter((r) => r.passed);
  const failed = results.filter((r) => !r.passed);

  console.log(`✅ Passed: ${passed.length}`);
  console.log(`❌ Failed: ${failed.length}`);

  if (failed.length > 0) {
    console.log("\nFailed packages:");
    failed.forEach((r) => console.log(`  - ${r.package}`));
    process.exit(1);
  }

  console.log("\n✅ All tests passed!");
}

runAllTests().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
