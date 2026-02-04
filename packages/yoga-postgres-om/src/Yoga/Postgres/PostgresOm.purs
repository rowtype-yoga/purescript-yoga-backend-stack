module Yoga.Postgres.PostgresOm
  ( -- * Query operations (with yoga-json parsing - DEFAULT)
    query
  , queryOne
  -- * Unsafe query operations (with unsafeCoerce - use with caution!)
  , queryUnsafe
  , queryOneUnsafe
  -- * Execute operations (no parsing needed)
  , execute
  , executeSimple
  -- * Transaction operations
  , begin
  , commit
  , rollback
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse)
import Effect.Aff.Class (liftAff)
import Foreign (Foreign, MultipleErrors)
import Yoga.Postgres as PG
import Unsafe.Coerce (unsafeCoerce)
import Yoga.JSON (class ReadForeign)
import Yoga.JSON as JSON
import Yoga.Om as Om

-- All Postgres functions automatically get the Connection from Om context!

-- * Query operations (with yoga-json parsing - DEFAULT)

-- | Query and parse rows using yoga-json's ReadForeign (DEFAULT)
-- | Automatically gets Connection from Om context
-- | Throws parse errors to the Om exception channel
query
  :: forall @a r err
   . ReadForeign a
  => PG.SQL
  -> Array PG.PGValue
  -> Om.Om { postgres :: PG.Connection | r } (parseError :: MultipleErrors | err) (Array a)
query sql params = do
  { postgres } <- Om.ask
  result <- liftAff $ PG.query sql params postgres
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om.Om { postgres :: PG.Connection | r } (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- | Query one row and parse using yoga-json's ReadForeign (DEFAULT)
-- | Automatically gets Connection from Om context
-- | Throws parse errors to the Om exception channel
queryOne
  :: forall @a r err
   . ReadForeign a
  => PG.SQL
  -> Array PG.PGValue
  -> Om.Om { postgres :: PG.Connection | r } (parseError :: MultipleErrors | err) (Maybe a)
queryOne sql params = do
  { postgres } <- Om.ask
  maybeRow <- liftAff $ PG.queryOne sql params postgres
  case maybeRow of
    Nothing -> pure Nothing
    Just row -> case (JSON.read row :: Either _ a) of
      Left errors -> Om.throw { parseError: errors }
      Right parsed -> pure (Just parsed)

-- * Unsafe query operations (with unsafeCoerce - use with caution!)

-- | Query and unsafeCoerce rows to the desired type (bypasses yoga-json parsing)
-- | Automatically gets Connection from Om context
-- | USE WITH CAUTION - no runtime validation!
queryUnsafe
  :: forall @a r err
   . PG.SQL
  -> Array PG.PGValue
  -> Om.Om { postgres :: PG.Connection | r } err (Array a)
queryUnsafe sql params = do
  { postgres } <- Om.ask
  result <- liftAff $ PG.query sql params postgres
  pure $ unsafeCoerce result.rows

-- | Query one row and unsafeCoerce to the desired type (bypasses yoga-json parsing)
-- | Automatically gets Connection from Om context
-- | USE WITH CAUTION - no runtime validation!
queryOneUnsafe
  :: forall @a r err
   . PG.SQL
  -> Array PG.PGValue
  -> Om.Om { postgres :: PG.Connection | r } err (Maybe a)
queryOneUnsafe sql params = do
  { postgres } <- Om.ask
  maybeRow <- liftAff $ PG.queryOne sql params postgres
  pure $ unsafeCoerce maybeRow

-- * Execute operations (no parsing needed)

execute :: forall r err. PG.SQL -> Array PG.PGValue -> Om.Om { postgres :: PG.Connection | r } err Int
execute sql params = do
  { postgres } <- Om.ask
  liftAff $ PG.execute sql params postgres

executeSimple :: forall r err. PG.SQL -> Om.Om { postgres :: PG.Connection | r } err Int
executeSimple sql = do
  { postgres } <- Om.ask
  liftAff $ PG.executeSimple sql postgres

-- Transaction support
begin :: forall r err. Om.Om { postgres :: PG.Connection | r } err PG.Transaction
begin = do
  { postgres } <- Om.ask
  liftAff $ PG.begin postgres

commit :: forall r err. PG.Transaction -> Om.Om r err Unit
commit txn = liftAff $ PG.commit txn

rollback :: forall r err. PG.Transaction -> Om.Om r err Unit
rollback txn = liftAff $ PG.rollback txn
