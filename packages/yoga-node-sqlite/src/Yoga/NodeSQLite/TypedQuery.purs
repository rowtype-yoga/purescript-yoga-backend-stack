module Yoga.NodeSQLite.TypedQuery where

import Prelude

import Data.Either (Either(..))
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse)
import Effect (Effect)
import Foreign (Foreign)
import Heterogeneous.Folding (class HFoldlWithIndex)
import Yoga.NodeSQLite.NodeSQLite as SQLite
import Yoga.SQL.Types (SQLParameter, SQLQuery, TurnIntoSQLParam, argsFor, sqlQueryToString)
import Unsafe.Coerce (unsafeCoerce)
import Yoga.JSON (class ReadForeign)
import Yoga.JSON as JSON

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Convert SQL Types to SQLite Types
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Convert a SQLParameter to Foreign for SQLite
sqlParamToForeign :: SQLParameter -> Foreign
sqlParamToForeign = unsafeCoerce

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Type-Safe Query Execution
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Execute a typed SQL query and parse results with yoga-json
executeSql
  :: forall @params @result
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => ReadForeign result
  => SQLQuery params
  -> { | params }
  -> SQLite.Database
  -> Effect (Either String (Array result))
executeSql sqlQuery params db = do
  let
    sql = sqlQueryToString sqlQuery
    sqlParams = argsFor sqlQuery params
    foreignParams = map sqlParamToForeign sqlParams
  stmt <- SQLite.prepare sql db
  rows <- SQLite.all foreignParams stmt
  SQLite.finalize stmt
  pure $ traverse parseRow rows
  where
  parseRow :: Foreign -> Either String result
  parseRow row = case (JSON.read row :: Either _ result) of
    Left errors -> Left (show errors)
    Right parsed -> Right parsed

-- | Execute a typed SQL query and return a single row
executeSqlOne
  :: forall @params @result
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => ReadForeign result
  => SQLQuery params
  -> { | params }
  -> SQLite.Database
  -> Effect (Either String (Maybe result))
executeSqlOne sqlQuery params db = do
  let
    sql = sqlQueryToString sqlQuery
    sqlParams = argsFor sqlQuery params
    foreignParams = map sqlParamToForeign sqlParams
  stmt <- SQLite.prepare sql db
  maybeRow <- SQLite.get foreignParams stmt
  SQLite.finalize stmt
  case maybeRow of
    Nothing -> pure $ Right Nothing
    Just row -> pure $ case (JSON.read row :: Either _ result) of
      Left errors -> Left (show errors)
      Right parsed -> Right (Just parsed)

-- | Execute a mutation (INSERT/UPDATE/DELETE)
executeMutation
  :: forall @params
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => SQLQuery params
  -> { | params }
  -> SQLite.Database
  -> Effect Unit
executeMutation sqlQuery params db = do
  let
    sql = sqlQueryToString sqlQuery
    sqlParams = argsFor sqlQuery params
    foreignParams = map sqlParamToForeign sqlParams
  stmt <- SQLite.prepare sql db
  SQLite.run foreignParams stmt
  SQLite.finalize stmt
