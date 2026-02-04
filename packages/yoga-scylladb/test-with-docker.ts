#!/usr/bin/env bun
import { $ } from "bun";
import { resolve } from "path";

const packageDir = resolve(import.meta.dir);
const composeFile = resolve(packageDir, "docker-compose.test.yml");

console.log("🐳 Starting ScyllaDB test service...");

try {
  // Start Docker Compose
  await $`docker compose -f ${composeFile} up -d`.quiet();

  console.log("⏳ Waiting for ScyllaDB to be ready (this may take 30-60 seconds)...");

  // ScyllaDB takes longer to start, so we wait longer
  let attempts = 0;
  const maxAttempts = 60;

  while (attempts < maxAttempts) {
    try {
      const result = await $`docker compose -f ${composeFile} ps --format json`.text();
      const services = result.trim().split('\n').map(line => JSON.parse(line));
      const scyllaService = services.find(s => s.Service === "scylla-test");

      if (scyllaService && scyllaService.Health === "healthy") {
        console.log("✅ ScyllaDB is ready!");
        break;
      }

      attempts++;
      if (attempts % 10 === 0) {
        console.log(`   Still waiting... (${attempts}s)`);
      }
      await Bun.sleep(1000);
    } catch (e) {
      attempts++;
      await Bun.sleep(1000);
    }
  }

  if (attempts >= maxAttempts) {
    console.error("❌ ScyllaDB failed to become healthy");
    process.exit(1);
  }

  // Run tests
  console.log("🧪 Running tests...\n");
  await $`bunx spago test -p yoga-scylladb`;

  console.log("\n✅ Tests completed successfully!");

} catch (error) {
  console.error("\n❌ Tests failed!");
  process.exit(1);
} finally {
  // Always stop Docker Compose
  console.log("\n🛑 Stopping ScyllaDB test service...");
  await $`docker compose -f ${composeFile} down`.quiet();
  console.log("✅ Cleanup complete");
}
