module Yoga.ScyllaDB.Om
  ( -- * Om-friendly query operations (with yoga-json parsing)
    execute
  , executeWithOptions
  -- * Unsafe query operations (with unsafeCoerce - use with caution!)
  , executeUnsafe
  -- * Batch operations
  , batch
  , batchWithOptions
  -- * Stream operations
  , stream
  -- * Prepared statements
  , prepare
  , executePrepared
  -- * Metadata
  , getKeyspace
  , getTable
  , getHosts
  -- * Connection
  , connect
  , shutdown
  , ping
  -- * Re-exports from base module
  , module Yoga.ScyllaDB.ScyllaDB
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe)
import Data.Traversable (traverse)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Foreign (Foreign, MultipleErrors)
import Prim.Row (class Union)
import Yoga.ScyllaDB.ScyllaDB (Client, PreparedStatement, CQL, QueryResult, ConsistencyLevel(..), BatchQuery, Keyspace, UUID, ContactPoint, Datacenter, Username, Password, PoolSize, ReplicationFactor)
import Yoga.ScyllaDB.ScyllaDB as Scylla
import Unsafe.Coerce (unsafeCoerce)
import Yoga.JSON (class ReadForeign)
import Yoga.JSON as JSON
import Yoga.Om (Om)
import Yoga.Om as Om

-- * Om-friendly parsed query operations (DEFAULT - opinionated towards yoga-json)

-- | Execute query and parse rows using yoga-json's ReadForeign (DEFAULT)
-- | Throws parse errors to the Om exception channel
execute
  :: forall @a ctx err
   . ReadForeign a
  => Scylla.CQL
  -> Array Foreign
  -> Scylla.Client
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
execute cql params client = do
  result <- liftAff $ Scylla.execute cql params client
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- | Execute query with options and parse rows using yoga-json's ReadForeign
-- | Throws parse errors to the Om exception channel
executeWithOptions
  :: forall @a ctx err opts opts_
   . ReadForeign a
  => Union opts opts_ Scylla.ExecuteOptionsImpl
  => Scylla.CQL
  -> Array Foreign
  -> { | opts }
  -> Scylla.Client
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
executeWithOptions cql params opts client = do
  result <- liftAff $ Scylla.executeWithOptions cql params opts client
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Unsafe query operations (with unsafeCoerce - use with caution!)

-- | Execute query and unsafeCoerce rows to the desired type (bypasses yoga-json parsing)
-- | USE WITH CAUTION - no runtime validation!
executeUnsafe
  :: forall @a ctx err
   . Scylla.CQL
  -> Array Foreign
  -> Scylla.Client
  -> Om ctx err (Array a)
executeUnsafe cql params client = do
  result <- liftAff $ Scylla.execute cql params client
  pure $ unsafeCoerce result.rows

-- * Batch operations

batch
  :: forall @a ctx err
   . ReadForeign a
  => Array Scylla.BatchQuery
  -> Scylla.Client
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
batch queries client = do
  result <- liftAff $ Scylla.batch queries client
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

batchWithOptions
  :: forall @a ctx err opts opts_
   . ReadForeign a
  => Union opts opts_ Scylla.BatchOptionsImpl
  => Array Scylla.BatchQuery
  -> { | opts }
  -> Scylla.Client
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
batchWithOptions queries opts client = do
  result <- liftAff $ Scylla.batchWithOptions queries opts client
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Stream operations

stream
  :: forall @a ctx err
   . ReadForeign a
  => Scylla.CQL
  -> Array Foreign
  -> Scylla.Client
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
stream cql params client = do
  rows <- liftAff $ Scylla.stream cql params client
  traverse parseRow rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Prepared statements

prepare :: forall ctx err. Scylla.CQL -> Scylla.Client -> Om ctx err Scylla.PreparedStatement
prepare cql client = liftAff $ Scylla.prepare cql client

executePrepared
  :: forall @a ctx err
   . ReadForeign a
  => Scylla.PreparedStatement
  -> Array Foreign
  -> Scylla.Client
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
executePrepared stmt params client = do
  result <- liftAff $ Scylla.executePrepared stmt params client
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Metadata

getKeyspace :: forall ctx err. Scylla.Keyspace -> Scylla.Client -> Om ctx err (Maybe Foreign)
getKeyspace keyspace client = liftEffect $ Scylla.getKeyspace keyspace client

getTable :: forall ctx err. Scylla.Keyspace -> String -> Scylla.Client -> Om ctx err (Maybe Foreign)
getTable keyspace table client = liftEffect $ Scylla.getTable keyspace table client

getHosts :: forall ctx err. Scylla.Client -> Om ctx err (Array Foreign)
getHosts client = liftEffect $ Scylla.getHosts client

-- * Connection

connect :: forall ctx err. Scylla.Client -> Om ctx err Unit
connect client = liftAff $ Scylla.connect client

shutdown :: forall ctx err. Scylla.Client -> Om ctx err Unit
shutdown client = liftAff $ Scylla.shutdown client

ping :: forall ctx err. Scylla.Client -> Om ctx err Boolean
ping client = liftAff $ Scylla.ping client
