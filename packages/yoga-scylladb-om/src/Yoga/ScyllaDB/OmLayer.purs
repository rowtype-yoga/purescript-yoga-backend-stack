module Yoga.ScyllaDB.OmLayer
  ( ScyllaDBConfig
  , ScyllaDBL
  , scyllaLayer
  , scyllaLayer'
  , noContext
  ) where

import Prelude

import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Yoga.ScyllaDB.ScyllaDB (Client)
import Yoga.ScyllaDB.ScyllaDB as Scylla
import Yoga.Om as Om
import Yoga.Om.Layer (OmLayer, makeLayer)

-- | ScyllaDB configuration
type ScyllaDBConfig =
  { contactPoints :: Array Scylla.ContactPoint
  , localDataCenter :: Scylla.Datacenter
  , keyspace :: Scylla.Keyspace
  , credentials ::
      { username :: Scylla.Username
      , password :: Scylla.Password
      }
  }

-- | Row type for ScyllaDB service
type ScyllaDBL r = (scylla :: Client | r)

-- | Create a ScyllaDB layer that provides Client as a service
-- | Requires ScyllaDBConfig in context
scyllaLayer :: forall r. OmLayer (scyllaConfig :: ScyllaDBConfig | r) (ScyllaDBL ()) ()
scyllaLayer = makeLayer do
  { scyllaConfig } <- Om.ask
  client <- liftEffect $ Scylla.createClient scyllaConfig
  liftAff $ Scylla.connect client
  healthy <- liftAff $ Scylla.ping client
  liftEffect $ Console.log $
    "🗄️  ScyllaDB connected: " <> show (scyllaConfig.localDataCenter)
  liftEffect $ Console.log $
    "   Keyspace: " <> show scyllaConfig.keyspace <> " (healthy: " <> show healthy <> ")"
  pure { scylla: client }

-- | Create a ScyllaDB layer with inline config
-- | Useful when you don't need config from context
scyllaLayer'
  :: forall r
   . ScyllaDBConfig
  -> OmLayer r (ScyllaDBL ()) ()
scyllaLayer' config = makeLayer do
  client <- liftEffect $ Scylla.createClient config
  liftAff $ Scylla.connect client
  healthy <- liftAff $ Scylla.ping client
  liftEffect $ Console.log $
    "🗄️  ScyllaDB connected: " <> show config.localDataCenter
  liftEffect $ Console.log $
    "   Keyspace: " <> show config.keyspace <> " (healthy: " <> show healthy <> ")"
  pure { scylla: client }

-- | Helper to avoid the annoying ({} :: {}) pattern
noContext :: {}
noContext = {}
