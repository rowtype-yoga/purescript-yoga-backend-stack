# File Structure - Integration Tests

## Complete Test Infrastructure

```
purescript-yoga-bindings/
│
├── 📚 Documentation (Root Level)
│   ├── TESTING_WITH_DOCKER.md          # Main testing guide
│   ├── DOCKER_TEST_SETUP_COMPLETE.md   # Setup documentation
│   ├── CHANGES.md                       # Change log
│   └── README.md                        # Updated with Docker tests
│
├── 📚 Documentation (.github/)
│   ├── TESTING_QUICK_REF.md            # Quick reference card
│   ├── INTEGRATION_TESTS_SUMMARY.md    # Implementation summary
│   └── FILE_TREE.md                    # This file
│
├── 🎯 Master Test Runner
│   └── test-all-with-docker.ts         # Runs all 88 tests
│
├── ⚙️ Root Configuration
│   └── package.json                     # Updated with test:*:docker scripts
│
└── 📦 Test Packages
    │
    ├── packages/yoga-redis/
    │   ├── 🐳 docker-compose.test.yml   # Redis 7 Alpine on port 6380
    │   ├── 🚀 test-with-docker.ts       # Test runner with lifecycle
    │   ├── 📚 README.test.md            # Redis test documentation
    │   ├── ⚙️ package.json              # Added test:docker script
    │   ├── ⚙️ spago.yaml                # Added test dependencies
    │   └── 🧪 test/Main.purs            # 32 integration tests
    │
    ├── packages/yoga-postgres/
    │   ├── 🐳 docker-compose.test.yml   # Postgres 16 Alpine on port 5433
    │   ├── 🚀 test-with-docker.ts       # Test runner with lifecycle
    │   ├── 📚 README.test.md            # Postgres test documentation
    │   ├── ⚙️ package.json              # Added test:docker script
    │   ├── ⚙️ spago.yaml                # Added test dependencies
    │   └── 🧪 test/Main.purs            # 30 integration tests
    │
    └── packages/yoga-scylladb/
        ├── 🐳 docker-compose.test.yml   # ScyllaDB 5.4 on port 9043
        ├── 🚀 test-with-docker.ts       # Test runner with lifecycle
        ├── 📚 README.test.md            # ScyllaDB test documentation
        ├── ⚙️ package.json              # Added test:docker script
        ├── ⚙️ spago.yaml                # Added test dependencies
        └── 🧪 test/Main.purs            # 26 integration tests
```

## File Count Summary

### New Files: 20
- 🐳 Docker Compose: 3
- 🚀 Test Runners: 4
- 📚 Documentation: 8
- 🧪 Test Suites: 3 (completely rewritten)
- ⚙️ Config Updates: 7

### Lines of Code Added
- Test Code: ~1,100 lines (PureScript)
- Test Runners: ~200 lines (TypeScript)
- Documentation: ~1,500 lines (Markdown)
- Config: ~50 lines (JSON/YAML)
- **Total: ~2,850 lines**

## Key Files by Purpose

### For Running Tests
```
test-all-with-docker.ts                    # Run all tests
packages/*/test-with-docker.ts             # Run individual package
packages/*/docker-compose.test.yml         # Database services
```

### For Understanding Tests
```
TESTING_WITH_DOCKER.md                     # Start here
.github/TESTING_QUICK_REF.md              # Quick commands
packages/*/README.test.md                  # Package-specific docs
```

### For Implementation Details
```
DOCKER_TEST_SETUP_COMPLETE.md             # Setup details
.github/INTEGRATION_TESTS_SUMMARY.md      # What was built
CHANGES.md                                 # Change log
```

### For Test Code
```
packages/yoga-redis/test/Main.purs        # Redis tests
packages/yoga-postgres/test/Main.purs     # Postgres tests
packages/yoga-scylladb/test/Main.purs     # ScyllaDB tests
```

## Docker Configuration

### Ports
- Redis: 6380 (production uses 6379)
- Postgres: 5433 (production uses 5432)
- ScyllaDB: 9043 (production uses 9042)

### Images
- Redis: `redis:7-alpine` (~35 MB)
- Postgres: `postgres:16-alpine` (~220 MB)
- ScyllaDB: `scylladb/scylla:5.4` (~700 MB)

### Health Checks
All services include health checks for automatic readiness detection:
- Redis: `redis-cli ping`
- Postgres: `pg_isready`
- ScyllaDB: `cqlsh -e 'describe cluster'`

## Test Runner Features

Each `test-with-docker.ts` includes:
1. Docker Compose start
2. Health check polling (with timeout)
3. Spago test execution
4. Docker Compose cleanup (in finally block)
5. Clear progress messages
6. Error handling

## Package Scripts Added

### Root package.json
```json
{
  "test:all:docker": "bun run test-all-with-docker.ts",
  "test:redis:docker": "cd packages/yoga-redis && bun run test:docker",
  "test:postgres:docker": "cd packages/yoga-postgres && bun run test:docker",
  "test:scylladb:docker": "cd packages/yoga-scylladb && bun run test:docker"
}
```

### Package-level package.json
```json
{
  "test": "spago test",
  "test:docker": "bun run test-with-docker.ts"
}
```

## Documentation Structure

### Quick Start → Full Guide → Deep Dive

1. **Quick Start**
   - `.github/TESTING_QUICK_REF.md` (1 page)

2. **Full Guide**
   - `TESTING_WITH_DOCKER.md` (comprehensive)

3. **Deep Dive**
   - `DOCKER_TEST_SETUP_COMPLETE.md` (setup details)
   - `.github/INTEGRATION_TESTS_SUMMARY.md` (what was built)
   - `packages/*/README.test.md` (per-package specifics)

## Usage Patterns

### Development Workflow
```bash
# Quick test before commit
bun run test:redis:docker

# Full test suite
bun run test:all:docker
```

### CI/CD Integration
```yaml
- run: bun install
- run: bun run test:all:docker
```

### Package Development
```bash
cd packages/yoga-redis
bun run test:docker
```

## Dependencies

### Runtime
- Docker Desktop (for running databases)
- Bun (for test runners)
- Spago (for PureScript tests)

### Test Dependencies (added to spago.yaml)
- `spec` - Test framework
- `exceptions` - Error handling
- `console` - Logging
- Various type libraries

## Test Organization

Each test file follows this structure:
```purescript
-- Configuration (ports, hosts, credentials)
-- Helper functions (withDatabase, isLeft, etc.)
-- Test suites (describe/it blocks)
-- Main entry point
```

Categories tested:
- Connection Management
- Basic Operations
- Error Handling
- Edge Cases
- Data Types
- Advanced Features

## Maintenance

All test infrastructure is:
- ✅ Self-contained per package
- ✅ Isolated (no shared state)
- ✅ Documented
- ✅ Executable
- ✅ Version controlled
- ✅ CI/CD ready

To update:
1. Modify test code in `test/Main.purs`
2. Update docs in `README.test.md`
3. Adjust Docker config if needed in `docker-compose.test.yml`
4. Test runner usually doesn't need changes
