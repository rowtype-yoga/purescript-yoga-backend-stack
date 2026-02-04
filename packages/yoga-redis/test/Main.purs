module Test.Redis.Main where

import Prelude

import Data.Array (length)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), isJust)
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff (Aff, delay, launchAff_, try, bracket)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Test.Spec (Spec, around, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Yoga.Test.Docker as Docker
import Yoga.Redis as Redis

-- Test configuration
testHost :: Redis.RedisHost
testHost = Redis.RedisHost "localhost"

testPort :: Redis.RedisPort
testPort = Redis.RedisPort 6380 -- Test port from docker-compose.test.yml

-- Helper to create and manage Redis connection
withRedis :: (Redis.Redis -> Aff Unit) -> Aff Unit
withRedis test = do
  redis <- liftEffect $ Redis.createRedis { host: testHost, port: testPort }
  _ <- Redis.connect redis
  -- Clean up test keys before each test
  _ <- try $ Redis.del [ Redis.RedisKey "test:*" ] redis
  test redis
  _ <- Redis.quit redis
  pure unit

-- Helper to check if value is Left
isLeft :: forall a b. Either a b -> Boolean
isLeft (Left _) = true
isLeft _ = false

spec :: Spec Unit
spec = do
  describe "Yoga.Redis Integration Tests" do

    -- Connection Management Tests
    around withRedis do
      describe "Connection Management" do
        it "connects to Redis successfully" \redis -> do
          pong <- Redis.ping redis
          pong `shouldEqual` "PONG"

        it "handles ping operations" \redis -> do
          pong <- Redis.ping redis
          pong `shouldSatisfy` (_ == "PONG")

    describe "Connection Errors" do
      it "handles connection failures gracefully" do
        result <- try do
          redis <- liftEffect $ Redis.createRedis
            { host: Redis.RedisHost "invalid-host-that-does-not-exist"
            , port: Redis.RedisPort 9999
            }
          _ <- Redis.connect redis
          Redis.ping redis
        result `shouldSatisfy` isLeft

    -- String Operations Tests
    around withRedis do
      describe "String Operations" do
        it "sets and gets values" \redis -> do
          let key = Redis.RedisKey "test:string:key1"
          let value = Redis.RedisValue "test-value"
          _ <- Redis.set key value {} redis
          result <- Redis.get key redis
          result `shouldEqual` Just value

        it "returns Nothing for non-existent keys" \redis -> do
          result <- Redis.get (Redis.RedisKey "test:nonexistent:key") redis
          result `shouldEqual` Nothing

        it "deletes keys successfully" \redis -> do
          let key = Redis.RedisKey "test:string:delete"
          let value = Redis.RedisValue "value-to-delete"
          _ <- Redis.set key value {} redis
          count <- Redis.del [ key ] redis
          count `shouldEqual` 1
          result <- Redis.get key redis
          result `shouldEqual` Nothing

        it "checks key existence" \redis -> do
          let key = Redis.RedisKey "test:string:exists"
          let value = Redis.RedisValue "exists-value"
          _ <- Redis.set key value {} redis
          existsCount <- Redis.exists [ key ] redis
          existsCount `shouldEqual` 1

          _ <- Redis.del [ key ] redis
          notExistsCount <- Redis.exists [ key ] redis
          notExistsCount `shouldEqual` 0

        it "increments and decrements counters" \redis -> do
          let key = Redis.RedisKey "test:string:counter"

          -- Increment from 0 to 1
          val1 <- Redis.incr key redis
          val1 `shouldEqual` 1

          -- Increment by 5
          val2 <- Redis.incrBy key 5 redis
          val2 `shouldEqual` 6

          -- Decrement by 1
          val3 <- Redis.decr key redis
          val3 `shouldEqual` 5

          -- Decrement by 3
          val4 <- Redis.decrBy key 3 redis
          val4 `shouldEqual` 2

    -- Hash Operations Tests
    around withRedis do
      describe "Hash Operations" do
        it "sets and gets hash fields" \redis -> do
          let hashKey = Redis.RedisKey "test:hash:user1"
          let field1 = Redis.RedisField "name"
          let value1 = Redis.RedisValue "Alice"

          _ <- Redis.hset hashKey [ { field: field1, value: value1 } ] redis
          result <- Redis.hget hashKey field1 redis
          result `shouldEqual` Just value1

        it "gets all hash fields" \redis -> do
          let hashKey = Redis.RedisKey "test:hash:user2"
          let
            fields =
              [ { field: Redis.RedisField "name", value: Redis.RedisValue "Bob" }
              , { field: Redis.RedisField "email", value: Redis.RedisValue "bob@example.com" }
              , { field: Redis.RedisField "age", value: Redis.RedisValue "30" }
              ]

          _ <- Redis.hset hashKey fields redis
          result <- Redis.hgetall hashKey redis
          length result `shouldEqual` 3

        it "checks if hash field exists" \redis -> do
          let hashKey = Redis.RedisKey "test:hash:exists"
          let field = Redis.RedisField "field1"
          let value = Redis.RedisValue "value1"

          _ <- Redis.hset hashKey [ { field, value } ] redis
          exists <- Redis.hexists hashKey field redis
          exists `shouldEqual` true

          notExists <- Redis.hexists hashKey (Redis.RedisField "nonexistent") redis
          notExists `shouldEqual` false

        it "deletes hash fields" \redis -> do
          let hashKey = Redis.RedisKey "test:hash:delete"
          let field = Redis.RedisField "temp"
          let value = Redis.RedisValue "temporary"

          _ <- Redis.hset hashKey [ { field, value } ] redis
          count <- Redis.hdel hashKey [ field ] redis
          count `shouldEqual` 1

          result <- Redis.hget hashKey field redis
          result `shouldEqual` Nothing

        it "gets hash length" \redis -> do
          let hashKey = Redis.RedisKey "test:hash:len"
          let
            fields =
              [ { field: Redis.RedisField "f1", value: Redis.RedisValue "v1" }
              , { field: Redis.RedisField "f2", value: Redis.RedisValue "v2" }
              , { field: Redis.RedisField "f3", value: Redis.RedisValue "v3" }
              ]

          _ <- Redis.hset hashKey fields redis
          len <- Redis.hlen hashKey redis
          len `shouldEqual` 3

    -- List Operations Tests
    around withRedis do
      describe "List Operations" do
        it "pushes and pops from lists (right push, left pop)" \redis -> do
          let key = Redis.RedisKey "test:list:queue"
          let
            values =
              [ Redis.RedisValue "first"
              , Redis.RedisValue "second"
              , Redis.RedisValue "third"
              ]

          len <- Redis.rpush key values redis
          len `shouldEqual` 3

          popped <- Redis.lpop key redis
          popped `shouldEqual` Just (Redis.RedisValue "first")

        it "pushes to left and pops from right" \redis -> do
          let key = Redis.RedisKey "test:list:stack"
          let value1 = Redis.RedisValue "bottom"
          let value2 = Redis.RedisValue "top"

          _ <- Redis.lpush key [ value1 ] redis
          _ <- Redis.lpush key [ value2 ] redis

          popped <- Redis.rpop key redis
          popped `shouldEqual` Just value1

        it "gets list range" \redis -> do
          let key = Redis.RedisKey "test:list:range"
          let
            values =
              [ Redis.RedisValue "a"
              , Redis.RedisValue "b"
              , Redis.RedisValue "c"
              , Redis.RedisValue "d"
              ]

          _ <- Redis.rpush key values redis
          result <- Redis.lrange key 0 (-1) redis
          result `shouldEqual` values

          partial <- Redis.lrange key 1 2 redis
          length partial `shouldEqual` 2

        it "gets list length" \redis -> do
          let key = Redis.RedisKey "test:list:length"
          let values = [ Redis.RedisValue "1", Redis.RedisValue "2", Redis.RedisValue "3" ]

          _ <- Redis.rpush key values redis
          len <- Redis.llen key redis
          len `shouldEqual` 3

    -- Set Operations Tests
    around withRedis do
      describe "Set Operations" do
        it "adds and checks members" \redis -> do
          let key = Redis.RedisKey "test:set:members"
          let member1 = Redis.RedisValue "member1"
          let member2 = Redis.RedisValue "member2"

          count <- Redis.sadd key [ member1, member2 ] redis
          count `shouldEqual` 2

          isMember <- Redis.sismember key member1 redis
          isMember `shouldEqual` true

          isNotMember <- Redis.sismember key (Redis.RedisValue "nonexistent") redis
          isNotMember `shouldEqual` false

        it "gets all set members" \redis -> do
          let key = Redis.RedisKey "test:set:all"
          let
            members =
              [ Redis.RedisValue "apple"
              , Redis.RedisValue "banana"
              , Redis.RedisValue "cherry"
              ]

          _ <- Redis.sadd key members redis
          result <- Redis.smembers key redis
          length result `shouldEqual` 3

        it "removes set members" \redis -> do
          let key = Redis.RedisKey "test:set:remove"
          let member = Redis.RedisValue "to-remove"

          _ <- Redis.sadd key [ member ] redis
          count <- Redis.srem key [ member ] redis
          count `shouldEqual` 1

          isMember <- Redis.sismember key member redis
          isMember `shouldEqual` false

        it "gets set cardinality" \redis -> do
          let key = Redis.RedisKey "test:set:card"
          let
            members =
              [ Redis.RedisValue "1"
              , Redis.RedisValue "2"
              , Redis.RedisValue "3"
              , Redis.RedisValue "4"
              ]

          _ <- Redis.sadd key members redis
          card <- Redis.scard key redis
          card `shouldEqual` 4

    -- TTL and Expiration Tests
    around withRedis do
      describe "TTL and Expiration" do
        it "sets TTL on keys with setex" \redis -> do
          let key = Redis.RedisKey "test:ttl:setex"
          let value = Redis.RedisValue "expires-soon"
          let ttl = Redis.TTLSeconds 5

          _ <- Redis.setex key ttl value redis
          ttlResult <- Redis.ttl key redis
          ttlResult `shouldSatisfy` (\t -> t > 0 && t <= 5)

        it "sets expiry with expire command" \redis -> do
          let key = Redis.RedisKey "test:ttl:expire"
          let value = Redis.RedisValue "will-expire"

          _ <- Redis.set key value {} redis
          success <- Redis.expire key (Redis.TTLSeconds 10) redis
          success `shouldEqual` true

          ttlResult <- Redis.ttl key redis
          ttlResult `shouldSatisfy` (\t -> t > 0 && t <= 10)

        it "expires keys after TTL (short wait test)" \redis -> do
          let key = Redis.RedisKey "test:ttl:wait"
          let value = Redis.RedisValue "expires-fast"

          _ <- Redis.setex key (Redis.TTLSeconds 1) value redis

          -- Check it exists initially
          initial <- Redis.get key redis
          initial `shouldSatisfy` isJust

          -- Wait for expiration
          delay (Milliseconds 1200.0)

          result <- Redis.get key redis
          result `shouldEqual` Nothing

        it "returns -2 TTL for non-existent keys" \redis -> do
          let key = Redis.RedisKey "test:ttl:nonexistent"
          ttlResult <- Redis.ttl key redis
          ttlResult `shouldEqual` (-2)

        it "returns -1 TTL for keys without expiration" \redis -> do
          let key = Redis.RedisKey "test:ttl:persistent"
          let value = Redis.RedisValue "no-expiry"

          _ <- Redis.set key value {} redis
          ttlResult <- Redis.ttl key redis
          ttlResult `shouldEqual` (-1)

    -- Sorted Set Operations Tests
    around withRedis do
      describe "Sorted Set Operations" do
        it "adds members with scores" \redis -> do
          let key = Redis.RedisKey "test:zset:leaderboard"
          let
            members =
              [ { score: Redis.RedisScore 100.0, value: Redis.RedisValue "player1" }
              , { score: Redis.RedisScore 200.0, value: Redis.RedisValue "player2" }
              , { score: Redis.RedisScore 150.0, value: Redis.RedisValue "player3" }
              ]

          count <- Redis.zadd key members {} redis
          count `shouldEqual` 3

        it "gets sorted set range with scores" \redis -> do
          let key = Redis.RedisKey "test:zset:range"
          let
            members =
              [ { score: Redis.RedisScore 1.0, value: Redis.RedisValue "a" }
              , { score: Redis.RedisScore 2.0, value: Redis.RedisValue "b" }
              , { score: Redis.RedisScore 3.0, value: Redis.RedisValue "c" }
              ]

          _ <- Redis.zadd key members {} redis
          result <- Redis.zrange key 0 (-1) redis
          length result `shouldEqual` 3

          -- Verify order (should be sorted by score)
          case result of
            [ first, _, _ ] -> first.value `shouldEqual` Redis.RedisValue "a"
            _ -> pure unit

        it "gets member score" \redis -> do
          let key = Redis.RedisKey "test:zset:score"
          let member = { score: Redis.RedisScore 42.5, value: Redis.RedisValue "test" }

          _ <- Redis.zadd key [ member ] {} redis
          score <- Redis.zscore key member.value redis
          score `shouldEqual` Just (Redis.RedisScore 42.5)

        it "removes sorted set members" \redis -> do
          let key = Redis.RedisKey "test:zset:remove"
          let member = { score: Redis.RedisScore 10.0, value: Redis.RedisValue "remove-me" }

          _ <- Redis.zadd key [ member ] {} redis
          count <- Redis.zrem key [ member.value ] redis
          count `shouldEqual` 1

          score <- Redis.zscore key member.value redis
          score `shouldEqual` Nothing

        it "gets sorted set cardinality" \redis -> do
          let key = Redis.RedisKey "test:zset:card"
          let
            members =
              [ { score: Redis.RedisScore 1.0, value: Redis.RedisValue "x" }
              , { score: Redis.RedisScore 2.0, value: Redis.RedisValue "y" }
              ]

          _ <- Redis.zadd key members {} redis
          card <- Redis.zcard key redis
          card `shouldEqual` 2

    -- Pub/Sub Tests
    around withRedis do
      describe "Pub/Sub Operations" do
        it "publishes messages to channel" \redis -> do
          let channel = Redis.RedisChannel "test:pubsub:channel"
          let message = Redis.RedisValue "test-message"

          -- Publishing to a channel with no subscribers returns 0
          subscribers <- Redis.publish channel message redis
          subscribers `shouldSatisfy` (\s -> s >= 0)

main :: Effect Unit
main = launchAff_ do
  liftEffect $ log "\n🧪 Starting Redis Integration Tests (with Docker)\n"

  bracket
    -- Start Docker before tests
    ( do
        liftEffect $ log "⏳ Starting Redis and waiting for it to be ready..."
        Docker.startService "packages/yoga-redis/docker-compose.test.yml" 30
        liftEffect $ log "✅ Redis is ready!\n"
    )
    -- Stop Docker after tests (always runs!)
    ( \_ -> do
        Docker.stopService "packages/yoga-redis/docker-compose.test.yml"
        liftEffect $ log "✅ Cleanup complete\n"
    )
    -- Run tests
    (\_ -> runSpec [ consoleReporter ] spec)
