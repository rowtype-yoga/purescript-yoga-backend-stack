module Yoga.BunSQLite.BunSQLite where

import Prelude

import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)
import Foreign (Foreign)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Opaque Foreign Types
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

foreign import data Database :: Type
foreign import data Statement :: Type

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Newtypes for Type Safety
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

newtype DatabasePath = DatabasePath String

derive instance Newtype DatabasePath _
derive newtype instance Show DatabasePath

-- | Special in-memory database path
inMemory :: DatabasePath
inMemory = DatabasePath ":memory:"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FFI Imports
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

foreign import openImpl :: EffectFn1 String Database
foreign import closeImpl :: EffectFn1 Database Unit
foreign import runImpl :: EffectFn2 String Database Unit
foreign import queryImpl :: EffectFn2 String Database (Array Foreign)
foreign import prepareImpl :: EffectFn2 String Database Statement
foreign import stmtRunImpl :: EffectFn2 (Array Foreign) Statement Unit
foreign import stmtGetImpl :: EffectFn2 (Array Foreign) Statement (Nullable Foreign)
foreign import stmtAllImpl :: EffectFn2 (Array Foreign) Statement (Array Foreign)
foreign import stmtFinalizeImpl :: EffectFn1 Statement Unit

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Database Operations
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Open a database connection
open :: DatabasePath -> Effect Database
open (DatabasePath path) = runEffectFn1 openImpl path

-- | Close a database connection
close :: Database -> Effect Unit
close = runEffectFn1 closeImpl

-- | Run SQL directly (for DDL/DML without results)
run :: String -> Database -> Effect Unit
run sql db = runEffectFn2 runImpl sql db

-- | Query directly (for simple queries)
query :: String -> Database -> Effect (Array Foreign)
query sql db = runEffectFn2 queryImpl sql db

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Prepared Statements
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Prepare a statement
prepare :: String -> Database -> Effect Statement
prepare sql db = runEffectFn2 prepareImpl sql db

-- | Run a prepared statement (INSERT/UPDATE/DELETE)
stmtRun :: Array Foreign -> Statement -> Effect Unit
stmtRun params stmt = runEffectFn2 stmtRunImpl params stmt

-- | Get a single row from a prepared statement
stmtGet :: Array Foreign -> Statement -> Effect (Maybe Foreign)
stmtGet params stmt = runEffectFn2 stmtGetImpl params stmt <#> Nullable.toMaybe

-- | Get all rows from a prepared statement
stmtAll :: Array Foreign -> Statement -> Effect (Array Foreign)
stmtAll params stmt = runEffectFn2 stmtAllImpl params stmt

-- | Finalize a prepared statement
stmtFinalize :: Statement -> Effect Unit
stmtFinalize = runEffectFn1 stmtFinalizeImpl
