module Yoga.LoggerOm
  ( logInfo
  , logDebug
  , logWarn
  , logError
  ) where

import Prelude

import Effect.Class (liftEffect)
import Yoga.Logger (Logger)
import Yoga.Logger as Logger
import Prim.Row (class Lacks)
import Record as Record
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)
import Yoga.Om as Om

-- Helper to convert record to Object String
recordToObjectString :: forall r. Record r -> Logger.LogContext
recordToObjectString = unsafeCoerce

-- Om-specific logging functions that use the unified Logger interface
logInfo :: forall ctx logCtx err. Lacks "body" logCtx => String -> { | logCtx } -> Om.Om { logger :: Logger | ctx } err Unit
logInfo message logCtx = do
  { logger } <- Om.ask
  let ctxWithBody = Record.insert (Proxy :: Proxy "body") message logCtx
  liftEffect $ Logger.logInfo logger message (recordToObjectString ctxWithBody)

logDebug :: forall ctx logCtx err. Lacks "body" logCtx => String -> { | logCtx } -> Om.Om { logger :: Logger | ctx } err Unit
logDebug message logCtx = do
  { logger } <- Om.ask
  let ctxWithBody = Record.insert (Proxy :: Proxy "body") message logCtx
  liftEffect $ Logger.logDebug logger message (recordToObjectString ctxWithBody)

logWarn :: forall ctx logCtx err. Lacks "body" logCtx => String -> { | logCtx } -> Om.Om { logger :: Logger | ctx } err Unit
logWarn message logCtx = do
  { logger } <- Om.ask
  let ctxWithBody = Record.insert (Proxy :: Proxy "body") message logCtx
  liftEffect $ Logger.logWarn logger message (recordToObjectString ctxWithBody)

logError :: forall ctx logCtx err. Lacks "body" logCtx => String -> { | logCtx } -> Om.Om { logger :: Logger | ctx } err Unit
logError message logCtx = do
  { logger } <- Om.ask
  let ctxWithBody = Record.insert (Proxy :: Proxy "body") message logCtx
  liftEffect $ Logger.logError logger message (recordToObjectString ctxWithBody)
