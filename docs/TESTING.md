# Testing Documentation

## Overview

This document provides an overview of the testing infrastructure for the PureScript Yoga Bindings monorepo.

## Current Test Status

**Build Status:** ✅ All 24 packages compile successfully  
**Test Status:** ✅ 7/7 test suites passing (14 tests total)  
**Coverage Level:** ⚠️ Smoke tests only (type safety + basic instantiation)

### Passing Tests
- `yoga-redis` - 3 type safety tests
- `yoga-postgres` - 3 type safety tests  
- `yoga-scylladb` - 3 type safety tests
- `yoga-sqlite` - 1 integration test
- `yoga-fastify` - 1 instantiation test
- `yoga-pino` - 2 integration tests
- `yoga-jaeger` - 1 type safety test

## Running Tests

### All Tests (No Docker Required)
```bash
cd /Users/mark/Developer/purescript-yoga-bindings
bun run test-runner.ts
```

### Individual Package Tests
```bash
bunx spago test -p yoga-redis
bunx spago test -p yoga-postgres
bunx spago test -p yoga-scylladb
bunx spago test -p yoga-sqlite
bunx spago test -p yoga-fastify
bunx spago test -p yoga-pino
bunx spago test -p yoga-jaeger
```

### With Docker (Future - For Integration Tests)
```bash
# Start services
docker compose -f docker-compose.test.yml up -d

# Wait for health checks
sleep 10

# Run tests
bun run test-runner.ts

# Cleanup
docker compose -f docker-compose.test.yml down
```

## Test Infrastructure

### Test Runners
- **`test-runner.ts`** - TypeScript test orchestrator, runs all package tests sequentially
- **`test-with-docker.ts`** - Manages Docker lifecycle for integration tests (future use)

### Docker Services
- **Redis** - Port 6380 (test port)
- **PostgreSQL** - Port 5433 (test port)
- **ScyllaDB** - Port 9043 (test port)

All defined in `docker-compose.test.yml`

### Test Framework
- **purescript-spec** - BDD-style testing framework
- **Test structure:** Each package has `test/Main.purs`
- **Assertions:** `shouldEqual`, `shouldSatisfy` from purescript-spec-assertions

## Future Plans

See **[TEST_UPGRADE_PLAN.md](../TEST_UPGRADE_PLAN.md)** for comprehensive plan to upgrade from smoke tests to production-ready test suite.

### Planned Improvements
1. **Docker Integration Tests** - Real database operations
2. **Property-Based Testing** - QuickCheck for invariants
3. **Error Handling Tests** - Connection failures, timeouts, edge cases
4. **Performance Benchmarks** - Stress tests and baselines
5. **CI/CD Integration** - GitHub Actions with service containers

### Target Coverage (Per Phase 1 of upgrade plan)
- Redis: 15+ integration tests
- Postgres: 20+ integration tests
- ScyllaDB: 15+ integration tests
- SQLite: 10+ integration tests
- All: Comprehensive error handling

**Estimated Effort:** 40-60 hours for full implementation

## Contributing Tests

### Adding Tests to a Package

1. **Create/Edit test file:**
   ```bash
   # Edit packages/<package-name>/test/Main.purs
   ```

2. **Follow the pattern:**
   ```purescript
   module Test.<PackageName>.Main where
   
   import Prelude
   import Test.Spec (Spec, describe, it)
   import Test.Spec.Assertions (shouldEqual)
   
   spec :: Spec Unit
   spec = do
     describe "Feature Name" do
       it "does something" do
         result <- operation
         result `shouldEqual` expected
   ```

3. **Update spago.yaml:**
   ```yaml
   test:
     main: Test.<PackageName>.Main
     dependencies:
       - spec
   ```

4. **Run tests:**
   ```bash
   bunx spago test -p <package-name>
   ```

### Test Naming Convention
- Module: `Test.<PackageName>.Main`
- Example: `Test.Redis.Main`, `Test.Postgres.Main`
- Avoids duplicate `Test.Main` module conflicts

### Best Practices
- ✅ Use descriptive test names
- ✅ Test one thing per `it` block
- ✅ Setup/teardown in `before`/`after` hooks
- ✅ Use type signatures on test setup functions
- ✅ Clean up resources after tests
- ❌ Don't test implementation details
- ❌ Don't write flaky tests

## Documentation Files

- **[TEST_UPGRADE_PLAN.md](../TEST_UPGRADE_PLAN.md)** - Comprehensive upgrade plan (this is the main reference)
- **[TEST_SUCCESS.md](../TEST_SUCCESS.md)** - Current test status and migration success
- **[TESTS_COMPLETE.md](../TESTS_COMPLETE.md)** - Detailed migration journey and fixes

## Quick Reference

| Command | Description |
|---------|-------------|
| `bun run test-runner.ts` | Run all tests |
| `bunx spago test -p <pkg>` | Test specific package |
| `bunx spago build` | Build all packages |
| `docker compose -f docker-compose.test.yml up -d` | Start test services |
| `docker compose -f docker-compose.test.yml down` | Stop test services |

## Getting Help

1. Check test output for specific errors
2. Review `TEST_UPGRADE_PLAN.md` for implementation examples
3. Look at existing tests in `packages/*/test/Main.purs`
4. Verify Docker services are healthy: `docker compose ps`
