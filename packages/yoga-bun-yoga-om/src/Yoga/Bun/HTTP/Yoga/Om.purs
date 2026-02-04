module Yoga.Bun.HTTP.Yoga.Om
  ( serve
  , stringResponse
  , jsonResponse
  , emptyResponse
  , arrayBufferResponse
  , responseRedirect
  , responseError
  , cloneResponse
  ) where

import Prelude

import Yoga.Bun.HTTP (BunServer, ResponseOptions)
import Yoga.Bun.HTTP as BunHTTP
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Prim.Row (class Union)
import Web.Fetch.Request (Request)
import Web.Fetch.Response (Response)

-- | Om-friendly serve that works directly with Aff handlers
serve 
  :: forall opts opts_
   . Union opts opts_ BunHTTP.BunServeOptionsImpl
  => { fetch :: Request -> Aff Response | opts }
  -> Aff BunServer
serve opts = liftEffect $ BunHTTP.serve
  { fetch: BunHTTP.mkFetch opts.fetch
  }

-- | Aff-friendly string response
stringResponse 
  :: forall opts opts_
   . Union opts opts_ ResponseOptions
  => String 
  -> { | opts } 
  -> Aff Response
stringResponse body opts = liftEffect $ BunHTTP.stringResponse body opts

-- | Aff-friendly JSON response
jsonResponse 
  :: forall opts opts_
   . Union opts opts_ ResponseOptions
  => Foreign 
  -> { | opts } 
  -> Aff Response
jsonResponse json opts = liftEffect $ BunHTTP.jsonResponse json opts

-- | Aff-friendly empty response
emptyResponse 
  :: forall opts opts_
   . Union opts opts_ ResponseOptions
  => { | opts } 
  -> Aff Response
emptyResponse opts = liftEffect $ BunHTTP.emptyResponse opts

-- | Aff-friendly array buffer response
arrayBufferResponse 
  :: forall opts opts_
   . Union opts opts_ ResponseOptions
  => Foreign 
  -> { | opts } 
  -> Aff Response
arrayBufferResponse buffer opts = liftEffect $ BunHTTP.arrayBufferResponse buffer opts

-- | Aff-friendly redirect
responseRedirect :: String -> Int -> Aff Response
responseRedirect url status = liftEffect $ BunHTTP.responseRedirect url status

-- | Aff-friendly error response
responseError :: Aff Response
responseError = liftEffect BunHTTP.responseError

-- | Aff-friendly clone
cloneResponse :: Response -> Aff Response
cloneResponse = liftEffect <<< BunHTTP.cloneResponse
