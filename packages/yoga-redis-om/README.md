# yoga-redis-om

Om-wrapped Redis operations for PureScript using the Yoga Om effect system.

## Overview

This package provides Om-wrapped versions of Redis operations from [yoga-redis](../yoga-redis), allowing you to use Redis within the Om effect system without manually threading the Redis client through your code.

## Installation

```bash
spago install yoga-redis-om yoga-om-core yoga-om-layer
```

## Usage

### Basic Example

```purescript
import Yoga.Redis.Om as Redis
import Yoga.Redis.OmLayer as RedisLayer
import Yoga.Om (runOm)

main = launchAff_ do
  let config = 
        { host: "localhost"
        , port: 6379
        , password: Nothing
        , db: Nothing
        , keyPrefix: Nothing
        , connectTimeout: Nothing
        }
  
  runOm (RedisLayer.live config) do
    -- All operations use the implicit Redis client from the environment
    Redis.set "mykey" "myvalue"
    value <- Redis.get "mykey"
    log $ "Retrieved: " <> show value
```

### With Om Layers

```purescript
import Yoga.Om ((:>), type (:>))
import Yoga.Redis.Om as Redis
import Yoga.Redis.OmLayer (RedisEnv)

-- Your application needs Redis
type AppEnv = RedisEnv :> ()

myApp :: forall r. Has RedisEnv r => Om r Unit
myApp = do
  Redis.set "counter" "0"
  Redis.incr "counter"
  count <- Redis.get "counter"
  log $ "Count: " <> show count

main = launchAff_ do
  runOm (RedisLayer.live config) myApp
```

### Hash Operations

```purescript
import Yoga.Redis.Om as Redis

saveUser :: forall r. Has RedisEnv r => Om r Unit
saveUser = do
  Redis.hset "user:1" "name" "Alice"
  Redis.hset "user:1" "email" "alice@example.com"
  Redis.hset "user:1" "age" "30"
  
  user <- Redis.hgetall "user:1"
  log $ "User data: " <> show user
```

### List Operations

```purescript
import Yoga.Redis.Om as Redis

manageQueue :: forall r. Has RedisEnv r => Om r Unit
manageQueue = do
  -- Add items to queue
  Redis.lpush "tasks" ["task1", "task2", "task3"]
  
  -- Get queue length
  length <- Redis.llen "tasks"
  log $ "Queue length: " <> show length
  
  -- Process items
  task <- Redis.rpop "tasks"
  case task of
    Just t -> log $ "Processing: " <> t
    Nothing -> log "Queue is empty"
```

## API Reference

All operations from [yoga-redis](../yoga-redis) are available with Om wrappers. The key difference is that you don't need to pass the Redis client explicitly - it's provided by the Om environment.

### String Operations

- `get` - Get value by key
- `set` - Set key to value
- `setex` - Set key with expiry
- `del` - Delete key(s)
- `exists` - Check if key exists
- `incr` / `incrBy` - Increment
- `decr` / `decrBy` - Decrement

### Hash Operations

- `hget` - Get field from hash
- `hset` - Set field in hash
- `hgetall` - Get all fields
- `hdel` - Delete field
- `hexists` - Check field exists
- `hkeys` - Get all keys
- `hlen` - Get number of fields

### List Operations

- `lpush` / `rpush` - Push to list
- `lpop` / `rpop` - Pop from list
- `lrange` - Get range
- `llen` - Get length

### Set Operations

- `sadd` - Add members
- `srem` - Remove members
- `smembers` - Get all members
- `sismember` - Check membership
- `scard` - Get size

### Sorted Set Operations

- `zadd` - Add with score
- `zrem` - Remove members
- `zrange` - Get range
- `zcard` - Get size
- `zscore` - Get score

### Other

- `ping` - Test connection
- `publish` - Publish to channel
- `expire` - Set expiry
- `ttl` - Get time to live

## Layer Management

### Creating a Redis Layer

```purescript
import Yoga.Redis.OmLayer as RedisLayer

-- Simple configuration
let config = { url: "redis://localhost:6379" }
let layer = RedisLayer.live config

-- Detailed configuration
let config = 
      { host: "localhost"
      , port: 6379
      , password: Just "secret"
      , db: Just 0
      , keyPrefix: Just "myapp:"
      , connectTimeout: Just (Milliseconds 10000.0)
      }
let layer = RedisLayer.live config
```

### Type-Safe Environment Requirements

The Om system ensures at compile time that your Redis layer is provided:

```purescript
-- This will compile
runOm (RedisLayer.live config) Redis.ping

-- This will NOT compile (missing Redis layer)
runOm emptyLayer Redis.ping
```

## Advantages Over Raw Bindings

1. **No Client Threading** - Redis client is implicit in the environment
2. **Composable** - Easily combine with other Om layers
3. **Type-Safe** - Compiler ensures required layers are provided
4. **Testable** - Easy to mock Redis layer for testing
5. **Clean Code** - Less boilerplate, more readable

## Testing

You can create mock Redis layers for testing:

```purescript
import Yoga.Redis.OmLayer as RedisLayer

mockRedisLayer :: Layer (RedisEnv :> ()) (RedisEnv :> ())
mockRedisLayer = -- implement mock behavior

spec = describe "MyApp" do
  it "works with Redis" do
    result <- runOm mockRedisLayer myApp
    result `shouldEqual` expected
```

## Related Packages

- [yoga-redis](../yoga-redis) - Raw Redis bindings
- [yoga-om-core](https://github.com/rowtype-yoga/purescript-yoga-om) - Om effect system core
- [yoga-om-layer](https://github.com/rowtype-yoga/purescript-yoga-om) - Om layer management

## License

MIT
