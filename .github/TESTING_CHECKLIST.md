# Testing Checklist

Use this checklist when implementing test improvements from TEST_UPGRADE_PLAN.md

## Phase 1: Docker Integration Tests

### Redis (yoga-redis)
- [ ] Connection management tests
- [ ] String operations (get/set/del)
- [ ] Hash operations (hset/hget/hgetall)
- [ ] List operations (lpush/rpush/lpop/rpop)
- [ ] Set operations (sadd/sismember/smembers)
- [ ] TTL and expiration tests
- [ ] Transaction tests (multi/exec)
- [ ] Pub/Sub tests
- [ ] Error handling

### Postgres (yoga-postgres)
- [ ] Connection management tests
- [ ] Basic CRUD operations
- [ ] Parameterized queries
- [ ] SQL injection prevention test
- [ ] Transaction tests (commit/rollback)
- [ ] NULL handling
- [ ] Various data types
- [ ] Constraint violation handling
- [ ] Error handling

### ScyllaDB (yoga-scylladb)
- [ ] Keyspace operations
- [ ] Table creation with various types
- [ ] Insert and query operations
- [ ] Consistency level tests
- [ ] Prepared statements
- [ ] Batch operations
- [ ] Collection types (list/set/map)
- [ ] Error handling

### SQLite (yoga-sqlite)
- [ ] Expand current basic test
- [ ] Transaction tests
- [ ] Complex queries
- [ ] Error handling

## Phase 2: Property-Based Testing

### Redis
- [ ] set/get roundtrip property
- [ ] delete removes key property
- [ ] list order preservation
- [ ] set uniqueness property

### Postgres
- [ ] Insert/select roundtrip
- [ ] Transaction atomicity
- [ ] Parameter binding correctness

### SQLite
- [ ] Insert/select roundtrip
- [ ] Transaction rollback

## Phase 3: Error Handling

### All Packages
- [ ] Connection timeout handling
- [ ] Invalid host/port handling
- [ ] Malformed data handling
- [ ] Service unavailability
- [ ] Resource exhaustion

## Phase 4: Performance (Optional)

### All Packages
- [ ] Sequential operation benchmarks
- [ ] Concurrent operation tests
- [ ] Load tests

## Phase 5: Infrastructure

- [ ] Shared test utilities module
- [ ] Test fixtures
- [ ] Retry helpers
- [ ] Cleanup helpers

## Phase 6: CI/CD

- [ ] GitHub Actions workflow
- [ ] Service containers in CI
- [ ] Coverage reporting
- [ ] Test reliability (no flaky tests)

## Completion Criteria

- [ ] All checklist items completed
- [ ] Tests pass reliably (>99%)
- [ ] Documentation updated
- [ ] CI/CD integrated
- [ ] Coverage >80% for tested packages
