#!/usr/bin/env bash
set -e

BASE_SRC="/Users/mark/Developer/om-playground/src"
BASE_TARGET="/Users/mark/Developer/purescript-yoga-bindings/packages"

# Function to copy and update module declarations
copy_and_update() {
  local src_module=$1
  local target_package=$2
  local module_namespace=$3
  
  echo "Creating $target_package..."
  mkdir -p "$BASE_TARGET/$target_package/src/$module_namespace"
  
  # Copy all .purs and .js files
  if [ -d "$BASE_SRC/$src_module" ]; then
    find "$BASE_SRC/$src_module" -name "*.purs" -o -name "*.js" | while read file; do
      filename=$(basename "$file")
      subdir=$(dirname "$file" | sed "s|$BASE_SRC/$src_module||" | sed 's|^/||')
      
      target_dir="$BASE_TARGET/$target_package/src/$module_namespace/$subdir"
      mkdir -p "$target_dir"
      cp "$file" "$target_dir/"
    done
    
    # Update module declarations
    find "$BASE_TARGET/$target_package/src" -name "*.purs" | while read file; do
      # Replace module declarations
      sed -i '' "s|module $src_module\\.|module $module_namespace.|g" "$file"
      sed -i '' "s|module $src_module |module $module_namespace |g" "$file"
      sed -i '' "s|import $src_module\\.|import $module_namespace.|g" "$file"
      sed -i '' "s|import $src_module |import $module_namespace |g" "$file"
      # Update SQL imports
      sed -i '' "s|import SQL\\.|import Yoga.SQL.|g" "$file"
      sed -i '' "s|module SQL\\.|module Yoga.SQL.|g" "$file"
    done
  fi
}

# ScyllaDB
copy_and_update "ScyllaDB" "yoga-scylladb" "Yoga/ScyllaDB"
copy_and_update "ScyllaDB" "yoga-scylladb-om" "Yoga/ScyllaDB"

# SQLite variants
copy_and_update "SQLite" "yoga-sqlite" "Yoga/SQLite"
copy_and_update "BunSQLite" "yoga-bun-sqlite" "Yoga/BunSQLite"
copy_and_update "NodeSQLite" "yoga-node-sqlite" "Yoga/NodeSQLite"

# Other databases
copy_and_update "DynamoDB" "yoga-dynamodb" "Yoga/DynamoDB"
copy_and_update "Elasticsearch" "yoga-elasticsearch" "Yoga/Elasticsearch"

# Messaging
copy_and_update "Kafka" "yoga-kafka" "Yoga/Kafka"

# HTTP
copy_and_update "Fastify" "yoga-fastify" "Yoga/Fastify"
copy_and_update "Fastify" "yoga-fastify-om" "Yoga/Fastify"
copy_and_update "Bun/HTTP" "yoga-bun-yoga" "Yoga/Bun/HTTP"
copy_and_update "Bun/HTTP" "yoga-bun-yoga-om" "Yoga/Bun/HTTP"

# Observability
copy_and_update "OpenTelemetry" "yoga-opentelemetry" "Yoga/OpenTelemetry"
copy_and_update "OpenTelemetry" "yoga-opentelemetry-om" "Yoga/OpenTelemetry"
copy_and_update "Jaeger" "yoga-jaeger" "Yoga/Jaeger"
copy_and_update "Logger" "yoga-pino" "Yoga"
copy_and_update "Logger" "yoga-pino-om" "Yoga"

# Utilities
copy_and_update "DockerCompose" "yoga-docker-compose" "Yoga/DockerCompose"

echo "All packages created!"
