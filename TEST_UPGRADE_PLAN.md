# Comprehensive Test Suite Upgrade Plan

## Current State
- ✅ 7/7 tests passing (smoke tests)
- ⚠️ Minimal coverage: type checking + basic instantiation
- ❌ No real database operations (except SQLite)
- ❌ No error handling tests
- ❌ No edge cases or property tests

## Goal
Transform smoke tests into production-ready comprehensive test suite with:
- Real integration tests with Docker services
- Error handling and edge cases
- Property-based tests
- Performance benchmarks (optional)
- >80% meaningful test coverage

---

## Phase 1: Docker-Based Integration Tests

### 1.1 Infrastructure Setup
**Priority: HIGH | Complexity: Medium | Time: 2-3 hours**

```bash
# Already have docker-compose.test.yml ✅
# Need to ensure it's working and add health checks
```

**Tasks:**
- [ ] Verify `docker-compose.test.yml` works correctly
- [ ] Add proper health checks for all services
- [ ] Create `test-with-docker.ts` that manages lifecycle
- [ ] Add Docker availability detection (skip if not available)
- [ ] Document Docker setup in README

**Files to modify:**
- `docker-compose.test.yml` - Add missing health checks
- `test-with-docker.ts` - Already exists, verify it works
- `README.md` - Add Docker test instructions

---

### 1.2 Redis Integration Tests
**Priority: HIGH | Complexity: Medium | Time: 2-3 hours**

**Current:** 3 type-safety tests (no real operations)

**Upgrade to:**
```purescript
describe "Connection Management" do
  it "connects to Redis successfully" \redis -> do
    pong <- Redis.ping redis
    pong `shouldEqual` "PONG"
  
  it "handles connection failures gracefully" do
    result <- try $ Redis.createRedis { host: RedisHost "invalid", port: RedisPort 9999 }
    result `shouldSatisfy` isLeft

describe "String Operations" do
  it "sets and gets values" \redis -> do
    Redis.set key value {} redis
    result <- Redis.get key redis
    result `shouldEqual` Just value
  
  it "returns Nothing for non-existent keys" \redis -> do
    result <- Redis.get (RedisKey "nonexistent") redis
    result `shouldEqual` Nothing
  
  it "deletes keys" \redis -> do
    Redis.set key value {} redis
    count <- Redis.del [key] redis
    count `shouldEqual` 1
    result <- Redis.get key redis
    result `shouldEqual` Nothing

describe "Hash Operations" do
  it "sets and gets hash fields" \redis -> do
    Redis.hset hashKey [(field: field1, value: value1)] redis
    result <- Redis.hget hashKey field1 redis
    result `shouldEqual` Just value1
  
  it "gets all hash fields" \redis -> do
    Redis.hset hashKey [(field: f1, value: v1), (field: f2, value: v2)] redis
    result <- Redis.hgetall hashKey redis
    length result `shouldEqual` 2

describe "List Operations" do
  it "pushes and pops from lists" \redis -> do
    len <- Redis.rpush key [value1, value2, value3] redis
    len `shouldEqual` 3
    popped <- Redis.lpop key redis
    popped `shouldEqual` Just value1

describe "Set Operations" do
  it "adds and checks members" \redis -> do
    count <- Redis.sadd key [member1, member2] redis
    count `shouldEqual` 2
    isMember <- Redis.sismember key member1 redis
    isMember `shouldEqual` true

describe "TTL and Expiration" do
  it "sets TTL on keys" \redis -> do
    Redis.setex key (TTLSeconds 5) value redis
    ttl <- Redis.ttl key redis
    ttl `shouldSatisfy` (\t -> t > 0 && t <= 5)
  
  it "expires keys after TTL" \redis -> do
    Redis.setex key (TTLSeconds 1) value redis
    delay (Milliseconds 1100.0)
    result <- Redis.get key redis
    result `shouldEqual` Nothing

describe "Transactions" do
  it "executes atomic transactions" \redis -> do
    Redis.multi redis
    Redis.set key1 value1 {} redis
    Redis.set key2 value2 {} redis
    results <- Redis.exec redis
    length results `shouldEqual` 2

describe "Pub/Sub" do
  it "publishes and receives messages" do
    -- Test pub/sub functionality
    -- Requires separate subscriber client
```

**Files:**
- `packages/yoga-redis/test/Main.purs` - Complete rewrite
- Add test utilities: `packages/yoga-redis/test/TestUtils.purs`

---

### 1.3 Postgres Integration Tests
**Priority: HIGH | Complexity: Medium | Time: 2-3 hours**

**Current:** 3 type-safety tests

**Upgrade to:**
```purescript
describe "Connection Management" do
  it "connects to Postgres successfully" \pg -> do
    healthy <- PG.ping pg
    healthy `shouldEqual` true
  
  it "handles connection failures" do
    result <- try $ PG.postgres { host: "invalid", port: 9999 }
    result `shouldSatisfy` isLeft

describe "Basic Queries" do
  it "creates and drops tables" \pg -> do
    PG.executeSimple (SQL "DROP TABLE IF EXISTS test") pg
    count <- PG.executeSimple (SQL "CREATE TABLE test (id SERIAL, name TEXT)") pg
    count `shouldEqual` 0
    PG.executeSimple (SQL "DROP TABLE test") pg
  
  it "inserts and queries data" \pg -> do
    setupTable pg
    PG.execute (SQL "INSERT INTO users (name, email) VALUES ($1, $2)")
      [toPGValue "Alice", toPGValue "alice@example.com"] pg
    result <- PG.querySimple (SQL "SELECT * FROM users") pg
    result.count `shouldEqual` 1

describe "Parameterized Queries" do
  it "prevents SQL injection" \pg -> do
    setupTable pg
    maliciousInput = "'; DROP TABLE users; --"
    PG.execute (SQL "INSERT INTO users (name) VALUES ($1)")
      [toPGValue maliciousInput] pg
    result <- PG.querySimple (SQL "SELECT * FROM users") pg
    result.count `shouldEqual` 1
  
  it "handles multiple parameters" \pg -> do
    PG.execute (SQL "INSERT INTO users (name, age, email) VALUES ($1, $2, $3)")
      [toPGValue "Bob", toPGValue 30, toPGValue "bob@example.com"] pg
    result <- PG.query (SQL "SELECT * FROM users WHERE age > $1") [toPGValue 25] pg
    result.count `shouldEqual` 1

describe "Transactions" do
  it "commits transactions successfully" \pg -> do
    setupTable pg
    PG.withTransaction pg do
      PG.execute (SQL "INSERT INTO users (name) VALUES ($1)") [toPGValue "Charlie"] pg
      PG.execute (SQL "INSERT INTO users (name) VALUES ($1)") [toPGValue "Diana"] pg
    result <- PG.querySimple (SQL "SELECT * FROM users") pg
    result.count `shouldEqual` 2
  
  it "rolls back on errors" \pg -> do
    setupTable pg
    result <- try $ PG.withTransaction pg do
      PG.execute (SQL "INSERT INTO users (name) VALUES ($1)") [toPGValue "Eve"] pg
      throwError (error "Intentional error")
      PG.execute (SQL "INSERT INTO users (name) VALUES ($1)") [toPGValue "Frank"] pg
    result `shouldSatisfy` isLeft
    count <- PG.querySimple (SQL "SELECT * FROM users") pg
    count.count `shouldEqual` 0

describe "Data Types" do
  it "handles various PureScript types" \pg -> do
    -- Test Int, String, Boolean, Maybe, Array, etc.
  
  it "handles NULL values" \pg -> do
    PG.execute (SQL "INSERT INTO users (name, email) VALUES ($1, $2)")
      [toPGValue "Grace", toPGValue Nothing] pg
    result <- PG.query (SQL "SELECT * FROM users WHERE email IS NULL") [] pg
    result.count `shouldEqual` 1

describe "Error Handling" do
  it "handles syntax errors" \pg -> do
    result <- try $ PG.executeSimple (SQL "INVALID SQL SYNTAX") pg
    result `shouldSatisfy` isLeft
  
  it "handles constraint violations" \pg -> do
    setupTableWithConstraints pg
    PG.execute (SQL "INSERT INTO users (email) VALUES ($1)")
      [toPGValue "unique@example.com"] pg
    result <- try $ PG.execute (SQL "INSERT INTO users (email) VALUES ($1)")
      [toPGValue "unique@example.com"] pg
    result `shouldSatisfy` isLeft
```

**Files:**
- `packages/yoga-postgres/test/Main.purs`
- `packages/yoga-postgres/test/TestUtils.purs` - Schema helpers

---

### 1.4 ScyllaDB Integration Tests
**Priority: MEDIUM | Complexity: High | Time: 3-4 hours**

**Current:** 3 type-safety tests

**Upgrade to:**
```purescript
describe "Keyspace Operations" do
  it "creates and drops keyspaces" \client -> do
    Scylla.execute (CQL "DROP KEYSPACE IF EXISTS test_ks") [] client
    Scylla.execute (CQL """
      CREATE KEYSPACE test_ks 
      WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}
    """) [] client
    Scylla.execute (CQL "DROP KEYSPACE test_ks") [] client

describe "Table Operations" do
  it "creates tables with various column types" \client -> do
    setupKeyspace client
    Scylla.execute (CQL """
      CREATE TABLE test_ks.users (
        id uuid PRIMARY KEY,
        name text,
        age int,
        email text,
        created_at timestamp
      )
    """) [] client
  
  it "inserts and queries data" \client -> do
    setupKeyspace client
    setupUsersTable client
    Scylla.execute 
      (CQL "INSERT INTO test_ks.users (id, name, age) VALUES (?, ?, ?)")
      [uuid, "Alice", 30] client
    result <- Scylla.execute 
      (CQL "SELECT * FROM test_ks.users WHERE id = ?")
      [uuid] client
    result.rowLength `shouldEqual` 1

describe "Consistency Levels" do
  it "executes with different consistency levels" \client -> do
    -- Test One, Quorum, All consistency levels
    result <- Scylla.executeWithOptions 
      (CQL "SELECT * FROM system.local") 
      []
      { consistency: Quorum }
      client
    result.rowLength `shouldSatisfy` (_ > 0)

describe "Prepared Statements" do
  it "prepares and executes statements" \client -> do
    setupKeyspace client
    setupUsersTable client
    prepared <- Scylla.prepare 
      (CQL "INSERT INTO test_ks.users (id, name) VALUES (?, ?)")
      client
    Scylla.executePrepared prepared [uuid, "Bob"] client

describe "Batches" do
  it "executes batch operations" \client -> do
    setupKeyspace client
    setupUsersTable client
    Scylla.batch client do
      Scylla.addToBatch (CQL "INSERT INTO test_ks.users (id, name) VALUES (?, ?)") [uuid1, "Charlie"]
      Scylla.addToBatch (CQL "INSERT INTO test_ks.users (id, name) VALUES (?, ?)") [uuid2, "Diana"]
    result <- Scylla.execute (CQL "SELECT * FROM test_ks.users") [] client
    result.rowLength `shouldEqual` 2

describe "Collections" do
  it "handles lists, sets, and maps" \client -> do
    -- Test CQL collection types
```

**Files:**
- `packages/yoga-scylladb/test/Main.purs`
- `packages/yoga-scylladb/test/TestUtils.purs`

---

## Phase 2: Property-Based Testing

### 2.1 Add QuickCheck Tests
**Priority: MEDIUM | Complexity: Medium | Time: 4-5 hours**

**Install:**
```bash
bun add -D purescript-quickcheck purescript-quickcheck-laws
```

**Example for Redis:**
```purescript
import Test.QuickCheck ((===))
import Test.QuickCheck.Arbitrary (arbitrary)
import Test.QuickCheck.Laws.Data as Laws

describe "Property-Based Tests" do
  it "set followed by get returns the value" \redis -> do
    quickCheck \(key :: String) (value :: String) -> do
      Redis.set (RedisKey key) (RedisValue value) {} redis
      result <- Redis.get (RedisKey key) redis
      pure $ result === Just (RedisValue value)
  
  it "delete makes key non-existent" \redis -> do
    quickCheck \(key :: String) -> do
      Redis.set (RedisKey key) (RedisValue "temp") {} redis
      Redis.del [RedisKey key] redis
      result <- Redis.get (RedisKey key) redis
      pure $ result === Nothing
  
  it "list operations maintain order" \redis -> do
    quickCheck \(values :: Array String) -> do
      let key = RedisKey "test-list"
      Redis.del [key] redis
      Redis.rpush key (map RedisValue values) redis
      result <- Redis.lrange key 0 (-1) redis
      pure $ result === map RedisValue values
```

**Apply to:**
- Redis (high value)
- Postgres (medium value - parameterized queries)
- SQLite (medium value)

---

## Phase 3: Error Handling & Edge Cases

### 3.1 Comprehensive Error Tests
**Priority: HIGH | Complexity: Low | Time: 2-3 hours**

```purescript
describe "Error Handling" do
  it "handles network timeouts" do
    -- Configure short timeout
    result <- try $ operationWithTimeout
    result `shouldSatisfy` isLeft
  
  it "handles connection pool exhaustion" do
    -- Create many connections
    -- Verify graceful handling
  
  it "handles malformed data" do
    -- Send invalid data types
    -- Verify proper error messages
  
  it "handles service unavailability" do
    -- Stop service mid-operation
    -- Verify error recovery
```

**Add to all packages:**
- Connection failures
- Timeout handling
- Invalid input
- Service unavailability
- Resource exhaustion

---

## Phase 4: Performance & Benchmarks

### 4.1 Basic Benchmarks (Optional)
**Priority: LOW | Complexity: Medium | Time: 3-4 hours**

```purescript
describe "Performance" do
  it "handles 1000 sequential operations" \redis -> do
    start <- now
    forM_ (1..1000) \i ->
      Redis.set (RedisKey $ "key" <> show i) (RedisValue "value") {} redis
    end <- now
    let duration = diff end start
    duration `shouldSatisfy` (\d -> d < Milliseconds 10000.0)
  
  it "handles concurrent operations" \redis -> do
    -- Test with parallel operations
    results <- parTraverse (\i -> Redis.set key value {} redis) (1..100)
    length results `shouldEqual` 100
```

---

## Phase 5: Test Infrastructure Improvements

### 5.1 Test Utilities & Helpers
**Priority: MEDIUM | Complexity: Low | Time: 2-3 hours**

**Create shared test utilities:**

```purescript
-- packages/test-utils/src/Test/Utils.purs
module Test.Utils where

-- Retry with backoff
retryWithBackoff :: forall m a. MonadAff m => Int -> m a -> m a
retryWithBackoff maxAttempts action = ...

-- Wait for condition
waitFor :: forall m. MonadAff m => m Boolean -> m Unit
waitFor condition = ...

-- Generate test data
randomString :: Int -> Effect String
randomUUID :: Effect String
randomInt :: Int -> Int -> Effect Int

-- Database cleanup
cleanupRedis :: Redis -> Aff Unit
cleanupPostgres :: Connection -> Aff Unit
cleanupScylla :: Client -> Aff Unit
```

### 5.2 Test Fixtures
**Priority: LOW | Complexity: Low | Time: 1-2 hours**

```purescript
-- packages/*/test/Fixtures.purs
module Test.Fixtures where

sampleUsers :: Array User
sampleUsers = 
  [ { id: 1, name: "Alice", email: "alice@example.com" }
  , { id: 2, name: "Bob", email: "bob@example.com" }
  ]

samplePosts :: Array Post
samplePosts = ...
```

---

## Phase 6: CI/CD Integration

### 6.1 GitHub Actions Workflow
**Priority: HIGH | Complexity: Low | Time: 1 hour**

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      redis:
        image: redis:7-alpine
        ports: [6380:6379]
      
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_PASSWORD: postgres
        ports: [5433:5432]
      
      scylla:
        image: scylladb/scylla:5.4
        ports: [9043:9042]
    
    steps:
      - uses: actions/checkout@v3
      - uses: oven-sh/setup-bun@v1
      
      - name: Install dependencies
        run: bun install
      
      - name: Build
        run: bunx spago build
      
      - name: Wait for services
        run: |
          sleep 10
          # Add health checks
      
      - name: Run tests
        run: bun run test-runner.ts
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

---

## Implementation Order (Recommended)

### Week 1: Core Integration Tests
1. ✅ Docker infrastructure (already done)
2. Redis integration tests (2-3 hours)
3. Postgres integration tests (2-3 hours)
4. SQLite improvements (1 hour)

### Week 2: Error Handling & Edge Cases
1. Error handling for Redis (2 hours)
2. Error handling for Postgres (2 hours)
3. Error handling for ScyllaDB (2 hours)
4. Shared test utilities (2 hours)

### Week 3: Advanced Features
1. ScyllaDB integration tests (3-4 hours)
2. Property-based tests for Redis (2 hours)
3. Property-based tests for Postgres (2 hours)
4. CI/CD setup (1 hour)

### Week 4: Polish & Documentation
1. Remaining property tests (3 hours)
2. Performance benchmarks (optional, 3 hours)
3. Test documentation (2 hours)
4. Coverage reports (1 hour)

---

## Success Metrics

### Target Coverage
- [ ] Redis: 15+ integration tests, 5+ property tests
- [ ] Postgres: 20+ integration tests, 5+ property tests
- [ ] ScyllaDB: 15+ integration tests
- [ ] SQLite: 10+ integration tests
- [ ] All: Comprehensive error handling
- [ ] All: CI/CD passing on every commit

### Quality Gates
- [ ] All tests pass with Docker services
- [ ] No flaky tests (>99% reliability)
- [ ] Tests run in <2 minutes total
- [ ] Clear test failure messages
- [ ] Documentation for running tests locally

---

## Risks & Mitigations

### Risk: Docker not available in CI
**Mitigation:** Use GitHub Actions services (already supported)

### Risk: Tests too slow
**Mitigation:** 
- Run tests in parallel where possible
- Use test database cleanup instead of recreation
- Cache Docker images

### Risk: Flaky tests
**Mitigation:**
- Add retry logic with backoff
- Proper health checks before tests
- Clear state between tests

### Risk: Complex test maintenance
**Mitigation:**
- Shared test utilities
- Clear documentation
- Test helpers and fixtures

---

## Quick Start (Do This First)

```bash
# 1. Verify Docker setup
cd /Users/mark/Developer/purescript-yoga-bindings
docker compose -f docker-compose.test.yml up -d
docker compose -f docker-compose.test.yml ps  # All healthy?

# 2. Pick ONE package to upgrade first (recommend Redis)
# 3. Follow Phase 1.2 above
# 4. Iterate until comfortable
# 5. Apply pattern to other packages
```

**Estimated total effort:** 40-60 hours for comprehensive coverage
**Minimum viable improvement:** 8-12 hours (just Phase 1 Redis + Postgres)
