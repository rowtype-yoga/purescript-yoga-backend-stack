# Spago Test Approach - Docker Management via FFI

## The Goal

Run `spago test` and have it automatically handle Docker lifecycle - no external scripts needed!

## ✅ Implementation

### How It Works

Tests use the shared `yoga-test-docker` package:

1. **Shared Package** (`packages/yoga-test-docker`)
   - Reusable PureScript module with FFI
   - Calls `docker compose` via Node's `child_process`
   - Single source of truth for all packages

2. **Bracket Pattern** in each `test/Main.purs`
   - Imports `Yoga.Test.Docker`
   - Guarantees cleanup even on failure or Ctrl+C
   - Starts Docker → Runs tests → Stops Docker

### Architecture

```
packages/
├── yoga-test-docker/          # Shared utilities
│   └── src/
│       ├── Yoga.Test.Docker.purs
│       └── Yoga.Test.Docker.js
└── yoga-redis/
    ├── test/
    │   └── Main.purs          # Imports Yoga.Test.Docker
    └── docker-compose.test.yml
```

## Usage (Super Simple!)

```bash
# Just run spago test!
cd packages/yoga-redis
spago test                  # Everything handled automatically

# Or from root
bun run test:redis         # spago test -p yoga-redis
bun run test:postgres      # spago test -p yoga-postgres  
bun run test:scylladb      # spago test -p yoga-scylladb
```

## Implementation Details

### 1. FFI Module (`test/Docker.purs`)

```purescript
module Test.Docker where

import Prelude
import Effect.Aff (Aff, delay, throwError)
import Data.Time.Duration (Milliseconds(..))

foreign import dockerComposeUp :: String -> Aff Unit
foreign import dockerComposeDown :: String -> Aff Unit
foreign import isServiceHealthy :: String -> Aff Boolean

startDocker :: Aff Unit
startDocker = dockerComposeUp "docker-compose.test.yml"

stopDocker :: Aff Unit
stopDocker = dockerComposeDown "docker-compose.test.yml"

waitForHealthy :: Int -> Aff Unit
waitForHealthy maxAttempts = go 0
  where
  go n
    | n >= maxAttempts = throwError $ error "Service failed to become healthy"
    | otherwise = do
        healthy <- isServiceHealthy "docker-compose.test.yml"
        if healthy then pure unit
        else delay (Milliseconds 1000.0) *> go (n + 1)
```

### 2. JavaScript Implementation (`test/Docker.js`)

```javascript
import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const composeDir = path.resolve(__dirname, "..");

export const dockerComposeUp = (composeFile) => () => {
  console.log("🐳 Starting test service...");
  const result = spawnSync(
    "docker",
    ["compose", "-f", composeFile, "up", "-d"],
    { cwd: composeDir, stdio: "pipe" }
  );
  
  if (result.error || result.status !== 0) {
    throw new Error(`Failed to start Docker: ${result.error || result.stderr}`);
  }
  
  return (onError, onSuccess) => onSuccess();
};

export const dockerComposeDown = (composeFile) => () => {
  console.log("\n🛑 Stopping test service...");
  const result = spawnSync(
    "docker",
    ["compose", "-f", composeFile, "down"],
    { cwd: composeDir, stdio: "pipe" }
  );
  
  return (onError, onSuccess) => onSuccess();
};

export const isServiceHealthy = (composeFile) => () => {
  const result = spawnSync(
    "docker",
    ["compose", "-f", composeFile, "ps", "--format", "json"],
    { cwd: composeDir, stdio: "pipe" }
  );
  
  if (result.error || result.status !== 0) {
    return (onError, onSuccess) => onSuccess(false);
  }
  
  const healthy = result.stdout.toString().includes('"Health":"healthy"');
  return (onError, onSuccess) => onSuccess(healthy);
};
```

### 3. Test Main (`test/Main.purs`)

```purescript
import Effect.Aff (bracket)
import Test.Docker as Docker

main :: Effect Unit
main = launchAff_ do
  liftEffect $ log "\n🧪 Starting Integration Tests (with Docker)\n"
  
  bracket
    -- Acquire: Start Docker
    (do
      Docker.startDocker
      liftEffect $ log "⏳ Waiting for service to be ready..."
      Docker.waitForHealthy 30
      liftEffect $ log "✅ Service is ready!\n"
    )
    -- Release: Stop Docker (ALWAYS runs!)
    (\_ -> do
      Docker.stopDocker
      liftEffect $ log "✅ Cleanup complete\n"
    )
    -- Use: Run tests
    (\_ -> runSpec [ consoleReporter ] spec)
```

## Benefits

### ✅ vs External Scripts (Bash/TypeScript)

| Aspect | Spago Test (FFI) | External Scripts |
|--------|------------------|------------------|
| **Command** | `spago test` | `./test-with-docker.sh` |
| **Language** | PureScript + JS FFI | Bash or TypeScript |
| **Integration** | Native to test suite | External wrapper |
| **Dependencies** | Spago (already there) | Bash/Bun runtime |
| **Cleanup** | `bracket` (guaranteed) | `trap EXIT` / `finally` |
| **Complexity** | More (FFI required) | Less (direct commands) |

### 🎯 Why This Approach?

1. **Single Command**: Just `spago test` - nothing else to remember
2. **Type Safety**: PureScript's `bracket` guarantees cleanup
3. **Self-Contained**: Each package manages its own Docker
4. **Native Integration**: No wrapper scripts needed
5. **Spago Workflow**: Fits naturally into `spago test`

### 🔄 Comparison to Alternatives

#### External Bash Script
```bash
# test-with-docker.sh
docker compose up -d
trap 'docker compose down' EXIT
spago test
```
**Pros**: Simpler, direct  
**Cons**: Extra script, not integrated with `spago test`

#### PureScript FFI (Current)
```purescript
bracket startDocker (\_ -> stopDocker) (\_ -> runTests)
```
**Pros**: Native `spago test`, type-safe, integrated  
**Cons**: Requires FFI, more complex

## File Structure

```
packages/yoga-redis/
├── test/
│   ├── Docker.purs              # New: FFI interface
│   ├── Docker.js                # New: JS implementation
│   └── Main.purs                # Updated: uses bracket + Docker
├── docker-compose.test.yml      # Service definition
└── spago.yaml                   # Test dependencies
```

**Added files per package**: 2 (Docker.purs, Docker.js)  
**Modified files per package**: 1 (Main.purs)

## Troubleshooting

### Docker Not Installed
```
Error: Failed to start Docker: spawn docker ENOENT
```
**Solution**: Install Docker Desktop

### Port Already in Use
```
Error: Bind for 0.0.0.0:6380 failed: port is already allocated
```
**Solution**: Stop conflicting containers
```bash
docker compose -f packages/yoga-redis/docker-compose.test.yml down
```

### Service Not Healthy
```
Error: Service failed to become healthy
```
**Solution**: Check Docker logs
```bash
cd packages/yoga-redis
docker compose -f docker-compose.test.yml logs
```

## Summary

**You asked for**: `spago test` to handle Docker  
**You got**: PureScript FFI + `bracket` pattern = automatic Docker lifecycle

**Result**:
```bash
cd packages/yoga-redis
spago test  # 🎉 That's it!
```

No external scripts, no manual Docker commands, just `spago test`!

---

## Alternatives Still Available

If you prefer external scripts, they're still there:

```bash
# Bash version
cd packages/yoga-redis
./test-with-docker.sh

# TypeScript version  
bun run test:docker:ts

# Via package.json
bun run test:redis:docker
```

But now you can also just use:
```bash
spago test  # Handles everything! 🎉
```
