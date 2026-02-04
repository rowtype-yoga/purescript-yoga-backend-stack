module Yoga.Redis.Om
  ( -- * Om-friendly operations
    ping
  , get
  , set
  , setex
  , del
  , exists
  , expire
  , ttl
  , incr
  , incrBy
  , decr
  , decrBy
  -- * Hash operations
  , hget
  , hset
  , hgetall
  , hdel
  , hexists
  , hkeys
  , hlen
  -- * List operations
  , lpush
  , rpush
  , lpop
  , rpop
  , lrange
  , llen
  -- * Set operations
  , sadd
  , srem
  , smembers
  , sismember
  , scard
  -- * Sorted set operations
  , zadd
  , zrem
  , zrange
  , zcard
  , zscore
  -- * Pub/Sub
  , publish
  -- * Re-exports from base module
  , module Yoga.Redis
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect.Aff.Class (liftAff)
import Prim.Row (class Union)
import Yoga.Redis as R
import Yoga.Redis (Redis, RedisKey, RedisValue, RedisField, RedisChannel, RedisScore, TTLSeconds, TTLMilliseconds, ZAddMember, ZRangeMember)
import Yoga.Om (Om)

-- | Om-friendly ping
ping :: forall ctx err. R.Redis -> Om ctx err String
ping redis = liftAff $ R.ping redis

-- | Om-friendly get
get :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err (Maybe R.RedisValue)
get key redis = liftAff $ R.get key redis

-- | Om-friendly set
set :: forall ctx err opts opts_. Union opts opts_ R.SetOptionsImpl => R.RedisKey -> R.RedisValue -> { | opts } -> R.Redis -> Om ctx err Unit
set key value opts redis = liftAff $ R.set key value opts redis

-- | Om-friendly setex
setex :: forall ctx err. R.RedisKey -> R.TTLSeconds -> R.RedisValue -> R.Redis -> Om ctx err Unit
setex key ttlVal value redis = liftAff $ R.setex key ttlVal value redis

-- | Om-friendly del
del :: forall ctx err. Array R.RedisKey -> R.Redis -> Om ctx err Int
del keys redis = liftAff $ R.del keys redis

-- | Om-friendly exists
exists :: forall ctx err. Array R.RedisKey -> R.Redis -> Om ctx err Int
exists keys redis = liftAff $ R.exists keys redis

-- | Om-friendly expire
expire :: forall ctx err. R.RedisKey -> R.TTLSeconds -> R.Redis -> Om ctx err Boolean
expire key ttlVal redis = liftAff $ R.expire key ttlVal redis

-- | Om-friendly ttl
ttl :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
ttl key redis = liftAff $ R.ttl key redis

-- | Om-friendly incr
incr :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
incr key redis = liftAff $ R.incr key redis

-- | Om-friendly incrBy
incrBy :: forall ctx err. R.RedisKey -> Int -> R.Redis -> Om ctx err Int
incrBy key increment redis = liftAff $ R.incrBy key increment redis

-- | Om-friendly decr
decr :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
decr key redis = liftAff $ R.decr key redis

-- | Om-friendly decrBy
decrBy :: forall ctx err. R.RedisKey -> Int -> R.Redis -> Om ctx err Int
decrBy key decrement redis = liftAff $ R.decrBy key decrement redis

-- Hash operations

-- | Om-friendly hget
hget :: forall ctx err. R.RedisKey -> R.RedisField -> R.Redis -> Om ctx err (Maybe R.RedisValue)
hget key field redis = liftAff $ R.hget key field redis

-- | Om-friendly hset
hset :: forall ctx err. R.RedisKey -> Array { field :: R.RedisField, value :: R.RedisValue } -> R.Redis -> Om ctx err Int
hset key fieldValues redis = liftAff $ R.hset key fieldValues redis

-- | Om-friendly hgetall
hgetall :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err (Array { field :: R.RedisField, value :: R.RedisValue })
hgetall key redis = liftAff $ R.hgetall key redis

-- | Om-friendly hdel
hdel :: forall ctx err. R.RedisKey -> Array R.RedisField -> R.Redis -> Om ctx err Int
hdel key fields redis = liftAff $ R.hdel key fields redis

-- | Om-friendly hexists
hexists :: forall ctx err. R.RedisKey -> R.RedisField -> R.Redis -> Om ctx err Boolean
hexists key field redis = liftAff $ R.hexists key field redis

-- | Om-friendly hkeys
hkeys :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err (Array R.RedisField)
hkeys key redis = liftAff $ R.hkeys key redis

-- | Om-friendly hlen
hlen :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
hlen key redis = liftAff $ R.hlen key redis

-- List operations

-- | Om-friendly lpush
lpush :: forall ctx err. R.RedisKey -> Array R.RedisValue -> R.Redis -> Om ctx err Int
lpush key values redis = liftAff $ R.lpush key values redis

-- | Om-friendly rpush
rpush :: forall ctx err. R.RedisKey -> Array R.RedisValue -> R.Redis -> Om ctx err Int
rpush key values redis = liftAff $ R.rpush key values redis

-- | Om-friendly lpop
lpop :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err (Maybe R.RedisValue)
lpop key redis = liftAff $ R.lpop key redis

-- | Om-friendly rpop
rpop :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err (Maybe R.RedisValue)
rpop key redis = liftAff $ R.rpop key redis

-- | Om-friendly lrange
lrange :: forall ctx err. R.RedisKey -> Int -> Int -> R.Redis -> Om ctx err (Array R.RedisValue)
lrange key start stop redis = liftAff $ R.lrange key start stop redis

-- | Om-friendly llen
llen :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
llen key redis = liftAff $ R.llen key redis

-- Set operations

-- | Om-friendly sadd
sadd :: forall ctx err. R.RedisKey -> Array R.RedisValue -> R.Redis -> Om ctx err Int
sadd key members redis = liftAff $ R.sadd key members redis

-- | Om-friendly srem
srem :: forall ctx err. R.RedisKey -> Array R.RedisValue -> R.Redis -> Om ctx err Int
srem key members redis = liftAff $ R.srem key members redis

-- | Om-friendly smembers
smembers :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err (Array R.RedisValue)
smembers key redis = liftAff $ R.smembers key redis

-- | Om-friendly sismember
sismember :: forall ctx err. R.RedisKey -> R.RedisValue -> R.Redis -> Om ctx err Boolean
sismember key member redis = liftAff $ R.sismember key member redis

-- | Om-friendly scard
scard :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
scard key redis = liftAff $ R.scard key redis

-- Sorted set operations

-- | Om-friendly zadd
zadd :: forall ctx err opts opts_. Union opts opts_ R.ZAddOptionsImpl => R.RedisKey -> Array R.ZAddMember -> { | opts } -> R.Redis -> Om ctx err Int
zadd key members opts redis = liftAff $ R.zadd key members opts redis

-- | Om-friendly zrem
zrem :: forall ctx err. R.RedisKey -> Array R.RedisValue -> R.Redis -> Om ctx err Int
zrem key members redis = liftAff $ R.zrem key members redis

-- | Om-friendly zrange
zrange :: forall ctx err. R.RedisKey -> Int -> Int -> R.Redis -> Om ctx err (Array R.ZRangeMember)
zrange key start stop redis = liftAff $ R.zrange key start stop redis

-- | Om-friendly zcard
zcard :: forall ctx err. R.RedisKey -> R.Redis -> Om ctx err Int
zcard key redis = liftAff $ R.zcard key redis

-- | Om-friendly zscore
zscore :: forall ctx err. R.RedisKey -> R.RedisValue -> R.Redis -> Om ctx err (Maybe R.RedisScore)
zscore key member redis = liftAff $ R.zscore key member redis

-- Pub/Sub operations

-- | Om-friendly publish
publish :: forall ctx err. R.RedisChannel -> R.RedisValue -> R.Redis -> Om ctx err Int
publish channel message redis = liftAff $ R.publish channel message redis
