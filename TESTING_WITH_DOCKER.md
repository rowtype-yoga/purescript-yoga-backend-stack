# Testing with Docker

This guide explains how to run integration tests with automatic Docker management.

## Overview

The test suites now include Docker Compose files and test runners that automatically:
1. ✅ Start database services in Docker
2. ✅ Wait for services to be healthy
3. ✅ Run comprehensive integration tests
4. ✅ Clean up Docker services (even if tests fail)

## Quick Start

### Prerequisites

- **Docker Desktop** installed and running
- **Spago** (PureScript build tool)

### Run Tests

```bash
# From package directory - everything automatic!
cd packages/yoga-redis && spago test
cd packages/yoga-postgres && spago test
cd packages/yoga-scylladb && spago test

# Or from workspace root
bun run test:redis
bun run test:postgres
bun run test:scylladb
```

This will run all 88 integration tests across the three packages.

**Note:** Tests use the shared `yoga-test-docker` package for Docker management via FFI.

### Run Individual Package Tests

```bash
# Redis tests only (32 tests)
bun run test:redis:docker

# Postgres tests only (30 tests)
bun run test:postgres:docker

# ScyllaDB tests only (26 tests)
bun run test:scylladb:docker
```

## Per-Package Testing

Each package has its own self-contained test setup:

### yoga-redis

```bash
cd packages/yoga-redis
spago test

# Alternative: Use bash script
./test-with-docker.sh
```

**What it tests:**
- Connection management
- String, Hash, List, Set, Sorted Set operations
- TTL and expiration
- Pub/Sub
- Error handling

**Time:** ~5 seconds

### yoga-postgres

```bash
cd packages/yoga-postgres
bun run test:docker
```

**What it tests:**
- Connection management
- CRUD operations
- Parameterized queries (SQL injection prevention)
- Transactions (commit/rollback)
- Prepared statements
- Error handling

**Time:** ~10 seconds

### yoga-scylladb

```bash
cd packages/yoga-scylladb
bun run test:docker
```

**What it tests:**
- Connection management
- Keyspace and table operations
- Consistency levels
- Batch operations
- UUID operations
- Error handling

**Time:** ~60-90 seconds (ScyllaDB takes time to initialise)

## Test Architecture

Each package includes:

```
packages/yoga-{redis|postgres|scylladb}/
├── docker-compose.test.yml    # Docker service definition
├── test-with-docker.ts        # Test runner with Docker lifecycle
├── test/Main.purs             # Integration tests
└── README.test.md             # Package-specific test docs
```

### Docker Compose Files

Each package has an isolated `docker-compose.test.yml` that:
- Uses test-specific ports (6380, 5433, 9043)
- Includes health checks
- Configures test credentials
- Uses Alpine/lightweight images where possible

### Test Runners

The `test-with-docker.ts` scripts:
1. Start Docker Compose services
2. Poll for health status
3. Run Spago tests
4. Clean up Docker (in `finally` block)

## Manual Docker Management

If you prefer to manage Docker manually:

```bash
# Start services (from project root)
docker compose -f docker-compose.test.yml up -d

# Or start individual services
cd packages/yoga-redis
docker compose -f docker-compose.test.yml up -d

# Run tests without Docker management
bun run test

# Stop services
docker compose -f docker-compose.test.yml down
```

## Troubleshooting

### Tests fail to connect

**Symptom:** `ECONNREFUSED` errors

**Solutions:**
1. Ensure Docker Desktop is running
2. Check if ports are available: `lsof -i :6380,5433,9043`
3. Manually start services and check health:
   ```bash
   docker compose -f packages/yoga-redis/docker-compose.test.yml up
   ```

### ScyllaDB takes too long

**Symptom:** ScyllaDB health check timeout

**Solutions:**
1. ScyllaDB needs 30-60 seconds to initialise (this is normal)
2. Increase system resources allocated to Docker
3. First run downloads the image (may take longer)

### Port conflicts

**Symptom:** "port already in use"

**Solutions:**
1. Stop conflicting services: `docker ps` and `docker stop <container>`
2. Change test ports in `docker-compose.test.yml`
3. Update test configuration to match new ports

### Docker not found

**Symptom:** `command not found: docker`

**Solution:**
Install Docker Desktop from: https://www.docker.com/products/docker-desktop

## CI/CD Integration

The test setup is designed for CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      
      - name: Install dependencies
        run: bun install
      
      - name: Run all integration tests
        run: bun run test:all:docker
```

The tests automatically manage Docker lifecycle, so no additional service configuration is needed in CI.

## Test Coverage Summary

| Package | Tests | What's Tested | Time |
|---------|-------|---------------|------|
| **yoga-redis** | 32 | String, Hash, List, Set, Sorted Set, TTL, Pub/Sub | ~5s |
| **yoga-postgres** | 30 | CRUD, Transactions, Prepared Statements, Errors | ~10s |
| **yoga-scylladb** | 26 | Keyspace, Tables, Consistency, Batches, UUIDs | ~60-90s |
| **Total** | **88** | **Comprehensive integration testing** | **~2min** |

## Best Practices

1. **Use `:docker` scripts for integration tests** - They handle cleanup automatically
2. **Run tests before commits** - Catch issues early
3. **Check Docker resources** - Especially for ScyllaDB
4. **Use parallel execution cautiously** - Database tests may conflict
5. **Keep Docker images updated** - Periodically pull latest versions

## Additional Resources

- [Redis Test README](packages/yoga-redis/README.test.md)
- [Postgres Test README](packages/yoga-postgres/README.test.md)
- [ScyllaDB Test README](packages/yoga-scylladb/README.test.md)
- [Original Test Plan](TEST_UPGRADE_PLAN.md)
