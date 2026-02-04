# Migration to Shared yoga-test-docker Package

## What Changed?

Docker management FFI code has been moved from individual test directories to a **shared package** for reusability.

---

## Before (Duplicated)

Each package had its own Docker FFI:

```
packages/yoga-redis/
  test/
    Docker.purs  ❌ Duplicated
    Docker.js    ❌ Duplicated
    Main.purs    → import Test.Docker

packages/yoga-postgres/
  test/
    Docker.purs  ❌ Duplicated
    Docker.js    ❌ Duplicated
    Main.purs    → import Test.Docker

packages/yoga-scylladb/
  test/
    Docker.purs  ❌ Duplicated
    Docker.js    ❌ Duplicated
    Main.purs    → import Test.Docker
```

**Problem**: 540 lines of duplicated code across 6 files!

---

## After (Shared)

One shared package, imported by all:

```
packages/yoga-test-docker/  ✅ New!
  src/
    Yoga.Test.Docker.purs  ✅ Single source
    Yoga.Test.Docker.js    ✅ Single implementation

packages/yoga-redis/
  test/
    Main.purs  → import Yoga.Test.Docker  ✅ Changed

packages/yoga-postgres/
  test/
    Main.purs  → import Yoga.Test.Docker  ✅ Changed

packages/yoga-scylladb/
  test/
    Main.purs  → import Yoga.Test.Docker  ✅ Changed
```

**Solution**: 160 lines in 1 package, zero duplication!

---

## Code Changes

### Import Statement

**Before:**
```purescript
import Test.Docker as Docker
```

**After:**
```purescript
import Yoga.Test.Docker as Docker
```

### API Calls

**Before:**
```purescript
Docker.startDocker
Docker.waitForHealthy 30
Docker.stopDocker
```

**After:**
```purescript
Docker.startService "packages/my-package/docker-compose.test.yml" 30
Docker.stopService "packages/my-package/docker-compose.test.yml"
```

### Full Example

**Before:**
```purescript
module Test.Redis.Main where

import Test.Docker as Docker  -- Local module

main = launchAff_ do
  bracket
    (do
      Docker.startDocker
      Docker.waitForHealthy 30
    )
    (\_ -> Docker.stopDocker)
    (\_ -> runSpec spec)
```

**After:**
```purescript
module Test.Redis.Main where

import Yoga.Test.Docker as Docker  -- Shared package

main = launchAff_ do
  bracket
    (Docker.startService "packages/yoga-redis/docker-compose.test.yml" 30)
    (\_ -> Docker.stopService "packages/yoga-redis/docker-compose.test.yml")
    (\_ -> runSpec spec)
```

### Dependencies

Add to `spago.yaml`:

**Before:**
```yaml
test:
  dependencies:
    - spec
    # Docker.purs/js in local test/ directory
```

**After:**
```yaml
test:
  dependencies:
    - spec
    - yoga-test-docker  ✅ Add this!
```

---

## API Comparison

### High-Level API (Recommended)

| Before | After | Notes |
|--------|-------|-------|
| `startDocker` | `startService composeFile timeout` | Now takes file path |
| `stopDocker` | `stopService composeFile` | Now takes file path |
| `waitForHealthy attempts` | `waitForHealthy composeFile attempts` | Now takes file path |

### Low-Level API (Same)

| Function | Signature | Notes |
|----------|-----------|-------|
| `dockerComposeUp` | `String -> Aff Unit` | Unchanged |
| `dockerComposeDown` | `String -> Aff Unit` | Unchanged |
| `isServiceHealthy` | `String -> Aff Boolean` | Unchanged |

---

## Why This Change?

### Problems with Duplicated Code

❌ **Maintenance burden**: Fix bugs in 3+ places  
❌ **Inconsistency**: Easy for implementations to drift  
❌ **Code bloat**: 540 lines of duplicate code  
❌ **Hard to extend**: Adding features requires editing multiple files  

### Benefits of Shared Package

✅ **DRY**: Single source of truth  
✅ **Maintainable**: Fix bugs once, benefits all  
✅ **Consistent**: Same behaviour everywhere  
✅ **Reusable**: Easy to add to new packages  
✅ **Documented**: One place for API docs  
✅ **Testable**: Can test the utilities themselves  

---

## Migration Checklist

If you're adding Docker tests to a new package:

- [ ] Create `docker-compose.test.yml` in package directory
- [ ] Add `- yoga-test-docker` to `test.dependencies` in `spago.yaml`
- [ ] Import `Yoga.Test.Docker as Docker` in test Main
- [ ] Use `Docker.startService` and `Docker.stopService` with file paths
- [ ] Run `spago test` to verify

---

## File Structure

### Old Structure (Duplicated)

```
packages/
├── yoga-redis/
│   └── test/
│       ├── Docker.purs    (30 lines)
│       ├── Docker.js      (60 lines)
│       └── Main.purs
├── yoga-postgres/
│   └── test/
│       ├── Docker.purs    (30 lines)
│       ├── Docker.js      (60 lines)
│       └── Main.purs
└── yoga-scylladb/
    └── test/
        ├── Docker.purs    (30 lines)
        ├── Docker.js      (60 lines)
        └── Main.purs
```

**Total**: 180 lines × 3 = 540 lines

### New Structure (Shared)

```
packages/
├── yoga-test-docker/      ⭐ New!
│   ├── src/
│   │   ├── Yoga.Test.Docker.purs  (90 lines)
│   │   └── Yoga.Test.Docker.js    (70 lines)
│   ├── spago.yaml
│   └── README.md
├── yoga-redis/
│   └── test/
│       └── Main.purs      (imports Yoga.Test.Docker)
├── yoga-postgres/
│   └── test/
│       └── Main.purs      (imports Yoga.Test.Docker)
└── yoga-scylladb/
    └── test/
        └── Main.purs      (imports Yoga.Test.Docker)
```

**Total**: 160 lines (single copy)

---

## Examples

See current usage in:
- `packages/yoga-redis/test/Main.purs`
- `packages/yoga-postgres/test/Main.purs`
- `packages/yoga-scylladb/test/Main.purs`

All use the shared `yoga-test-docker` package!

---

## Questions?

- **API docs**: See `packages/yoga-test-docker/README.md`
- **Example usage**: See `packages/yoga-test-docker/EXAMPLE.md`
- **Rationale**: See `SHARED_TEST_DOCKER.md`

---

## Summary

**Old way**: Duplicate Docker.purs/js in each test directory  
**New way**: Import shared `Yoga.Test.Docker` package  

**Result**: 70% less code, single source of truth, easy to maintain! 🎉
