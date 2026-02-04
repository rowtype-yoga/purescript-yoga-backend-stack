# PureScript Yoga Bindings

High-quality, type-safe PureScript FFI bindings for databases, messaging, HTTP frameworks, and observability tools.

## 📦 Packages

### Foundation
- **yoga-sql-types** - Common SQL types and utilities for type-safe queries

### Databases (15 packages)
- **yoga-redis** / **yoga-redis-om** - Redis client with Om observability
- **yoga-postgres** / **yoga-postgres-om** - PostgreSQL client with Om observability  
- **yoga-scylladb** / **yoga-scylladb-om** - ScyllaDB client with Om observability
- **yoga-sqlite** / **yoga-sqlite-om** - SQLite bindings with Om observability
- **yoga-bun-sqlite** - Bun's native SQLite bindings
- **yoga-node-sqlite** - Node SQLite bindings
- **yoga-dynamodb** - AWS DynamoDB client
- **yoga-elasticsearch** - Elasticsearch client

### Messaging
- **yoga-kafka** - Apache Kafka client (Producer, Consumer, Admin)

### HTTP Frameworks (4 packages)
- **yoga-fastify** / **yoga-fastify-om** - Fastify web framework with Om observability
- **yoga-bun-yoga** / **yoga-bun-yoga-om** - Bun HTTP server with Yoga integration and Om observability

### Observability (6 packages)
- **yoga-opentelemetry** / **yoga-opentelemetry-om** - OpenTelemetry SDK with Om observability
- **yoga-jaeger** - Jaeger distributed tracing
- **yoga-pino** / **yoga-pino-om** - Pino logger with Om observability

### Utilities
- **yoga-docker-compose** - Docker Compose integration for tests and development

## 🚀 Quick Start

```bash
# Install dependencies
bun install

# Build all packages
bun run build

# Run all integration tests with automatic Docker management
bun run test:all:docker

# Or run individual package tests
bun run test:redis:docker      # Redis tests only
bun run test:postgres:docker   # Postgres tests only
bun run test:scylladb:docker   # ScyllaDB tests only

# Build a specific package
bunx spago build -p yoga-redis
```

## 🧪 Testing

### Simple as `spago test` 🎉

Integration tests automatically manage Docker - no manual setup needed!

```bash
# Just run spago test - it handles everything!
cd packages/yoga-redis && spago test       # 32 tests, ~5s
cd packages/yoga-postgres && spago test    # 30 tests, ~10s
cd packages/yoga-scylladb && spago test    # 26 tests, ~60-90s

# Or from root directory
bun run test:redis        # spago test -p yoga-redis
bun run test:postgres     # spago test -p yoga-postgres
bun run test:scylladb     # spago test -p yoga-scylladb
```

**What happens automatically:**
1. ✅ Starts database services in Docker (via FFI)
2. ✅ Waits for services to be healthy
3. ✅ Runs comprehensive integration tests
4. ✅ Cleans up Docker containers (even if tests fail)

### How It Works

Tests import the shared `yoga-test-docker` package and use `bracket` for guaranteed cleanup:

```purescript
import Yoga.Test.Docker as Docker

bracket
  (Docker.startService "docker-compose.test.yml" 30)  -- Acquire
  (\_ -> Docker.stopService "docker-compose.test.yml") -- Release (always!)
  (\_ -> runSpec spec)                                 -- Use
```

**Benefits:**
- 🎯 Zero manual Docker commands
- 🛡️ Guaranteed cleanup (even on test failure/Ctrl+C)
- ♻️ Shared Docker utilities (DRY - no duplication)
- 📦 Each package just imports `yoga-test-docker`
- 🚀 Just `spago test` and go!

**📚 Full Testing Guide:** See [TESTING_WITH_DOCKER.md](TESTING_WITH_DOCKER.md) for complete documentation and troubleshooting.

## 📚 Documentation

Each package includes its own README with:
- Installation instructions
- API documentation
- Usage examples
- FFI patterns and best practices

See individual package READMEs in `packages/<package-name>/README.md`

## 🏗️ Monorepo Structure

```
purescript-yoga-bindings/
├── packages/
│   ├── yoga-sql-types/          # Foundation package
│   ├── yoga-redis/              # Redis base package
│   │   ├── src/
│   │   ├── test/                # Package-specific tests
│   │   ├── spago.yaml
│   │   ├── package.json
│   │   └── README.md
│   ├── yoga-redis-om/           # Redis with Om observability
│   ├── yoga-postgres/
│   ├── yoga-postgres-om/
│   └── ...                      # 24 packages total
├── docker-compose.test.yml      # Test infrastructure
├── spago.yaml                   # Workspace configuration
├── package.json                 # Root package.json
├── test-all.sh                  # Test runner
└── test-with-docker.sh          # Test runner with Docker lifecycle
```

## 🔧 Development

### Adding a New Package

1. Create package directory in `packages/`
2. Add `spago.yaml`, `package.json`, and `README.md`
3. Implement FFI bindings following the pattern in existing packages
4. Add test suite in `test/Main.purs`
5. Update root scripts if needed

### Module Naming Convention

All modules use the `Yoga.*` namespace:
- `Yoga.Redis` - Base Redis module
- `Yoga.Postgres.TypedQuery` - PostgreSQL typed queries
- `Yoga.Bun.HTTP` - Bun HTTP server
- etc.

### Om Packages

Packages with `-om` suffix provide Observable Monitoring integration:
- Automatically instrument database queries
- Add tracing and metrics
- Integrate with OpenTelemetry
- Provide layer-based composition

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please ensure:
- All new bindings follow the FFI patterns from existing packages
- Tests are included for new functionality
- Documentation is updated
- Code passes linting (`bunx spago build`)

## ⚙️ Requirements

- **PureScript** 0.15.15+
- **Spago** 0.93.45+ (Spago Next)
- **Bun** (recommended) or Node.js 18+
- **Docker** (for integration tests)

## 🔗 Related Projects

- [purescript-yoga-om](https://github.com/rowtype-yoga/purescript-yoga-om) - Observable Monitoring effect system
- [purescript-yoga-json](https://github.com/rowtype-yoga/purescript-yoga-json) - High-performance JSON codecs
