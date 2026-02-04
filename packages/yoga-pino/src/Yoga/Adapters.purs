module Yoga.Adapters
  ( createPinoLogger
  , createOtelLogger
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Yoga.Logger (Logger)

-- FFI imports
foreign import createPinoLoggerImpl :: Effect Logger
foreign import createOtelLoggerImpl :: EffectFn1 String Logger

-- Public API

-- Create a Pino-only logger (fast, local dev, no OTEL overhead)
createPinoLogger :: Effect Logger
createPinoLogger = createPinoLoggerImpl

-- Create an OTEL-only logger (production, no console spam)
createOtelLogger :: String -> Effect Logger
createOtelLogger name = runEffectFn1 createOtelLoggerImpl name
