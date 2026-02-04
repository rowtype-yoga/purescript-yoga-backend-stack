#!/usr/bin/env bun
import { $ } from "bun";
import { resolve } from "path";

const packageDir = resolve(import.meta.dir);
const composeFile = resolve(packageDir, "docker-compose.test.yml");

console.log("🐳 Starting Redis test service...");

try {
  // Start Docker Compose
  await $`docker compose -f ${composeFile} up -d`.quiet();

  console.log("⏳ Waiting for Redis to be ready...");

  // Wait for service to be healthy
  let attempts = 0;
  const maxAttempts = 30;

  while (attempts < maxAttempts) {
    try {
      const result = await $`docker compose -f ${composeFile} ps --format json`.text();
      const services = result.trim().split('\n').map(line => JSON.parse(line));
      const redisService = services.find(s => s.Service === "redis-test");

      if (redisService && redisService.Health === "healthy") {
        console.log("✅ Redis is ready!");
        break;
      }

      attempts++;
      await Bun.sleep(1000);
    } catch (e) {
      attempts++;
      await Bun.sleep(1000);
    }
  }

  if (attempts >= maxAttempts) {
    console.error("❌ Redis failed to become healthy");
    process.exit(1);
  }

  // Run tests
  console.log("🧪 Running tests...\n");
  await $`bunx spago test -p yoga-redis`;

  console.log("\n✅ Tests completed successfully!");

} catch (error) {
  console.error("\n❌ Tests failed!");
  process.exit(1);
} finally {
  // Always stop Docker Compose
  console.log("\n🛑 Stopping Redis test service...");
  await $`docker compose -f ${composeFile} down`.quiet();
  console.log("✅ Cleanup complete");
}
