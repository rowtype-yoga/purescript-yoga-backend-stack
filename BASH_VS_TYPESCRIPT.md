# Bash vs TypeScript for Docker Management

## The Question

Is bash or TypeScript better for managing Docker in tests?

## TL;DR

**For simple Docker commands: Bash is simpler!** ✅

You now have **both options** - use whichever you prefer:

```bash
bun run test:docker     # Uses bash script (simpler)
bun run test:docker:ts  # Uses TypeScript (more features)
```

---

## Side-by-Side Comparison

### Bash Version (Simpler)
```bash
#!/bin/bash
set -e

# Start Docker
docker compose up -d

# Cleanup on exit (always runs!)
trap 'docker compose down' EXIT

# Wait for health
for i in {1..30}; do
    if docker compose ps | grep -q "healthy"; then
        break
    fi
    sleep 1
done

# Run tests
bunx spago test
```

**Lines:** ~20  
**Dependencies:** None (bash is built-in)  
**Complexity:** Very simple

### TypeScript Version (More Features)
```typescript
import { $ } from "bun";

try {
    await $`docker compose up -d`.quiet();
    
    // Parse JSON output for precise health check
    for (let i = 0; i < 30; i++) {
        const result = await $`docker compose ps --format json`.text();
        const services = result.split('\n').map(line => JSON.parse(line));
        const healthy = services.find(s => s.Health === "healthy");
        if (healthy) break;
        await Bun.sleep(1000);
    }
    
    await $`bunx spago test`;
} finally {
    await $`docker compose down`.quiet();
}
```

**Lines:** ~40  
**Dependencies:** Bun runtime  
**Complexity:** More complex (JSON parsing, etc.)

---

## When to Use Each

### Use Bash When:
✅ Simple Docker commands  
✅ Standard shell operations  
✅ Maximum compatibility  
✅ Don't need JSON parsing  
✅ Simpler is better

### Use TypeScript When:
✅ Need precise JSON parsing  
✅ Complex logic required  
✅ Want type safety  
✅ Integrating with Node/Bun ecosystem  
✅ More features > simplicity

---

## For This Project

### Bash Wins for Docker Management

**Why?**

1. **Simpler** - 20 lines vs 40+ lines
2. **More direct** - Native shell language
3. **No runtime needed** - Bash is everywhere
4. **Easier to read** - `trap cleanup EXIT` is obvious
5. **Standard practice** - Most Docker docs use bash

### Bash Script Features

```bash
set -e                    # Exit on error
trap cleanup EXIT         # ALWAYS runs cleanup
docker compose ps | grep  # Simple health check
for i in {1..30}; do     # Simple loop
```

All standard bash - no fancy features needed!

---

## What's Now Available

You have **both options** in every package:

```bash
# Bash version (simpler)
./packages/yoga-redis/test-with-docker.sh
./packages/yoga-postgres/test-with-docker.sh
./packages/yoga-scylladb/test-with-docker.sh

# TypeScript version (more features)
./packages/yoga-redis/test-with-docker.ts
./packages/yoga-postgres/test-with-docker.ts
./packages/yoga-scylladb/test-with-docker.ts
```

### Package.json (Updated)
```json
{
  "scripts": {
    "test:docker": "./test-with-docker.sh",      // Default: bash
    "test:docker:ts": "bun run test-with-docker.ts"  // Alternative: TS
  }
}
```

### Root Level
```bash
# Bash (now default)
bun run test:all:docker        # Uses bash
./test-all-with-docker.sh      # Direct bash

# TypeScript (alternative)
bun run test:all:docker:ts     # Uses TypeScript
./test-all-with-docker.ts      # Direct TypeScript
```

---

## My Take

**You're right!** For this use case:

| Task | Best Tool | Why |
|------|-----------|-----|
| Docker commands | **Bash** | Native shell language |
| Health checks | **Bash** | `grep` is simpler than JSON parsing |
| Cleanup | **Bash** | `trap EXIT` is perfect |
| Test logic | **PureScript** | Type safety & domain logic |

**Bottom line:** Bash for infrastructure, PureScript for tests. Each language doing what it does best!

---

## Recommendation

**Use the bash scripts** (now the default):

```bash
# Simple and direct
bun run test:redis:docker
```

The TypeScript versions are still there if you need them, but bash is simpler and more appropriate for Docker management.

Good catch! 👍
