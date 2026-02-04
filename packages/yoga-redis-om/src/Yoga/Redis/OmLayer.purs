module Yoga.Redis.OmLayer
  ( RedisConfig
  , RedisL
  , redisLayer
  , redisLayer'
  ) where

import Prelude

import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Yoga.Redis (Redis)
import Yoga.Redis as R
import Yoga.Om as Om
import Yoga.Om.Layer (OmLayer, makeLayer)

-- | Redis configuration
type RedisConfig =
  { host :: R.RedisHost
  , port :: R.RedisPort
  }

-- | Row type for Redis service
type RedisL r = (redis :: Redis | r)

-- | Create a Redis layer that provides Redis connection as a service
-- | Requires RedisConfig in context
redisLayer :: forall r. OmLayer (redisConfig :: RedisConfig | r) (RedisL ()) ()
redisLayer = makeLayer do
  { redisConfig } <- Om.ask
  redis <- liftEffect $ R.createRedis redisConfig
  pong <- liftAff $ R.ping redis
  liftEffect $ Console.log $
    "⚡ Redis connected: " <> show redisConfig.host <> ":" <> show redisConfig.port
  liftEffect $ Console.log $
    "   Status: " <> pong
  pure { redis }

-- | Create a Redis layer with inline config
-- | Useful when you don't need config from context
redisLayer'
  :: forall r
   . RedisConfig
  -> OmLayer r (RedisL ()) ()
redisLayer' config = makeLayer do
  redis <- liftEffect $ R.createRedis config
  pong <- liftAff $ R.ping redis
  liftEffect $ Console.log $
    "⚡ Redis connected: " <> show config.host <> ":" <> show config.port
  liftEffect $ Console.log $
    "   Status: " <> pong
  pure { redis }
