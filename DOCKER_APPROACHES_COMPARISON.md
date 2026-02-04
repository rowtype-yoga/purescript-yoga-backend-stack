# Docker Management Approaches - Complete Comparison

## TL;DR

You now have **three ways** to run tests with Docker:

| Approach | Command | Best For |
|----------|---------|----------|
| **Spago FFI** ⭐ | `spago test` | Normal workflow |
| **Bash Script** | `./test-with-docker.sh` | Simple & direct |
| **TypeScript** | `bun run test:docker:ts` | Advanced features |

**Recommended**: Just use `spago test` - it handles everything!

---

## 1. Spago Test (FFI) ⭐ RECOMMENDED

### Command
```bash
cd packages/yoga-redis
spago test
```

### How It Works
```purescript
-- test/Main.purs
import Test.Docker as Docker

main = launchAff_ do
  bracket
    Docker.startDocker
    (\_ -> Docker.stopDocker)
    (\_ -> runSpec spec)
```

### Pros
✅ **Single command**: Just `spago test`  
✅ **Integrated**: Native Spago workflow  
✅ **Type-safe**: PureScript's `bracket` guarantees cleanup  
✅ **Self-contained**: No external scripts  
✅ **Package-local**: Each package manages its own Docker

### Cons
❌ Requires FFI code (but it's done!)  
❌ Slightly more complex implementation

### Files
```
test/Docker.purs    # 30 lines
test/Docker.js      # 60 lines
test/Main.purs      # Modified
```

---

## 2. Bash Script (Simple & Direct)

### Command
```bash
cd packages/yoga-redis
./test-with-docker.sh
```

### How It Works
```bash
#!/bin/bash
set -e
docker compose up -d
trap 'docker compose down' EXIT
spago test
```

### Pros
✅ **Simplest**: 20 lines of bash  
✅ **Direct**: Native shell commands  
✅ **No runtime**: Bash is built-in  
✅ **Standard**: `trap EXIT` is idiomatic

### Cons
❌ Separate script (not `spago test`)  
❌ External to test suite

### Files
```
test-with-docker.sh    # 25 lines
```

---

## 3. TypeScript (Advanced)

### Command
```bash
cd packages/yoga-redis
bun run test:docker:ts
```

### How It Works
```typescript
import { $ } from "bun";

try {
  await $`docker compose up -d`.quiet();
  // ... wait for health ...
  await $`spago test`;
} finally {
  await $`docker compose down`.quiet();
}
```

### Pros
✅ **Rich features**: JSON parsing, async/await  
✅ **Type-safe**: TypeScript types  
✅ **Bun integration**: Fast runtime

### Cons
❌ Requires Bun runtime  
❌ More complex (40+ lines)  
❌ Separate script (not `spago test`)

### Files
```
test-with-docker.ts    # 50 lines
```

---

## Side-by-Side Comparison

### Code Size

| Approach | Total Lines | Complexity |
|----------|-------------|------------|
| Spago FFI | ~90 | Medium (FFI required) |
| Bash | ~25 | Low (simple shell) |
| TypeScript | ~50 | Medium (TS + async) |

### User Experience

| Approach | Command | Steps |
|----------|---------|-------|
| Spago FFI ⭐ | `spago test` | 1 |
| Bash | `./test-with-docker.sh` | 1 |
| TypeScript | `bun run test:docker:ts` | 1 |

All are one command! But Spago FFI uses the **standard test command**.

### Integration

| Aspect | Spago FFI | Bash | TypeScript |
|--------|-----------|------|------------|
| **Part of test suite** | ✅ Yes | ❌ No | ❌ No |
| **Uses `spago test`** | ✅ Yes | ❌ No | ❌ No |
| **External script** | ❌ No | ✅ Yes | ✅ Yes |
| **Guaranteed cleanup** | ✅ bracket | ✅ trap | ✅ finally |

### Maintenance

| Aspect | Spago FFI | Bash | TypeScript |
|--------|-----------|------|------------|
| **Files per package** | 2 new + 1 mod | 1 new | 1 new |
| **Dependencies** | Node (via Spago) | Bash (built-in) | Bun runtime |
| **Complexity** | Medium | Low | Medium |
| **Standard approach** | Yes (FFI) | Yes (shell) | Partial |

---

## Which to Choose?

### Use Spago FFI (Recommended) ⭐

**When:**
- Normal development workflow
- Want `spago test` to "just work"
- Prefer integrated solution
- Package should be self-contained

**Why:**
Single command, native integration, type-safe cleanup.

### Use Bash Script

**When:**
- Want simplest possible implementation
- Prefer shell-native approach
- Don't mind separate script
- Value directness over integration

**Why:**
Simplest code, most direct, standard practice.

### Use TypeScript

**When:**
- Need advanced features (JSON parsing, etc.)
- Already using Bun ecosystem
- Want TypeScript type safety
- Need complex Docker orchestration

**Why:**
Rich features, type-safe, async/await.

---

## Real-World Usage

### Daily Development (Use Spago FFI)
```bash
cd packages/yoga-redis
spago test               # ✨ Just works!
```

### CI/CD (Any approach works)
```yaml
# GitHub Actions
- run: cd packages/yoga-redis && spago test
# Or: ./test-with-docker.sh
# Or: bun run test:docker:ts
```

### Debugging Docker (Use direct commands)
```bash
cd packages/yoga-redis
docker compose -f docker-compose.test.yml up
# ... manual testing ...
docker compose -f docker-compose.test.yml down
```

---

## Final Recommendation

**Use Spago FFI** for normal workflow:
```bash
spago test  # Everything automatic!
```

**Bash and TypeScript scripts are still there** if you need them, but for day-to-day testing, `spago test` is the simplest and most integrated approach.

---

## Implementation Status

✅ **All three approaches implemented**  
✅ **All packages compile**  
✅ **All approaches tested**  
✅ **Documentation complete**

Pick your preference and go! 🚀
