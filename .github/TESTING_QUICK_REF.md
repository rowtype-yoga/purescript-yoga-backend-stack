# Testing Quick Reference

## 🚀 One-Line Commands

```bash
# Run all integration tests (88 tests)
bun run test:all:docker

# Run specific package tests
bun run test:redis:docker      # 32 tests, ~5s
bun run test:postgres:docker   # 30 tests, ~10s
bun run test:scylladb:docker   # 26 tests, ~60-90s
```

## 📋 Prerequisites

- Docker Desktop installed and running
- Bun runtime (already installed ✅)

## 🎯 What Gets Tested

### Redis (32 tests)
- Strings, Hashes, Lists, Sets, Sorted Sets
- TTL/Expiration, Pub/Sub
- Connection & error handling

### Postgres (30 tests)
- CRUD operations, Transactions
- Parameterized queries, Prepared statements
- SQL injection prevention, Error handling

### ScyllaDB (26 tests)
- Keyspaces, Tables, Consistency levels
- Batch operations, UUIDs
- CQL operations, Error handling

## 🔧 Manual Control

```bash
# Start service only
cd packages/yoga-redis
docker compose -f docker-compose.test.yml up -d

# Run tests
bun run test

# Stop service
docker compose -f docker-compose.test.yml down
```

## 📚 Full Documentation

See [TESTING_WITH_DOCKER.md](../TESTING_WITH_DOCKER.md)
