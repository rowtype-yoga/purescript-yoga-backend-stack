module Yoga.Bun.HTTP.Yoga.JSON
  ( jsonResponse
  , parseJSON
  , parseJSONRequest
  ) where

import Prelude

import Yoga.Bun.HTTP as BunHTTP
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, throwError)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Foreign (Foreign)
import Prim.Row (class Union)
import Promise.Aff as Promise
import Web.Fetch.Request (Request)
import Web.Fetch.Response (Response)
import Yoga.JSON (class ReadForeign, class WriteForeign, readJSON, writeImpl)

-- | Create a JSON response with type-safe encoding
jsonResponse 
  :: forall a opts opts_
   . WriteForeign a
  => Union opts opts_ BunHTTP.ResponseOptions
  => a 
  -> { | opts } 
  -> Effect Response
jsonResponse value opts = 
  BunHTTP.jsonResponse (writeImpl value) opts

-- | Parse JSON from a string
parseJSON :: forall a. ReadForeign a => String -> Aff a
parseJSON str = case readJSON str of
  Right value -> pure value
  Left err -> throwError $ error $ show err

-- | Parse JSON from a Request body
foreign import requestTextImpl :: Request -> Effect (Promise.Promise String)

parseJSONRequest :: forall a. ReadForeign a => Request -> Aff a
parseJSONRequest req = do
  textPromise <- liftEffect $ requestTextImpl req
  text <- Promise.toAff textPromise
  parseJSON text
