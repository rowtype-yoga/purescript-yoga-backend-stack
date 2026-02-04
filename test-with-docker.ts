#!/usr/bin/env bun
import { $ } from "bun";

async function waitForHealthy(maxWaitSeconds = 60) {
  console.log("⏳ Waiting for services to be healthy...");

  const startTime = Date.now();
  const maxWaitMs = maxWaitSeconds * 1000;

  while (Date.now() - startTime < maxWaitMs) {
    try {
      const result =
        await $`docker compose -f docker-compose.test.yml ps --format json`.text();
      const services = result
        .trim()
        .split("\n")
        .filter((line) => line)
        .map((line) => JSON.parse(line));

      const allHealthy = services.every(
        (s) => s.Health === "healthy" || s.Health === ""
      );
      const anyUnhealthy = services.some((s) => s.Health === "unhealthy");

      if (anyUnhealthy) {
        throw new Error("Some services are unhealthy");
      }

      if (allHealthy) {
        console.log("✅ All services are healthy!");
        return;
      }
    } catch (error) {
      // Ignore and retry
    }

    await Bun.sleep(2000);
  }

  throw new Error("Services failed to become healthy within timeout");
}

async function main() {
  console.log("🐳 Starting test infrastructure with Docker...\n");

  try {
    // Start services
    await $`docker compose -f docker-compose.test.yml up -d`;

    // Wait for health
    await waitForHealthy();

    console.log("\n🧪 Running tests...\n");

    // Run tests
    await $`bun run test-runner.ts`;

    console.log("\n✅ All tests completed successfully!");
  } catch (error) {
    console.error("\n❌ Tests failed:", error);

    // Show logs on failure
    console.log("\n📋 Docker logs:");
    await $`docker compose -f docker-compose.test.yml logs --tail=50`;

    process.exit(1);
  } finally {
    console.log("\n🧹 Cleaning up Docker services...");
    await $`docker compose -f docker-compose.test.yml down`;
  }
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
