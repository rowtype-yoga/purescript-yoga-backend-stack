module Yoga.Bun.HTTP where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import Foreign.Object (Object)
import Prim.Row (class Union)
import Promise (Promise)
import Promise.Aff (toAffE, fromAff) as Promise
import Web.Fetch.Request (Request)
import Web.Fetch.Response (Response)

type BunServerImpl = { stop :: EffectFn1 Boolean (Promise Unit) }

data CloseActiveConnections = WaitForOpenConnections | ForceTerminateAllOpenConnections

type BunServer = { stop :: CloseActiveConnections -> Aff Unit }

foreign import serveImpl :: forall options. EffectFn1 options BunServerImpl

type BunServeOptionsImpl = (fetch :: EffectFn1 Request (Promise Response), port :: Int, host :: String)

serve :: forall opts opts_. Union opts opts_ BunServeOptionsImpl => { fetch :: EffectFn1 Request (Promise Response) | opts } -> Effect BunServer
serve opts = do
  serverImpl <- runEffectFn1 serveImpl opts
  pure
    { stop: \closeActiveConnections -> case closeActiveConnections of
        WaitForOpenConnections -> runEffectFn1 serverImpl.stop true # Promise.toAffE
        ForceTerminateAllOpenConnections -> runEffectFn1 serverImpl.stop false # Promise.toAffE
    }

mkFetch :: (Request -> Aff Response) -> EffectFn1 Request (Promise Response)
mkFetch fetchAff = mkEffectFn1 (fetchAff >>> Promise.fromAff)

-- Response Options Type
type ResponseOptions = (status :: Int, headers :: Object String, statusText :: String)

-- String/text Response
foreign import stringResponseImpl :: forall opts. EffectFn2 String { | opts } Response

stringResponse :: forall opts opts_. Union opts opts_ ResponseOptions => String -> { | opts } -> Effect Response
stringResponse body opts = runEffectFn2 stringResponseImpl body opts

-- JSON Response
foreign import jsonResponseImpl :: forall opts. EffectFn2 Foreign { | opts } Response

jsonResponse :: forall opts opts_. Union opts opts_ ResponseOptions => Foreign -> { | opts } -> Effect Response
jsonResponse json opts = runEffectFn2 jsonResponseImpl json opts

-- Empty Response (useful for 204 No Content)
foreign import emptyResponseImpl :: forall opts. EffectFn1 { | opts } Response

emptyResponse :: forall opts opts_. Union opts opts_ ResponseOptions => { | opts } -> Effect Response
emptyResponse opts = runEffectFn1 emptyResponseImpl opts

-- Response with ArrayBuffer
foreign import arrayBufferResponseImpl :: forall opts. EffectFn2 Foreign { | opts } Response

arrayBufferResponse :: forall opts opts_. Union opts opts_ ResponseOptions => Foreign -> { | opts } -> Effect Response
arrayBufferResponse buffer opts = runEffectFn2 arrayBufferResponseImpl buffer opts

-- Response.redirect() - creates a redirect response
foreign import responseRedirectImpl :: EffectFn2 String Int Response

responseRedirect :: String -> Int -> Effect Response
responseRedirect url status = runEffectFn2 responseRedirectImpl url status

-- Response.error() - creates a network error response
foreign import responseErrorImpl :: Effect Response

responseError :: Effect Response
responseError = responseErrorImpl

-- Clone a Response
foreign import cloneResponseImpl :: Response -> Effect Response

cloneResponse :: Response -> Effect Response
cloneResponse = cloneResponseImpl
