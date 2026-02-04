# Docker with Bracket Pattern (Advanced PureScript)

## The "Right" Way in PureScript

If we wanted to manage Docker purely in PureScript with guaranteed cleanup, we'd use the `bracket` pattern:

```purescript
import Effect.Aff (bracket)

-- Resource management with guaranteed cleanup
withDocker :: forall a. Aff a -> Aff a
withDocker action = bracket
  startDocker    -- Acquire resource
  stopDocker     -- ALWAYS release (even on exception)
  (\_ -> action) -- Use resource

main :: Effect Unit  
main = launchAff_ do
  withDocker do
    runSpec [consoleReporter] spec
```

## How Bracket Works

```purescript
bracket
  :: forall a b
   . Aff a           -- Acquire resource
  -> (a -> Aff Unit) -- Release resource (ALWAYS runs)
  -> (a -> Aff b)    -- Use resource
  -> Aff b
```

**Key feature:** The release function ALWAYS runs, even if the use function throws.

## Full Implementation

```purescript
module Test.Redis.Main where

import Prelude
import Effect.Aff (Aff, bracket, launchAff_)
import Test.Spec (Spec, describe, it)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Test.Redis.Docker (startDocker, stopDocker)

-- Bracket pattern for Docker management
withDocker :: forall a. Aff a -> Aff a
withDocker = bracket
  (do
    log "🐳 Starting Docker..."
    startDocker
  )
  (\_ -> do
    log "🛑 Stopping Docker..."
    stopDocker
  )
  (\_ -> identity)

main :: Effect Unit
main = launchAff_ $ withDocker do
  log "🧪 Running tests..."
  runSpec [consoleReporter] spec

spec :: Spec Unit
spec = describe "Redis Tests" do
  it "works" do
    pure unit
```

## Pros of Bracket Approach

✅ **Guaranteed cleanup** - Release function always runs
✅ **Pure PureScript** - No external scripts
✅ **Type-safe** - Compiler ensures correct usage
✅ **Composable** - Can nest multiple resources

## Cons of Bracket Approach

❌ **Still need FFI** - Must implement Docker commands in JavaScript
❌ **Complex health checks** - Need to poll for readiness in PureScript  
❌ **More dependencies** - Need `node-child-process` or similar
❌ **More code** - 100+ lines vs 40 lines for external script

## Comparison

### External Script (Current)
```typescript
// 40 lines, TypeScript
try {
  await startDocker();
  await runTests();
} finally {
  await stopDocker();
}
```

**Cleanup:** ✅ Guaranteed  
**Simplicity:** ✅ Very simple  
**Lines of code:** ✅ 40

### Bracket Pattern
```purescript
-- 100+ lines, PureScript + FFI
withDocker = bracket startDocker stopDocker

main = launchAff_ $ withDocker do
  runSpec spec
```

**Cleanup:** ✅ Guaranteed  
**Simplicity:** ❌ Need FFI + health checks  
**Lines of code:** ❌ 100+

### Simple beforeAll/afterAll
```purescript  
-- 150+ lines, PureScript + FFI
main = launchAff_ do
  startDocker
  runSpec spec
  stopDocker
```

**Cleanup:** ❌ Not guaranteed  
**Simplicity:** ❌ Need FFI + health checks  
**Lines of code:** ❌ 150+

## The Trade-off

Both bracket and external scripts guarantee cleanup, but:

| Aspect | External Script | Bracket Pattern |
|--------|----------------|-----------------|
| Language | TypeScript (easier for shell) | PureScript (need FFI) |
| Lines of code | 40 | 100+ |
| Dependencies | None (Bun built-in) | node-child-process + FFI |
| Health checks | Simple (TypeScript) | Complex (PureScript) |
| Maintenance | Easy | Medium |

## Recommendation

**For this project: Keep external scripts**

Because:
1. **Simpler** - 40 lines vs 100+
2. **Better tooling** - Bun excels at shell commands
3. **Easier maintenance** - TypeScript for infrastructure, PureScript for tests
4. **Industry standard** - Most projects separate infrastructure from tests

**But if you want pure PureScript**, the bracket pattern is the way to go!

## Summary

You asked: "Why can't we use beforeAll?"

**Answer:** We can, but:

1. **Simple beforeAll** - No cleanup guarantee ❌
2. **Bracket pattern** - Cleanup guaranteed ✅ (but complex)
3. **External script** - Cleanup guaranteed ✅ (and simple)

The external script is the sweet spot of safety and simplicity.

---

**Your choice:**
- Keep external scripts? (recommended)
- Implement bracket pattern? (I can do this)
- Try simple beforeAll? (I can show the risks)
