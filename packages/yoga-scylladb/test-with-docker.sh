#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🐳 Starting ScyllaDB test service..."
docker compose -f docker-compose.test.yml up -d

cleanup() {
    echo ""
    echo "🛑 Stopping ScyllaDB test service..."
    docker compose -f docker-compose.test.yml down
    echo "✅ Cleanup complete"
}
trap cleanup EXIT

echo "⏳ Waiting for ScyllaDB to be ready (this may take 30-60 seconds)..."
for i in {1..60}; do
    if docker compose -f docker-compose.test.yml ps | grep -q "healthy"; then
        echo "✅ ScyllaDB is ready!"
        break
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo "   Still waiting... (${i}s)"
    fi
    sleep 1
done

echo "🧪 Running tests..."
echo ""
bunx spago test -p yoga-scylladb
