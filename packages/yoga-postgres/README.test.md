# Postgres Integration Tests

## Overview

Comprehensive integration tests for the `yoga-postgres` package that test real PostgreSQL operations.

## Test Coverage

- **30 tests** covering:
  - Connection Management
  - Basic Queries (CREATE, INSERT, SELECT, UPDATE, DELETE)
  - Parameterized Queries (SQL injection prevention)
  - Transactions (COMMIT, ROLLBACK)
  - Data Types (NULL, boolean, integer, text)
  - Error Handling
  - Query Helpers (queryOne, queryOneSimple)
  - Prepared Statements

## Running Tests

### Option 1: With Automatic Docker Management (Recommended)

```bash
cd packages/yoga-postgres
bun run test:docker
```

This will:
1. Start Postgres in Docker
2. Wait for it to be healthy
3. Run all tests
4. Stop Docker (even if tests fail)

### Option 2: Manual Docker Management

```bash
# Start Postgres
docker compose -f docker-compose.test.yml up -d

# Run tests
bun run test

# Stop Postgres
docker compose -f docker-compose.test.yml down
```

### Option 3: From Root Directory

```bash
# Run only Postgres tests
bun run packages/yoga-postgres/test-with-docker.ts

# Or run all tests
bun run test-all-with-docker.ts
```

## Requirements

- Docker Desktop installed and running
- Bun runtime

## Test Configuration

- **Postgres Version:** 16-alpine
- **Test Port:** 5433
- **Database:** test_playground
- **Username:** postgres
- **Password:** postgres

## Expected Results

All 30 tests should pass when Postgres is available:

```
✅ 30/30 tests passed
```
