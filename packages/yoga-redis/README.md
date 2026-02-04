# yoga-redis

Type-safe PureScript FFI bindings for Redis using ioredis.

## Overview

This package provides comprehensive bindings to Redis operations including:
- String operations (get, set, setex, etc.)
- Hash operations (hget, hset, hgetall, etc.)
- List operations (lpush, rpush, lpop, rpop, lrange, etc.)
- Set operations (sadd, srem, smembers, etc.)
- Sorted set operations (zadd, zrem, zrange, etc.)
- Pub/Sub support
- Connection management
- TTL and expiry operations

## Installation

```bash
spago install yoga-redis
```

Make sure to also install the ioredis npm package:

```bash
npm install ioredis
```

## Usage

### Basic Operations

```purescript
import Yoga.Redis as Redis
import Effect.Aff (launchAff_)

main = launchAff_ do
  -- Create and connect
  client <- Redis.createClient { url: "redis://localhost:6379" }
  Redis.connect client
  
  -- String operations
  Redis.set client (Redis.RedisKey "mykey") "myvalue"
  value <- Redis.get client (Redis.RedisKey "mykey")
  
  -- With expiry
  Redis.setex client (Redis.RedisKey "tempkey") (Redis.RedisTTL 60) "tempvalue"
  
  -- Hash operations
  Redis.hset client (Redis.RedisKey "user:1") "name" "John"
  Redis.hset client (Redis.RedisKey "user:1") "email" "john@example.com"
  user <- Redis.hgetall client (Redis.RedisKey "user:1")
  
  -- List operations
  Redis.lpush client (Redis.RedisKey "mylist") ["item1", "item2"]
  items <- Redis.lrange client (Redis.RedisKey "mylist") 0 (-1)
  
  -- Cleanup
  Redis.disconnect client
```

### Configuration

```purescript
import Yoga.Redis as Redis

config :: Redis.RedisConfig
config = 
  { host: Redis.RedisHost "localhost"
  , port: Redis.RedisPort 6379
  , password: Just (Redis.RedisPassword "mypassword")
  , db: Just (Redis.RedisDatabase 0)
  , keyPrefix: Just (Redis.RedisKeyPrefix "myapp:")
  , connectTimeout: Just (Redis.ConnectTimeout (Milliseconds 10000.0))
  }

main = launchAff_ do
  client <- Redis.createClientWithConfig config
  -- ... use client
```

### Pub/Sub

```purescript
import Yoga.Redis.PubSub as RedisPubSub

main = launchAff_ do
  -- Create separate clients for pub and sub
  pubClient <- Redis.createClient { url: "redis://localhost:6379" }
  subClient <- Redis.createClient { url: "redis://localhost:6379" }
  
  -- Subscribe to channel
  RedisPubSub.subscribe subClient "notifications" \message -> do
    log $ "Received: " <> message
  
  -- Publish message
  RedisPubSub.publish pubClient "notifications" "Hello, World!"
```

## Type Safety

All Redis keys are wrapped in a `RedisKey` newtype for type safety:

```purescript
newtype RedisKey = RedisKey String
```

Similarly, TTL values, passwords, and other configuration values use newtypes:

```purescript
newtype RedisTTL = RedisTTL Int
newtype RedisPassword = RedisPassword String
newtype RedisHost = RedisHost String
newtype RedisPort = RedisPort Int
```

## API Reference

### Connection Management

- `createClient` - Create Redis client from URL
- `createClientWithConfig` - Create client with detailed configuration
- `connect` - Connect to Redis
- `disconnect` - Disconnect from Redis
- `quit` - Gracefully quit connection
- `ping` - Test connection

### String Operations

- `get` - Get value by key
- `set` - Set key to value
- `setex` - Set key with expiry time
- `del` - Delete key(s)
- `exists` - Check if key exists
- `incr` / `incrBy` - Increment value
- `decr` / `decrBy` - Decrement value

### Hash Operations

- `hget` - Get field from hash
- `hset` - Set field in hash
- `hgetall` - Get all fields from hash
- `hdel` - Delete field from hash
- `hexists` - Check if field exists
- `hkeys` - Get all field names
- `hlen` - Get number of fields

### List Operations

- `lpush` / `rpush` - Push to list
- `lpop` / `rpop` - Pop from list
- `lrange` - Get range of elements
- `llen` - Get list length

### Set Operations

- `sadd` - Add members to set
- `srem` - Remove members from set
- `smembers` - Get all members
- `sismember` - Check membership
- `scard` - Get set size

### Sorted Set Operations

- `zadd` - Add members with scores
- `zrem` - Remove members
- `zrange` - Get range by index
- `zcard` - Get sorted set size
- `zscore` - Get member score

### TTL Operations

- `expire` - Set key expiry
- `ttl` - Get time to live

## Integration with Om

For Om-based applications, see [yoga-redis-om](../yoga-redis-om) which provides Om-wrapped operations and layer management.

## Related Packages

- [yoga-redis-om](../yoga-redis-om) - Om-wrapped Redis operations
- [ioredis](https://github.com/luin/ioredis) - The underlying Node.js Redis client

## License

MIT
