# Docker Management Approaches - Trade-offs

## The Question

Why use external TypeScript test runners instead of managing Docker in PureScript `beforeAll`/`afterAll` hooks?

## TL;DR

**Both approaches work!** The external script approach was chosen for:
- ✅ Guaranteed cleanup (even if tests crash)
- ✅ Better error messages
- ✅ Language strengths (Bun for shell, PureScript for logic)
- ✅ Simpler test code

But we **could** do it all in PureScript if preferred.

---

## Approach 1: External Scripts (Current)

### Structure
```
packages/yoga-redis/
├── test-with-docker.ts    # Manages Docker lifecycle
└── test/Main.purs         # Pure test logic
```

### Pros
✅ **Guaranteed cleanup** - `finally` block ensures Docker stops even if:
   - Tests crash
   - PureScript runtime errors
   - User hits Ctrl+C

✅ **Better error handling** - TypeScript can catch and report Docker errors clearly

✅ **Language strengths** - Use the right tool for the job:
   - Bun/TypeScript: Shell commands, process management, health checks
   - PureScript: Type-safe test logic

✅ **Simpler test code** - Tests focus on testing, not infrastructure

✅ **No extra dependencies** - Tests don't need `node-child-process` or FFI

### Cons
❌ Extra layer of indirection
❌ Need to remember to use `test:docker` script

### Usage
```bash
bun run test:docker  # One command does everything
```

---

## Approach 2: Internal Hooks (Alternative)

### Structure
```
packages/yoga-redis/
└── test/
    ├── Docker.purs    # FFI for Docker commands
    └── Main.purs      # Tests with beforeAll/afterAll
```

### Implementation
```purescript
-- test/Docker.purs
module Test.Redis.Docker where

foreign import startDockerImpl :: Effect (Promise Unit)
foreign import stopDockerImpl :: Effect (Promise Unit)

startDocker :: Aff Unit
startDocker = Promise.toAffE startDockerImpl

stopDocker :: Aff Unit
stopDocker = Promise.toAffE stopDockerImpl

-- test/Main.purs
main :: Effect Unit
main = launchAff_ do
  -- Start Docker
  startDocker
  
  -- Run tests
  runSpec [consoleReporter] spec
  
  -- Stop Docker (but what if tests crash?)
  stopDocker
```

### Pros
✅ Everything in one place
✅ More "integrated" feel
✅ PureScript programmers don't need to know about external scripts

### Cons
❌ **Cleanup not guaranteed** - If tests crash, Docker keeps running
❌ **Complex error handling** - Need to handle Docker errors in PureScript
❌ **FFI required** - Need JavaScript bindings for shell commands
❌ **Extra dependencies** - Need `node-child-process` or similar
❌ **Harder health checks** - Polling logic in PureScript is more complex

### Problem: Crash Scenario
```purescript
main = launchAff_ do
  startDocker                 -- ✅ Starts
  runSpec [consoleReporter] spec  -- ❌ CRASHES
  stopDocker                  -- ❌ Never runs! Docker still running!
```

---

## Approach 3: Hybrid (Best of Both?)

### Structure
```
packages/yoga-redis/
├── test-with-docker.ts     # Optional convenience wrapper
└── test/
    ├── Docker.purs         # Docker detection/helpers
    └── Main.purs           # Tests that auto-skip if no Docker
```

### Implementation
```purescript
-- test/Docker.purs
foreign import dockerAvailable :: Effect Boolean

-- test/Main.purs
spec :: Spec Unit
spec = do
  -- Tests automatically skip if Docker not available
  around withRedis do
    describe "Redis Operations" do
      it "works with Redis" \redis -> do
        -- test logic
```

### Pros
✅ Tests can run standalone (skip if no Docker)
✅ External script still available for CI/CD
✅ Clear error messages either way

### Cons
❌ Still need external script for guaranteed cleanup
❌ More complex setup

---

## Comparison Table

| Aspect | External Script | Internal Hooks | Hybrid |
|--------|----------------|----------------|--------|
| Guaranteed cleanup | ✅ Yes | ❌ No | ✅ Yes (with script) |
| One command | ✅ Yes | ✅ Yes | ✅ Yes |
| Test code simplicity | ✅ Simple | ❌ Complex | ⚠️ Medium |
| Extra dependencies | ✅ None | ❌ node-child-process | ⚠️ Optional |
| Error handling | ✅ Excellent | ❌ Complex | ✅ Good |
| CI/CD friendly | ✅ Perfect | ⚠️ Risky | ✅ Perfect |

---

## Real-World Example: What Happens on Crash?

### External Script (Current)
```typescript
try {
  await startDocker();
  await runTests();
} finally {
  await stopDocker();  // ✅ ALWAYS runs
}
```

**Result:** Docker stops even if tests crash ✅

### Internal Hooks
```purescript
main = do
  startDocker
  runTests     -- Crashes here
  stopDocker   -- ❌ Never executes
```

**Result:** Docker containers left running ❌

---

## Industry Patterns

### What do other projects do?

**Jest/Vitest (JavaScript):**
```javascript
// External setup script
beforeAll(async () => {
  await docker.start();  // But cleanup not guaranteed
});
```

**Go testing:**
```go
// External docker-compose.yml + Makefile
make test  // Script manages Docker
```

**Rails (Ruby):**
```ruby
# External docker-compose + script
bin/test  // Wrapper script
```

**Conclusion:** Most projects use external scripts for infrastructure.

---

## Recommendation

### For This Project: Keep External Scripts

**Why:**
1. **Safety first** - Guaranteed cleanup prevents Docker sprawl
2. **Better DX** - Clear error messages, simple test code
3. **Industry standard** - Matches common patterns
4. **CI/CD ready** - Works perfectly in automation

### When to Use Internal Hooks

Consider internal hooks if:
- ❌ You never run tests that might crash
- ❌ You're okay manually cleaning up Docker
- ❌ You want everything in PureScript (even FFI)
- ❌ You don't care about guaranteed cleanup

In practice: **External scripts are better** for this use case.

---

## What We Could Do

If you prefer everything in PureScript, I can:

1. ✅ Add FFI bindings for Docker commands
2. ✅ Implement `beforeAll` hooks in tests
3. ✅ Add try/catch for cleanup
4. ⚠️ But cleanup still not 100% guaranteed

**OR**

Keep current approach (recommended) which:
- ✅ Works reliably
- ✅ Is simpler
- ✅ Has guaranteed cleanup
- ✅ Is industry standard

---

## Your Choice!

**Option A: Keep current approach** (recommended)
- ✅ Works great
- ✅ Safe and reliable
- ✅ Industry best practice

**Option B: Move Docker to PureScript**
- I can implement this if you prefer
- But be aware of the cleanup guarantee issue

**Option C: Hybrid approach**
- Tests auto-skip if no Docker
- Scripts still available for automation

Which would you prefer? The current approach is battle-tested and safe, but I'm happy to implement alternatives if you have strong preferences!
