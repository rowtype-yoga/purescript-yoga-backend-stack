module Yoga.Postgres.Om
  ( -- * Om-friendly query operations (with yoga-json parsing)
    query
  , queryOne
  , unsafe
  -- * Unsafe query operations (with unsafeCoerce - use with caution!)
  , queryUnsafe
  , queryOneUnsafe
  , unsafeUnsafe
  -- * Execute operations (no parsing needed)
  , execute
  , executeSimple
  -- * Transaction operations
  , transaction
  , txQuery
  , txQuerySimple
  , txExecute
  -- * Re-exports from base module
  , module Yoga.Postgres
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse)
import Effect.Aff.Class (liftAff)
import Foreign (Foreign, MultipleErrors)
import Yoga.Postgres (Connection, Transaction, SQL, QueryResult, PGValue, toPGValue)
import Yoga.Postgres as PG
import Unsafe.Coerce (unsafeCoerce)
import Yoga.JSON (class ReadForeign)
import Yoga.JSON as JSON
import Yoga.Om (Om)
import Yoga.Om as Om

-- * Om-friendly parsed query operations (DEFAULT - opinionated towards yoga-json)

-- | Query and parse rows using yoga-json's ReadForeign (DEFAULT)
-- | Throws parse errors to the Om exception channel
query
  :: forall @a ctx err
   . ReadForeign a
  => PG.SQL
  -> Array PG.PGValue
  -> PG.Connection
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
query sql params conn = do
  result <- liftAff $ PG.query sql params conn
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- | Query one row and parse using yoga-json's ReadForeign (DEFAULT)
-- | Throws parse errors to the Om exception channel
queryOne
  :: forall @a ctx err
   . ReadForeign a
  => PG.SQL
  -> Array PG.PGValue
  -> PG.Connection
  -> Om ctx (parseError :: MultipleErrors | err) (Maybe a)
queryOne sql params conn = do
  maybeRow <- liftAff $ PG.queryOne sql params conn
  case maybeRow of
    Nothing -> pure Nothing
    Just row -> case (JSON.read row :: Either _ a) of
      Left errors -> Om.throw { parseError: errors }
      Right parsed -> pure (Just parsed)

-- | Unsafe query (expects exactly one row) and parse using yoga-json (DEFAULT)
-- | Throws parse errors to the Om exception channel
unsafe
  :: forall @a ctx err
   . ReadForeign a
  => PG.SQL
  -> Array PG.PGValue
  -> PG.Connection
  -> Om ctx (parseError :: MultipleErrors | err) a
unsafe sql params conn = do
  row <- liftAff $ PG.unsafe sql params conn
  case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- * Unsafe query operations (with unsafeCoerce - use with caution!)

-- | Query and unsafeCoerce rows to the desired type (bypasses yoga-json parsing)
-- | USE WITH CAUTION - no runtime validation!
queryUnsafe
  :: forall @a ctx err
   . PG.SQL
  -> Array PG.PGValue
  -> PG.Connection
  -> Om ctx err (Array a)
queryUnsafe sql params conn = do
  result <- liftAff $ PG.query sql params conn
  pure $ unsafeCoerce result.rows

-- | Query one row and unsafeCoerce to the desired type (bypasses yoga-json parsing)
-- | USE WITH CAUTION - no runtime validation!
queryOneUnsafe
  :: forall @a ctx err
   . PG.SQL
  -> Array PG.PGValue
  -> PG.Connection
  -> Om ctx err (Maybe a)
queryOneUnsafe sql params conn = do
  maybeRow <- liftAff $ PG.queryOne sql params conn
  pure $ unsafeCoerce maybeRow

-- | Unsafe query (expects exactly one row) and unsafeCoerce to the desired type
-- | USE WITH CAUTION - no runtime validation!
unsafeUnsafe
  :: forall @a ctx err
   . PG.SQL
  -> Array PG.PGValue
  -> PG.Connection
  -> Om ctx err a
unsafeUnsafe sql params conn = do
  row <- liftAff $ PG.unsafe sql params conn
  pure $ unsafeCoerce row

-- * Execute operations (no parsing needed)

-- | Om-friendly execute (takes Connection as parameter)
execute :: forall ctx err. PG.SQL -> Array PG.PGValue -> PG.Connection -> Om ctx err Int
execute sql params conn = liftAff $ PG.execute sql params conn

-- | Om-friendly executeSimple (takes Connection as parameter)
executeSimple :: forall ctx err. PG.SQL -> PG.Connection -> Om ctx err Int
executeSimple sql conn = liftAff $ PG.executeSimple sql conn

-- * Transaction operations (with yoga-json parsing by default)

-- | Om-friendly transaction (takes Connection as parameter)
transaction :: forall ctx err a. (PG.Transaction -> Om ctx err a) -> PG.Connection -> Om ctx err a
transaction action conn = do
  tx <- liftAff $ PG.begin conn
  result <- action tx
  liftAff $ PG.commit tx
  pure result

-- | Transaction query and parse rows using yoga-json's ReadForeign (DEFAULT)
-- | Throws parse errors to the Om exception channel
txQuery
  :: forall @a ctx err
   . ReadForeign a
  => PG.SQL
  -> Array PG.PGValue
  -> PG.Transaction
  -> Om ctx (parseError :: MultipleErrors | err) (Array a)
txQuery sql params tx = do
  result <- liftAff $ PG.txQuery sql params tx
  traverse parseRow result.rows
  where
  parseRow :: Foreign -> Om ctx (parseError :: MultipleErrors | err) a
  parseRow row = case (JSON.read row :: Either _ a) of
    Left errors -> Om.throw { parseError: errors }
    Right parsed -> pure parsed

-- | Om-friendly transaction querySimple (raw Foreign, takes Transaction as parameter)
txQuerySimple :: forall ctx err. PG.SQL -> PG.Transaction -> Om ctx err PG.QueryResult
txQuerySimple sql tx = liftAff $ PG.txQuerySimple sql tx

-- | Om-friendly transaction execute (takes Transaction as parameter)
txExecute :: forall ctx err. PG.SQL -> Array PG.PGValue -> PG.Transaction -> Om ctx err Int
txExecute sql params tx = liftAff $ PG.txExecute sql params tx
