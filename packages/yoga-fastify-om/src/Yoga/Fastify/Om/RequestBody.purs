module Yoga.Fastify.Om.RequestBody
  ( RequestBody(..)
  , class ParseRequestBody
  , parseRequestBody
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import Unsafe.Coerce (unsafeCoerce)
import Yoga.JSON (class ReadForeign, read)

-- | Sum type representing different request body formats
-- |
-- | Example usage:
-- |   type MyEndpointSpec =
-- |     ( body :: RequestBody (JSONBody CreateUserRequest)
-- |     )
data RequestBody a
  = JSONBody a -- JSON parsed via yoga-json ReadForeign
  | NoBody -- No body (for GET, DELETE, etc.)
  | FormData (Object String) -- URL-encoded form data (key-value pairs)
  | TextBody String -- Plain text body
  | BytesBody Foreign -- Raw bytes (Buffer/ArrayBuffer)

-- Note: No Eq instance because BytesBody contains Foreign which doesn't implement Eq

instance Show a => Show (RequestBody a) where
  show (JSONBody a) = "JSONBody (" <> show a <> ")"
  show NoBody = "NoBody"
  show (FormData obj) = "FormData (" <> show (Object.keys obj) <> ")"
  show (TextBody s) = "TextBody \"" <> s <> "\""
  show (BytesBody _) = "BytesBody <buffer>"

-- | Parse request body based on Content-Type header
-- |
-- | The RequestBody wrapper type is used at the spec level, but this class
-- | unwraps it to return the inner value directly to handlers.
-- |
-- | Strategies:
-- | - application/json → parse as JSON (via ReadForeign) → returns typed value
-- | - missing body → Unit
class ParseRequestBody a where
  parseRequestBody
    :: Object String -- headers (to check Content-Type)
    -> Maybe Foreign -- body
    -> Either String a  -- Returns unwrapped inner value

-- Unit instance - when no body needed (checked first)
instance ParseRequestBody Unit where
  parseRequestBody _ _ = Right unit

-- ReadForeign instance - parse JSON or handle other content types (fallback)
else instance ReadForeign a => ParseRequestBody a where
  parseRequestBody headers bodyMaybe =
    case bodyMaybe of
      Nothing -> Left "Request body is required"
      Just foreignBody -> do
        -- Check Content-Type header
        case Object.lookup "content-type" headers of
          Just contentType
            | contentType == "application/json" || contentType == "application/json; charset=utf-8" ->
                case read foreignBody of
                  Left err -> Left $ "Invalid JSON body: " <> show err
                  Right parsed -> Right parsed  -- Return unwrapped value
            | otherwise ->
                Left $ "Unsupported Content-Type: " <> contentType
          Nothing ->
            -- No Content-Type header, try to parse as JSON by default
            case read foreignBody of
              Left err -> Left $ "Invalid JSON body (no Content-Type header): " <> show err
              Right parsed -> Right parsed  -- Return unwrapped value
