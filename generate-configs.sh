#!/usr/bin/env bash
set -e

BASE="/Users/mark/Developer/purescript-yoga-bindings/packages"

# Function to create spago.yaml for base packages
create_base_spago() {
  local pkg=$1
  local deps=$2
  cat > "$BASE/$pkg/spago.yaml" <<EOF
package:
  name: $pkg
  publish:
    version: 0.1.0
    license: MIT
    location:
      githubOwner: rowtype-yoga
      githubRepo: purescript-yoga-bindings
      subdir: packages/$pkg
  dependencies:
    - aff: ">=7.0.0 <8.0.0"
    - effect: ">=4.0.0 <5.0.0"
    - prelude: ">=6.0.0 <7.0.0"
$deps
EOF
}

# Function to create spago.yaml for Om packages
create_om_spago() {
  local pkg=$1
  local base_pkg=$2
  cat > "$BASE/$pkg/spago.yaml" <<EOF
package:
  name: $pkg
  publish:
    version: 0.1.0
    license: MIT
    location:
      githubOwner: rowtype-yoga
      githubRepo: purescript-yoga-bindings
      subdir: packages/$pkg
  dependencies:
    - $base_pkg: "*"
    - yoga-om-core: ">=1.0.0 <2.0.0"
    - yoga-om-layer: ">=1.0.0 <2.0.0"
    - aff: ">=7.0.0 <8.0.0"
    - effect: ">=4.0.0 <5.0.0"
    - prelude: ">=6.0.0 <7.0.0"
EOF
}

# Function to create package.json
create_package_json() {
  local pkg=$1
  local desc=$2
  cat > "$BASE/$pkg/package.json" <<EOF
{
  "name": "purescript-$pkg",
  "version": "0.1.0",
  "description": "$desc",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/rowtype-yoga/purescript-yoga-bindings.git",
    "directory": "packages/$pkg"
  },
  "keywords": ["purescript", "ffi", "bindings", "yoga"]
}
EOF
}

# Function to create README
create_readme() {
  local pkg=$1
  local title=$2
  cat > "$BASE/$pkg/README.md" <<EOF
# $pkg

$title

## Installation

\`\`\`bash
spago install $pkg
\`\`\`

## License

MIT
EOF
}

# ScyllaDB
create_base_spago "yoga-scylladb" "    - yoga-sql-types: \"*\"
    - arrays: \">=7.0.0 <8.0.0\"
    - foreign-object: \">=4.0.0 <5.0.0\"
    - nullable: \">=6.0.0 <7.0.0\""
create_om_spago "yoga-scylladb-om" "yoga-scylladb"
create_package_json "yoga-scylladb" "PureScript FFI bindings for ScyllaDB/Cassandra"
create_package_json "yoga-scylladb-om" "Om-wrapped ScyllaDB operations"
create_readme "yoga-scylladb" "ScyllaDB/Cassandra bindings with typed query support"
create_readme "yoga-scylladb-om" "Om-wrapped ScyllaDB operations"

# SQLite
for variant in "yoga-sqlite" "yoga-bun-sqlite" "yoga-node-sqlite"; do
  create_base_spago "$variant" "    - yoga-sql-types: \"*\"
    - arrays: \">=7.0.0 <8.0.0\"
    - foreign: \">=7.0.0 <8.0.0\""
  create_package_json "$variant" "PureScript FFI bindings for SQLite"
  create_readme "$variant" "SQLite bindings with typed query support"
done

# DynamoDB & Elasticsearch
create_base_spago "yoga-dynamodb" "    - foreign-object: \">=4.0.0 <5.0.0\""
create_base_spago "yoga-elasticsearch" "    - foreign-object: \">=4.0.0 <5.0.0\""
create_package_json "yoga-dynamodb" "PureScript FFI bindings for AWS DynamoDB"
create_package_json "yoga-elasticsearch" "PureScript FFI bindings for Elasticsearch"
create_readme "yoga-dynamodb" "AWS DynamoDB client bindings"
create_readme "yoga-elasticsearch" "Elasticsearch client bindings"

# Kafka
create_base_spago "yoga-kafka" "    - arrays: \">=7.0.0 <8.0.0\"
    - foreign-object: \">=4.0.0 <5.0.0\""
create_package_json "yoga-kafka" "PureScript FFI bindings for Apache Kafka"
create_readme "yoga-kafka" "Apache Kafka producer, consumer, and admin bindings"

# Fastify
create_base_spago "yoga-fastify" "    - foreign-object: \">=4.0.0 <5.0.0\""
create_om_spago "yoga-fastify-om" "yoga-fastify"
create_package_json "yoga-fastify" "PureScript FFI bindings for Fastify"
create_package_json "yoga-fastify-om" "Om-wrapped Fastify operations"
create_readme "yoga-fastify" "Fastify web framework bindings"
create_readme "yoga-fastify-om" "Om-wrapped Fastify operations"

# Bun Yoga
create_base_spago "yoga-bun-yoga" "    - yoga-json: \">=5.0.0 <6.0.0\""
create_om_spago "yoga-bun-yoga-om" "yoga-bun-yoga"
create_package_json "yoga-bun-yoga" "PureScript FFI bindings for Bun HTTP with GraphQL Yoga"
create_package_json "yoga-bun-yoga-om" "Om-wrapped Bun Yoga operations"
create_readme "yoga-bun-yoga" "Bun HTTP server with GraphQL Yoga support"
create_readme "yoga-bun-yoga-om" "Om-wrapped Bun Yoga operations"

# OpenTelemetry
create_base_spago "yoga-opentelemetry" "    - datetime: \">=6.0.0 <7.0.0\"
    - foreign-object: \">=4.0.0 <5.0.0\""
create_om_spago "yoga-opentelemetry-om" "yoga-opentelemetry"
create_package_json "yoga-opentelemetry" "PureScript FFI bindings for OpenTelemetry"
create_package_json "yoga-opentelemetry-om" "Om-wrapped OpenTelemetry operations"
create_readme "yoga-opentelemetry" "OpenTelemetry SDK, traces, and logs"
create_readme "yoga-opentelemetry-om" "Om-wrapped OpenTelemetry operations"

# Jaeger & Pino
create_base_spago "yoga-jaeger" "    - foreign-object: \">=4.0.0 <5.0.0\""
create_base_spago "yoga-pino" "    - foreign-object: \">=4.0.0 <5.0.0\""
create_om_spago "yoga-pino-om" "yoga-pino"
create_package_json "yoga-jaeger" "PureScript FFI bindings for Jaeger tracing"
create_package_json "yoga-pino" "PureScript FFI bindings for Pino logger"
create_package_json "yoga-pino-om" "Om-wrapped Pino logger operations"
create_readme "yoga-jaeger" "Jaeger tracing client bindings"
create_readme "yoga-pino" "Pino logger bindings"
create_readme "yoga-pino-om" "Om-wrapped Pino logger operations"

# DockerCompose
create_base_spago "yoga-docker-compose" "    - node-child-process: \">=9.0.0 <10.0.0\""
create_package_json "yoga-docker-compose" "PureScript utilities for Docker Compose"
create_readme "yoga-docker-compose" "Docker Compose utilities for testing"

echo "All configuration files created!"
