module Yoga.Bun.HTTP.Yoga.Om.OmLayer
  ( HTTPServerConfig
  , HTTPServerL
  , httpServerLayer
  , httpServerLayer'
  ) where

import Prelude

import Yoga.Bun.HTTP (BunServer)
import Yoga.Bun.HTTP.Yoga.Om as OmHTTP
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Web.Fetch.Request (Request)
import Web.Fetch.Response (Response)
import Yoga.Om as Om
import Yoga.Om.Layer (OmLayer, makeLayer)

-- | HTTP server configuration
type HTTPServerConfig =
  { port :: Int
  , host :: String
  , fetch :: Request -> Aff Response
  }

-- | Row type for HTTP server service
type HTTPServerL r = (httpServer :: BunServer | r)

-- | Create an HTTP server layer that provides BunServer as a service
-- | Requires HTTPServerConfig in context
httpServerLayer :: forall r. OmLayer (httpServerConfig :: HTTPServerConfig | r) (HTTPServerL ()) ()
httpServerLayer = makeLayer do
  { httpServerConfig } <- Om.ask
  server <- liftAff $ OmHTTP.serve
    { fetch: httpServerConfig.fetch
    , port: httpServerConfig.port
    , host: httpServerConfig.host
    }
  liftEffect $ Console.log $ 
    "🚀 Server running on http://" <> httpServerConfig.host <> ":" <> show httpServerConfig.port
  pure { httpServer: server }

-- | Create an HTTP server layer with inline config
-- | Useful when you don't need config from context
httpServerLayer' 
  :: forall r
   . { port :: Int, host :: String, fetch :: Request -> Aff Response }
  -> OmLayer r (HTTPServerL ()) ()
httpServerLayer' config = makeLayer do
  server <- liftAff $ OmHTTP.serve
    { fetch: config.fetch
    , port: config.port
    , host: config.host
    }
  liftEffect $ Console.log $ 
    "🚀 Server running on http://" <> config.host <> ":" <> show config.port
  pure { httpServer: server }
