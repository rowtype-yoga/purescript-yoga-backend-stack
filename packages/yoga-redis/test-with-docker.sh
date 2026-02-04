#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🐳 Starting Redis test service..."
docker compose -f docker-compose.test.yml up -d

cleanup() {
    echo ""
    echo "🛑 Stopping Redis test service..."
    docker compose -f docker-compose.test.yml down
    echo "✅ Cleanup complete"
}
trap cleanup EXIT

echo "⏳ Waiting for Redis to be ready..."
for i in {1..30}; do
    if docker compose -f docker-compose.test.yml ps | grep -q "healthy"; then
        echo "✅ Redis is ready!"
        break
    fi
    sleep 1
done

echo "🧪 Running tests..."
echo ""
bunx spago test -p yoga-redis
