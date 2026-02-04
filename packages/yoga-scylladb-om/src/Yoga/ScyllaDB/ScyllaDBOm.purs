module Yoga.ScyllaDB.ScyllaDBOm
  ( -- * Query operations (with yoga-json parsing - DEFAULT)
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
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe)
import Data.Traversable (traverse)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Foreign (Foreign, MultipleErrors)
import Prim.Row (class Union)
import Yoga.ScyllaDB.ScyllaDB as Scylla
import Unsafe.Coerce (unsafeCoerce)
import Yoga.JSON (class ReadForeign)
import Yoga.JSON as JSON
import Yoga.Om as Om

-- All ScyllaDB functions automatically get the Client from Om context!

-- * Query operations (with yoga-json parsing - DEFAULT)

-- | Execute query and parse rows using yoga-json's ReadForeign (DEFAULT)
-- | Automatically gets Client from Om context
-- | Throws parse errors to the Om exception channel
execute
  :: forall @a r err
   . ReadForeign a
  => Scylla.CQL
  -> Array Foreign
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) (Array a)
execute cql params = do
  { scylla } <- Om.ask
  result <- liftAff $ Scylla.execute cql params scylla
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- | Execute query with options and parse rows using yoga-json's ReadForeign
-- | Automatically gets Client from Om context
-- | Throws parse errors to the Om exception channel
executeWithOptions
  :: forall @a r err opts opts_
   . ReadForeign a
  => Union opts opts_ Scylla.ExecuteOptionsImpl
  => Scylla.CQL
  -> Array Foreign
  -> { | opts }
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) (Array a)
executeWithOptions cql params opts = do
  { scylla } <- Om.ask
  result <- liftAff $ Scylla.executeWithOptions cql params opts scylla
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Unsafe query operations (with unsafeCoerce - use with caution!)

-- | Execute query and unsafeCoerce rows to the desired type (bypasses yoga-json parsing)
-- | Automatically gets Client from Om context
-- | USE WITH CAUTION - no runtime validation!
executeUnsafe
  :: forall @a r err
   . Scylla.CQL
  -> Array Foreign
  -> Om.Om { scylla :: Scylla.Client | r } err (Array a)
executeUnsafe cql params = do
  { scylla } <- Om.ask
  result <- liftAff $ Scylla.execute cql params scylla
  pure $ unsafeCoerce result.rows

-- * Batch operations

batch
  :: forall @a r err
   . ReadForeign a
  => Array Scylla.BatchQuery
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) (Array a)
batch queries = do
  { scylla } <- Om.ask
  result <- liftAff $ Scylla.batch queries scylla
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

batchWithOptions
  :: forall @a r err opts opts_
   . ReadForeign a
  => Union opts opts_ Scylla.BatchOptionsImpl
  => Array Scylla.BatchQuery
  -> { | opts }
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) (Array a)
batchWithOptions queries opts = do
  { scylla } <- Om.ask
  result <- liftAff $ Scylla.batchWithOptions queries opts scylla
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Stream operations

stream
  :: forall @a r err
   . ReadForeign a
  => Scylla.CQL
  -> Array Foreign
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) (Array a)
stream cql params = do
  { scylla } <- Om.ask
  rows <- liftAff $ Scylla.stream cql params scylla
  traverse parseRow rows
  where
  parseRow :: Foreign -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Prepared statements

prepare :: forall r err. Scylla.CQL -> Om.Om { scylla :: Scylla.Client | r } err Scylla.PreparedStatement
prepare cql = do
  { scylla } <- Om.ask
  liftAff $ Scylla.prepare cql scylla

executePrepared
  :: forall @a r err
   . ReadForeign a
  => Scylla.PreparedStatement
  -> Array Foreign
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) (Array a)
executePrepared stmt params = do
  { scylla } <- Om.ask
  result <- liftAff $ Scylla.executePrepared stmt params scylla
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om.Om { scylla :: Scylla.Client | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Metadata

getKeyspace :: forall r err. Scylla.Keyspace -> Om.Om { scylla :: Scylla.Client | r } err (Maybe Foreign)
getKeyspace keyspace = do
  { scylla } <- Om.ask
  liftEffect $ Scylla.getKeyspace keyspace scylla

getTable :: forall r err. Scylla.Keyspace -> String -> Om.Om { scylla :: Scylla.Client | r } err (Maybe Foreign)
getTable keyspace table = do
  { scylla } <- Om.ask
  liftEffect $ Scylla.getTable keyspace table scylla

getHosts :: forall r err. Om.Om { scylla :: Scylla.Client | r } err (Array Foreign)
getHosts = do
  { scylla } <- Om.ask
  liftEffect $ Scylla.getHosts scylla

-- * Connection

connect :: forall r err. Om.Om { scylla :: Scylla.Client | r } err Unit
connect = do
  { scylla } <- Om.ask
  liftAff $ Scylla.connect scylla

shutdown :: forall r err. Om.Om { scylla :: Scylla.Client | r } err Unit
shutdown = do
  { scylla } <- Om.ask
  liftAff $ Scylla.shutdown scylla

ping :: forall r err. Om.Om { scylla :: Scylla.Client | r } err Boolean
ping = do
  { scylla } <- Om.ask
  liftAff $ Scylla.ping scylla
