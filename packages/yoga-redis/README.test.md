# Redis Integration Tests

## Overview

Comprehensive integration tests for the `yoga-redis` package that test real Redis operations.

## Test Coverage

- **32 tests** covering:
  - Connection Management
  - String Operations (GET, SET, DEL, etc.)
  - Hash Operations (HSET, HGET, etc.)
  - List Operations (LPUSH, RPOP, etc.)
  - Set Operations (SADD, SREM, etc.)
  - TTL and Expiration
  - Sorted Set Operations
  - Pub/Sub Operations

## Running Tests

### Option 1: With Automatic Docker Management (Recommended)

```bash
cd packages/yoga-redis
bun run test:docker
```

This will:
1. Start Redis in Docker
2. Wait for it to be healthy
3. Run all tests
4. Stop Docker (even if tests fail)

### Option 2: Manual Docker Management

```bash
# Start Redis
docker compose -f docker-compose.test.yml up -d

# Run tests
bun run test

# Stop Redis
docker compose -f docker-compose.test.yml down
```

### Option 3: From Root Directory

```bash
# Run only Redis tests
bun run packages/yoga-redis/test-with-docker.ts

# Or run all tests
bun run test-all-with-docker.ts
```

## Requirements

- Docker Desktop installed and running
- Bun runtime

## Test Configuration

- **Redis Version:** 7-alpine
- **Test Port:** 6380
- **Connection:** localhost:6380

## Expected Results

All 32 tests should pass when Redis is available:

```
✅ 32/32 tests passed
```
