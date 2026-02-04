module Yoga.Postgres.TypedQueryOm where

import Prelude

import Data.Either (Either(..))
import Data.Map (Map)
import Data.Maybe (Maybe)
import Effect.Aff.Class (liftAff)
import Foreign (MultipleErrors)
import Heterogeneous.Folding (class HFoldlWithIndex)
import Yoga.Postgres as PG
import Yoga.Postgres.TypedQuery as TypedQuery
import Yoga.SQL.PostgresTypes (SQLParameter, SQLQuery, TurnIntoSQLParam)
import Yoga.JSON (class ReadForeign)
import Yoga.Om as Om

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Type-Safe Query Execution in Om Context
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Execute a typed SQL query in Om context
-- | Automatically gets Connection from Om context
-- | Throws parse errors to the Om exception channel
executeSql
  :: forall @params @result r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => ReadForeign result
  => SQLQuery params
  -> { | params }
  -> Om.Om { postgres :: PG.Connection | r } (parseError :: String | err) (Array result)
executeSql sqlQuery params = do
  { postgres } <- Om.ask
  result <- liftAff $ TypedQuery.executeSql @params @result sqlQuery params postgres
  case result of
    Left err -> Om.throw { parseError: err }
    Right rows -> pure rows

-- | Execute a typed SQL query and return a single row in Om context
executeSqlOne
  :: forall @params @result r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => ReadForeign result
  => SQLQuery params
  -> { | params }
  -> Om.Om { postgres :: PG.Connection | r } (parseError :: String | err) (Maybe result)
executeSqlOne sqlQuery params = do
  { postgres } <- Om.ask
  result <- liftAff $ TypedQuery.executeSqlOne @params @result sqlQuery params postgres
  case result of
    Left err -> Om.throw { parseError: err }
    Right maybeRow -> pure maybeRow

-- | Execute a mutation in Om context
executeMutation
  :: forall @params r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => SQLQuery params
  -> { | params }
  -> Om.Om { postgres :: PG.Connection | r } err Int
executeMutation sqlQuery params = do
  { postgres } <- Om.ask
  liftAff $ TypedQuery.executeMutation @params sqlQuery params postgres

-- | Execute raw query (no parsing) in Om context
executeSqlRaw
  :: forall @params r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => SQLQuery params
  -> { | params }
  -> Om.Om { postgres :: PG.Connection | r } err PG.QueryResult
executeSqlRaw sqlQuery params = do
  { postgres } <- Om.ask
  liftAff $ TypedQuery.executeSqlRaw @params sqlQuery params postgres
