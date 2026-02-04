#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Running all integration tests with Docker"
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0

run_test() {
    local name=$1
    local dir=$2
    
    echo ""
    echo "============================================================"
    echo "📦 Testing: $name"
    echo "============================================================"
    
    if cd "$ROOT_DIR/$dir" && bash test-with-docker.sh; then
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        echo ""
        echo "✅ $name tests passed"
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        echo ""
        echo "❌ $name tests failed"
    fi
}

run_test "yoga-redis" "packages/yoga-redis"
run_test "yoga-postgres" "packages/yoga-postgres"
run_test "yoga-scylladb" "packages/yoga-scylladb"

echo ""
echo "============================================================"
echo "📊 Test Summary"
echo "============================================================"
echo "✅ Passed: $TOTAL_PASSED/3"
echo "❌ Failed: $TOTAL_FAILED/3"

if [ $TOTAL_FAILED -gt 0 ]; then
    echo ""
    echo "❌ Some tests failed"
    exit 1
else
    echo ""
    echo "✅ All tests passed!"
    exit 0
fi
