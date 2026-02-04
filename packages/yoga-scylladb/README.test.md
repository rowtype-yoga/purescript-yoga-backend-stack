# ScyllaDB Integration Tests

## Overview

Comprehensive integration tests for the `yoga-scylladb` package that test real ScyllaDB/Cassandra operations.

## Test Coverage

- **26 tests** covering:
  - Connection Management
  - Keyspace Operations (CREATE, DROP, USE)
  - Table Operations (CREATE, INSERT, SELECT, UPDATE, DELETE)
  - Consistency Levels (ONE, QUORUM, LOCAL_ONE)
  - Prepared Statements
  - Batch Operations
  - UUID Operations
  - Data Types
  - Error Handling

## Running Tests

### Option 1: With Automatic Docker Management (Recommended)

```bash
cd packages/yoga-scylladb
bun run test:docker
```

This will:
1. Start ScyllaDB in Docker (takes 30-60 seconds to initialise)
2. Wait for it to be healthy
3. Run all tests
4. Stop Docker (even if tests fail)

### Option 2: Manual Docker Management

```bash
# Start ScyllaDB
docker compose -f docker-compose.test.yml up -d

# Wait for ScyllaDB to be ready (30-60 seconds)
# Check with: docker compose -f docker-compose.test.yml ps

# Run tests
bun run test

# Stop ScyllaDB
docker compose -f docker-compose.test.yml down
```

### Option 3: From Root Directory

```bash
# Run only ScyllaDB tests
bun run packages/yoga-scylladb/test-with-docker.ts

# Or run all tests
bun run test-all-with-docker.ts
```

## Requirements

- Docker Desktop installed and running
- Bun runtime
- **Note:** ScyllaDB requires more system resources than Redis or Postgres

## Test Configuration

- **ScyllaDB Version:** 5.4
- **Test Port:** 9043
- **Datacenter:** datacenter1
- **Test Keyspace:** test_ks

## Expected Results

All 26 tests should pass when ScyllaDB is available:

```
✅ 26/26 tests passed
```

## Important Notes

- ScyllaDB takes 30-60 seconds to become ready
- The test runner automatically waits for health checks
- First run may take longer as Docker downloads the image
