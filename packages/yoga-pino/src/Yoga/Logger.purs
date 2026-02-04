module Yoga.Logger
  ( Logger
  , LogContext
  , logInfo
  , logDebug
  , logWarn
  , logError
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn3, runEffectFn3)
import Foreign.Object (Object)

-- Unified logger interface (regardless of implementation)
foreign import data Logger :: Type

type LogContext = Object String

-- FFI imports for the generic logger
foreign import logInfoImpl :: EffectFn3 Logger String LogContext Unit
foreign import logDebugImpl :: EffectFn3 Logger String LogContext Unit
foreign import logWarnImpl :: EffectFn3 Logger String LogContext Unit
foreign import logErrorImpl :: EffectFn3 Logger String LogContext Unit

-- Public API
logInfo :: Logger -> String -> LogContext -> Effect Unit
logInfo logger msg ctx = runEffectFn3 logInfoImpl logger msg ctx

logDebug :: Logger -> String -> LogContext -> Effect Unit
logDebug logger msg ctx = runEffectFn3 logDebugImpl logger msg ctx

logWarn :: Logger -> String -> LogContext -> Effect Unit
logWarn logger msg ctx = runEffectFn3 logWarnImpl logger msg ctx

logError :: Logger -> String -> LogContext -> Effect Unit
logError logger msg ctx = runEffectFn3 logErrorImpl logger msg ctx
