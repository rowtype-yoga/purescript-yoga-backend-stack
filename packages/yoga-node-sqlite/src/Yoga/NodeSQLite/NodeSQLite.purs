module Yoga.NodeSQLite.NodeSQLite where

import Prelude

import Data.Either (Either(..))
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
foreign import execImpl :: EffectFn2 String Database Unit
foreign import prepareImpl :: EffectFn2 String Database Statement
foreign import runImpl :: EffectFn2 (Array Foreign) Statement Unit
foreign import getImpl :: EffectFn2 (Array Foreign) Statement (Nullable Foreign)
foreign import allImpl :: EffectFn2 (Array Foreign) Statement (Array Foreign)
foreign import finalizeImpl :: EffectFn1 Statement Unit

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Database Operations
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Open a database connection
open :: DatabasePath -> Effect Database
open (DatabasePath path) = runEffectFn1 openImpl path

-- | Close a database connection
close :: Database -> Effect Unit
close = runEffectFn1 closeImpl

-- | Execute SQL (for DDL/DML without results)
exec :: String -> Database -> Effect Unit
exec sql db = runEffectFn2 execImpl sql db

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Prepared Statements
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Prepare a statement
prepare :: String -> Database -> Effect Statement
prepare sql db = runEffectFn2 prepareImpl sql db

-- | Run a statement (INSERT/UPDATE/DELETE)
run :: Array Foreign -> Statement -> Effect Unit
run params stmt = runEffectFn2 runImpl params stmt

-- | Get a single row
get :: Array Foreign -> Statement -> Effect (Maybe Foreign)
get params stmt = runEffectFn2 getImpl params stmt <#> Nullable.toMaybe

-- | Get all rows
all :: Array Foreign -> Statement -> Effect (Array Foreign)
all params stmt = runEffectFn2 allImpl params stmt

-- | Finalize a statement
finalize :: Statement -> Effect Unit
finalize = runEffectFn1 finalizeImpl
