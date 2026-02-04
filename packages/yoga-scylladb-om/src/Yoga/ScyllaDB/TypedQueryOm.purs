module Yoga.ScyllaDB.TypedQueryOm where

import Prelude

import Data.Either (Either(..))
import Data.Map (Map)
import Data.Maybe (Maybe)
import Effect.Aff.Class (liftAff)
import Heterogeneous.Folding (class HFoldlWithIndex)
import Yoga.ScyllaDB.ScyllaDB as Scylla
import Yoga.ScyllaDB.TypedQuery as TypedQuery
import Yoga.SQL.Types (SQLParameter, SQLQuery, TurnIntoSQLParam)
import Yoga.JSON (class ReadForeign)
import Yoga.Om as Om

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Type-Safe Query Execution in Om Context
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Execute a typed CQL query in Om context
-- | Automatically gets Client from Om context
-- | Throws parse errors to the Om exception channel
executeSql
  :: forall @params @result r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => ReadForeign result
  => SQLQuery params
  -> { | params }
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: String | err) (Array result)
executeSql sqlQuery params = do
  { scylla } <- Om.ask
  result <- liftAff $ TypedQuery.executeSql @params @result sqlQuery params scylla
  case result of
    Left err -> Om.throw { parseError: err }
    Right rows -> pure rows

-- | Execute a typed CQL query and return a single row in Om context
executeSqlOne
  :: forall @params @result r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => ReadForeign result
  => SQLQuery params
  -> { | params }
  -> Om.Om { scylla :: Scylla.Client | r } (parseError :: String | err) (Maybe result)
executeSqlOne sqlQuery params = do
  { scylla } <- Om.ask
  result <- liftAff $ TypedQuery.executeSqlOne @params @result sqlQuery params scylla
  case result of
    Left err -> Om.throw { parseError: err }
    Right maybeRow -> pure maybeRow

-- | Execute a mutation in Om context
executeMutation
  :: forall @params r err
   . HFoldlWithIndex TurnIntoSQLParam (Map String SQLParameter) { | params } (Map String SQLParameter)
  => SQLQuery params
  -> { | params }
  -> Om.Om { scylla :: Scylla.Client | r } err Unit
executeMutation sqlQuery params = do
  { scylla } <- Om.ask
  liftAff $ TypedQuery.executeMutation @params sqlQuery params scylla
