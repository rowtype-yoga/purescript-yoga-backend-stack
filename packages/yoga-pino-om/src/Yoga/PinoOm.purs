module Yoga.PinoOm
  ( logInfo
  , logDebug
  , logWarn
  , logError
  ) where

import Prelude

import Effect.Class (liftEffect)
import Yoga.Pino as Log
import Prim.Row (class Lacks)
import Record as Record
import Type.Proxy (Proxy(..))
import Yoga.Om as Om

-- All logging functions automatically get logger from Om context!
-- New API: message + context object (msg gets merged in automatically)

logInfo :: forall ctx r err. Lacks "msg" ctx => String -> { | ctx } -> Om.Om { logger :: Log.Logger | r } err Unit
logInfo msg context = do
  { logger } <- Om.ask
  liftEffect $ Log.infoWith logger (Record.insert (Proxy :: _ "msg") msg context)

logDebug :: forall ctx r err. Lacks "msg" ctx => String -> { | ctx } -> Om.Om { logger :: Log.Logger | r } err Unit
logDebug msg context = do
  { logger } <- Om.ask
  liftEffect $ Log.debugWith logger (Record.insert (Proxy :: _ "msg") msg context)

logWarn :: forall ctx r err. Lacks "msg" ctx => String -> { | ctx } -> Om.Om { logger :: Log.Logger | r } err Unit
logWarn msg context = do
  { logger } <- Om.ask
  liftEffect $ Log.warnWith logger (Record.insert (Proxy :: _ "msg") msg context)

logError :: forall ctx r err. Lacks "msg" ctx => String -> { | ctx } -> Om.Om { logger :: Log.Logger | r } err Unit
logError msg context = do
  { logger } <- Om.ask
  liftEffect $ Log.errorWith logger (Record.insert (Proxy :: _ "msg") msg context)
