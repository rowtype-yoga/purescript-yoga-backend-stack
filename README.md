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
bunx spago build

# Build a specific package
bunx spago build -p yoga-redis

# Run tests for a specific package
cd packages/yoga-redis && bunx spago test
```

## 🧪 Testing

Run tests for individual packages:

```bash
cd packages/yoga-redis && bunx spago test
cd packages/yoga-postgres && bunx spago test
cd packages/yoga-fastify-om && bunx spago test
```

Some packages with integration tests use Docker for test infrastructure (Redis, Postgres, ScyllaDB). The `yoga-test-docker` package provides utilities for managing Docker Compose services within tests.

## 📚 Documentation

Comprehensive documentation is available for key packages:
- **yoga-redis** / **yoga-redis-om** - Full API reference and examples
- **yoga-sql-types** - SQL type system documentation
- **yoga-test-docker** - Docker integration testing guide
- **yoga-postgres** / **yoga-postgres-om** - PostgreSQL usage
- **yoga-sqlite-om** - SQLite with Om

Additional documentation:
- `docs/ENDPOINT2_RECORD_API.md` - Tapir-style endpoint specification for Fastify
- `docs/FIELD_OMISSION.md` - Union constraint and field omission patterns

## 🏗️ Monorepo Structure

```
purescript-yoga-bindings/
├── packages/
│   ├── yoga-sql-types/          # Foundation package
│   ├── yoga-redis/              # Redis base package
│   │   ├── src/
│   │   ├── test/                # Package-specific tests
│   │   ├── spago.yaml
│   │   └── package.json
│   ├── yoga-redis-om/           # Redis with Om observability
│   ├── yoga-postgres/
│   ├── yoga-postgres-om/
│   ├── yoga-fastify-om/         # Fastify web framework with Om
│   └── ...                      # Additional packages
├── docs/                        # Documentation
├── spago.yaml                   # Workspace configuration
├── package.json                 # Root package.json
└── README.md
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
