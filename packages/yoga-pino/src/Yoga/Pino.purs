module Yoga.Pino where

import Prelude

import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Pino Logger FFI (Modern Node.js Logging)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

foreign import data Logger :: Type

type LoggerOptions =
  { level :: String
  , transport :: { target :: String, options :: { colorize :: Boolean } }
  }

foreign import createLogger :: LoggerOptions -> Effect Logger

-- Logging functions with optional context objects
foreign import infoImpl :: Fn2 Logger String (Effect Unit)
foreign import debugImpl :: Fn2 Logger String (Effect Unit)
foreign import warnImpl :: Fn2 Logger String (Effect Unit)
foreign import errorImpl :: Fn2 Logger String (Effect Unit)

foreign import infoWithImpl :: forall r. Fn2 Logger { msg :: String | r } (Effect Unit)
foreign import debugWithImpl :: forall r. Fn2 Logger { msg :: String | r } (Effect Unit)
foreign import warnWithImpl :: forall r. Fn2 Logger { msg :: String | r } (Effect Unit)
foreign import errorWithImpl :: forall r. Fn2 Logger { msg :: String | r } (Effect Unit)

-- Context-based logging: message + context object
foreign import infoWithContextImpl :: forall r. Fn3 Logger String { | r } (Effect Unit)
foreign import debugWithContextImpl :: forall r. Fn3 Logger String { | r } (Effect Unit)
foreign import warnWithContextImpl :: forall r. Fn3 Logger String { | r } (Effect Unit)
foreign import errorWithContextImpl :: forall r. Fn3 Logger String { | r } (Effect Unit)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PureScript API
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Create a logger with pretty printing
pino :: Effect Logger
pino = createLogger
  { level: "info"
  , transport:
      { target: "pino-pretty"
      , options: { colorize: true }
      }
  }

-- Simple logging
info :: forall m. MonadEffect m => Logger -> String -> m Unit
info logger msg = liftEffect $ runFn2 infoImpl logger msg

debug :: forall m. MonadEffect m => Logger -> String -> m Unit
debug logger msg = liftEffect $ runFn2 debugImpl logger msg

warn :: forall m. MonadEffect m => Logger -> String -> m Unit
warn logger msg = liftEffect $ runFn2 warnImpl logger msg

error :: forall m. MonadEffect m => Logger -> String -> m Unit
error logger msg = liftEffect $ runFn2 errorImpl logger msg

-- Structured logging (with context)
infoWith :: forall m r. MonadEffect m => Logger -> { msg :: String | r } -> m Unit
infoWith logger obj = liftEffect $ runFn2 infoWithImpl logger obj

debugWith :: forall m r. MonadEffect m => Logger -> { msg :: String | r } -> m Unit
debugWith logger obj = liftEffect $ runFn2 debugWithImpl logger obj

warnWith :: forall m r. MonadEffect m => Logger -> { msg :: String | r } -> m Unit
warnWith logger obj = liftEffect $ runFn2 warnWithImpl logger obj

errorWith :: forall m r. MonadEffect m => Logger -> { msg :: String | r } -> m Unit
errorWith logger obj = liftEffect $ runFn2 errorWithImpl logger obj

-- New context-based logging: message + context
infoWithContext :: forall m r. MonadEffect m => Logger -> String -> { | r } -> m Unit
infoWithContext logger msg ctx = liftEffect $ runFn3 infoWithContextImpl logger msg ctx

debugWithContext :: forall m r. MonadEffect m => Logger -> String -> { | r } -> m Unit
debugWithContext logger msg ctx = liftEffect $ runFn3 debugWithContextImpl logger msg ctx

warnWithContext :: forall m r. MonadEffect m => Logger -> String -> { | r } -> m Unit
warnWithContext logger msg ctx = liftEffect $ runFn3 warnWithContextImpl logger msg ctx

errorWithContext :: forall m r. MonadEffect m => Logger -> String -> { | r } -> m Unit
errorWithContext logger msg ctx = liftEffect $ runFn3 errorWithContextImpl logger msg ctx
