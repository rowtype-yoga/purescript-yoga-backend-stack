module Yoga.Postgres.OmLayer
  ( PostgresConfig
  , PostgresL
  , postgresLayer
  , postgresLayer'
  , noContext
  ) where

import Prelude

import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Yoga.Postgres (Connection)
import Yoga.Postgres as PG
import Yoga.Om as Om
import Yoga.Om.Layer (OmLayer, makeLayer)

-- | Postgres configuration
type PostgresConfig =
  { host :: PG.PostgresHost
  , port :: PG.PostgresPort
  , database :: PG.PostgresDatabase
  , username :: PG.PostgresUsername
  , password :: PG.PostgresPassword
  }

-- | Row type for Postgres service
type PostgresL r = (postgres :: Connection | r)

-- | Create a Postgres layer that provides Connection as a service
-- | Requires PostgresConfig in context
postgresLayer :: forall r. OmLayer (postgresConfig :: PostgresConfig | r) (PostgresL ()) ()
postgresLayer = makeLayer do
  { postgresConfig } <- Om.ask
  conn <- liftEffect $ PG.postgres postgresConfig
  healthy <- liftAff $ PG.ping conn
  liftEffect $ Console.log $
    "🐘 Postgres connected: " <> show postgresConfig.host <> ":" <> show postgresConfig.port
  liftEffect $ Console.log $
    "   Database: " <> show postgresConfig.database <> " (healthy: " <> show healthy <> ")"
  pure { postgres: conn }

-- | Create a Postgres layer with inline config
-- | Useful when you don't need config from context
postgresLayer'
  :: forall r
   . PostgresConfig
  -> OmLayer r (PostgresL ()) ()
postgresLayer' config = makeLayer do
  conn <- liftEffect $ PG.postgres config
  healthy <- liftAff $ PG.ping conn
  liftEffect $ Console.log $
    "🐘 Postgres connected: " <> show config.host <> ":" <> show config.port
  liftEffect $ Console.log $
    "   Database: " <> show config.database <> " (healthy: " <> show healthy <> ")"
  pure { postgres: conn }

-- | Helper to avoid the annoying ({} :: {}) pattern
noContext :: {}
noContext = {}
