module Yoga.Fastify.Om.Endpoint2
  ( -- * Endpoint Specification
    Endpoint2
  , endpoint2
  -- * Parsed Endpoint Data
  , EndpointData2
  -- * Endpoint Handler
  , EndpointHandler2
  , handleEndpoint2
  -- * Parsing Typeclasses
  , class ParseRequestSpec
  , parseRequestSpec
  , class ParseQueryField
  , parseQueryField
  , class ParseHeadersField
  , parseHeadersField
  , class ParseBodyField
  , parseBodyField
  -- * Re-exports
  , module Routing.Duplex
  , module Yoga.Fastify.Om.RequestBody
  ) where

import Prelude

import Control.Monad (void)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol, reflectSymbol)
import Effect.Class (liftEffect)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object as Object
import Prim.Row (class Cons, class Lacks, class Union)
import Prim.RowList (class RowToList, RowList)
import Prim.RowList as RL
import Record as Record
import Routing.Duplex (RouteDuplex', parse)
import Routing.Duplex as Routing.Duplex
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)
import Yoga.Fastify.Fastify (FastifyReply, RouteURL(..), StatusCode(..))
import Yoga.Fastify.Fastify as F
import Yoga.Fastify.Om as FO
import Yoga.Fastify.Om.RequestBody (RequestBody(..), class ParseRequestBody, parseRequestBody)
import Yoga.Fastify.Om.RequestBody as RequestBody
import Yoga.JSON (class ReadForeign, class WriteForeign, read, writeImpl)
import Yoga.Om as Om

--------------------------------------------------------------------------------
-- Endpoint Specification
--------------------------------------------------------------------------------

-- | Complete typed endpoint specification with record-based request spec
-- |
-- | Example:
-- |   type UserRequestSpec =
-- |     ( query :: { page :: Int, limit :: Maybe Int }
-- |     , headers :: { authorization :: String }
-- |     , body :: CreateUserRequest
-- |     )
-- |   
-- |   type UserEndpoint = Endpoint2 UserRoute UserRequestSpec UserResponse
-- |
-- | Note: Omit fields entirely from the spec to use defaults (empty records/Unit)
data Endpoint2 path requestSpec response = Endpoint2
  { pathCodec :: RouteDuplex' path
  , requestSpec :: Proxy requestSpec
  , responseType :: Proxy response
  }

-- | Build an endpoint specification
-- |
-- | Example:
-- |   userEndpoint :: Endpoint2 UserRoute UserRequestSpec UserResponse
-- |   userEndpoint = endpoint2 userRoute (Proxy :: Proxy UserRequestSpec) (Proxy :: Proxy UserResponse)
endpoint2
  :: forall path requestSpec response
   . RouteDuplex' path
  -> Proxy requestSpec
  -> Proxy response
  -> Endpoint2 path requestSpec response
endpoint2 pathCodec requestSpec responseType = Endpoint2
  { pathCodec
  , requestSpec
  , responseType
  }

--------------------------------------------------------------------------------
-- Parsed Endpoint Data
--------------------------------------------------------------------------------

-- | Result of parsing an endpoint - all components extracted and typed
type EndpointData2 path query headers body =
  { path :: path
  , query :: Record query
  , headers :: Record headers
  , body :: body
  }

-- | Handler that receives fully parsed endpoint data and returns a response
type EndpointHandler2 path query headers body response ctx err =
  EndpointData2 path query headers body
  -> Om.Om { httpRequest :: FO.RequestContext | ctx } err response

--------------------------------------------------------------------------------
-- Parsing Typeclasses
--------------------------------------------------------------------------------

-- | Parse entire request spec from row list
-- | Note: specBody is the type in the spec (e.g. RequestBody a), handlerBody is what handler receives (e.g. a)
class ParseRequestSpec (rl :: RowList Type) (query :: Row Type) (headers :: Row Type) (specBody :: Type) (handlerBody :: Type) 
  | rl -> query headers specBody handlerBody where
  parseRequestSpec
    :: Proxy rl
    -> Object Foreign -- query params
    -> Object String -- headers
    -> Maybe Foreign -- body
    -> Either String { query :: Record query, headers :: Record headers, body :: handlerBody }

-- Base case: empty spec defaults to empty records and Unit
instance ParseRequestSpec RL.Nil () () Unit Unit where
  parseRequestSpec _ _ _ _ = Right { query: {}, headers: {}, body: unit }

-- When we have a "query" field in the spec
instance
  ( IsSymbol "query"
  , RowToList queryRow queryRowList
  , ParseQueryFieldRecord queryRowList queryRow
  , ParseRequestSpec tail () tailHeaders tailSpecBody tailHandlerBody
  , Cons "query" (Record queryRow) tail' requestSpec
  ) =>
  ParseRequestSpec (RL.Cons "query" (Record queryRow) tail) queryRow tailHeaders tailSpecBody tailHandlerBody where
  parseRequestSpec _ queryObj headersObj bodyObj = do
    query <- parseQueryFieldRecord (Proxy :: Proxy queryRowList) queryObj
    rest <- parseRequestSpec (Proxy :: Proxy tail) queryObj headersObj bodyObj
    Right { query, headers: rest.headers, body: rest.body }

-- When we have a "headers" field in the spec
instance
  ( IsSymbol "headers"
  , RowToList headersRow headersRowList
  , ParseHeadersFieldRecord headersRowList headersRow
  , ParseRequestSpec tail tailQuery () tailSpecBody tailHandlerBody
  , Cons "headers" (Record headersRow) tail' requestSpec
  ) =>
  ParseRequestSpec (RL.Cons "headers" (Record headersRow) tail) tailQuery headersRow tailSpecBody tailHandlerBody where
  parseRequestSpec _ queryObj headersObj bodyObj = do
    headers <- parseHeadersFieldRecord (Proxy :: Proxy headersRowList) headersObj
    rest <- parseRequestSpec (Proxy :: Proxy tail) queryObj headersObj bodyObj
    Right { query: rest.query, headers, body: rest.body }

-- When we have a "body" field in the spec
instance
  ( IsSymbol "body"
  , ParseBodyField specBody handlerBody
  , ParseRequestSpec tail tailQuery tailHeaders Unit Unit
  , Cons "body" specBody tail' requestSpec
  ) =>
  ParseRequestSpec (RL.Cons "body" specBody tail) tailQuery tailHeaders specBody handlerBody where
  parseRequestSpec _ queryObj headersObj bodyObj = do
    body <- parseBodyField (Proxy :: Proxy specBody) headersObj bodyObj
    rest <- parseRequestSpec (Proxy :: Proxy tail) queryObj headersObj bodyObj
    Right { query: rest.query, headers: rest.headers, body }

-- | Parse query field - a record with Maybe-wrapped optional fields
class ParseQueryField (ty :: Type) where
  parseQueryField :: Proxy ty -> Object Foreign -> Either String ty

-- Record instance - delegate to ParseQueryFieldRecord (handles empty records via RL.Nil)
instance (RowToList r rl, ParseQueryFieldRecord rl r) => ParseQueryField (Record r) where
  parseQueryField _ = parseQueryFieldRecord (Proxy :: Proxy rl)

-- | Parse a query record field by field
-- | Uses a typeclass to distinguish required from optional (Maybe-wrapped) fields
class ParseQueryFieldRecord (rl :: RowList Type) (r :: Row Type) | rl -> r where
  parseQueryFieldRecord :: Proxy rl -> Object Foreign -> Either String (Record r)

instance ParseQueryFieldRecord RL.Nil () where
  parseQueryFieldRecord _ _ = Right {}

-- Instance for any field - delegate to ParseQueryFieldValue to handle Maybe/non-Maybe
instance
  ( IsSymbol name
  , ParseQueryFieldValue ty
  , ParseQueryFieldRecord tail tailRow
  , Cons name ty tailRow r
  , Lacks name tailRow
  ) =>
  ParseQueryFieldRecord (RL.Cons name ty tail) r where
  parseQueryFieldRecord _ queryObj =
    let
      key = Proxy :: Proxy name
      keyName = reflectSymbol key
      valueResult = parseQueryFieldValue (Proxy :: Proxy ty) keyName queryObj
      restResult = parseQueryFieldRecord (Proxy :: Proxy tail) queryObj
    in
      case valueResult, restResult of
        Right value, Right rest -> Right (Record.insert key value rest)
        Left err, _ -> Left err
        _, Left err -> Left err

-- | Parse a single query field value
class ParseQueryFieldValue (ty :: Type) where
  parseQueryFieldValue :: Proxy ty -> String -> Object Foreign -> Either String ty

-- Optional field (Maybe type) - checked first
instance (FO.ParseParam inner) => ParseQueryFieldValue (Maybe inner) where
  parseQueryFieldValue _ keyName queryObj =
    Right $ case Object.lookup keyName queryObj of
      Nothing -> Nothing
      Just foreignVal ->
        let
          valueStr = unsafeCoerce foreignVal :: String
        in
          FO.parseParam valueStr
-- Required field (non-Maybe type) - fallback
else instance (FO.ParseParam ty) => ParseQueryFieldValue ty where
  parseQueryFieldValue _ keyName queryObj =
    case Object.lookup keyName queryObj of
      Nothing -> Left $ "Missing required query parameter: " <> keyName
      Just foreignVal ->
        let
          valueStr = unsafeCoerce foreignVal :: String
        in
          case FO.parseParam valueStr of
            Nothing -> Left $ "Invalid query parameter: " <> keyName
            Just value -> Right value

-- | Parse headers field - a record with Maybe-wrapped optional fields
class ParseHeadersField (ty :: Type) where
  parseHeadersField :: Proxy ty -> Object String -> Either String ty

-- Record instance - delegate to ParseHeadersFieldRecord (handles empty records via RL.Nil)
instance (RowToList r rl, ParseHeadersFieldRecord rl r) => ParseHeadersField (Record r) where
  parseHeadersField _ = parseHeadersFieldRecord (Proxy :: Proxy rl)

-- | Parse a headers record field by field
-- | Uses a typeclass to distinguish required from optional (Maybe-wrapped) fields
class ParseHeadersFieldRecord (rl :: RowList Type) (r :: Row Type) | rl -> r where
  parseHeadersFieldRecord :: Proxy rl -> Object String -> Either String (Record r)

instance ParseHeadersFieldRecord RL.Nil () where
  parseHeadersFieldRecord _ _ = Right {}

-- Instance for any field - delegate to ParseHeaderFieldValue to handle Maybe/non-Maybe
instance
  ( IsSymbol name
  , ParseHeaderFieldValue ty
  , ParseHeadersFieldRecord tail tailRow
  , Cons name ty tailRow r
  , Lacks name tailRow
  ) =>
  ParseHeadersFieldRecord (RL.Cons name ty tail) r where
  parseHeadersFieldRecord _ headersObj =
    let
      key = Proxy :: Proxy name
      keyName = reflectSymbol key
      valueResult = parseHeaderFieldValue (Proxy :: Proxy ty) keyName headersObj
      restResult = parseHeadersFieldRecord (Proxy :: Proxy tail) headersObj
    in
      case valueResult, restResult of
        Right value, Right rest -> Right (Record.insert key value rest)
        Left err, _ -> Left err
        _, Left err -> Left err

-- | Parse a single header field value
class ParseHeaderFieldValue (ty :: Type) where
  parseHeaderFieldValue :: Proxy ty -> String -> Object String -> Either String ty

-- Optional header (Maybe String) - checked first
instance ParseHeaderFieldValue (Maybe String) where
  parseHeaderFieldValue _ keyName headersObj =
    Right $ Object.lookup keyName headersObj
-- Required header (String) - fallback
else instance ParseHeaderFieldValue String where
  parseHeaderFieldValue _ keyName headersObj =
    case Object.lookup keyName headersObj of
      Nothing -> Left $ "Missing required header: " <> keyName
      Just value -> Right value

-- | Parse body field
-- |
-- | For RequestBody types, this unwraps the wrapper and returns the inner value:
-- | - RequestBody CreateUserRequest → returns CreateUserRequest
-- | - RequestBody Unit → returns Unit
class ParseBodyField (specTy :: Type) (handlerTy :: Type) | specTy -> handlerTy where
  parseBodyField :: Proxy specTy -> Object String -> Maybe Foreign -> Either String handlerTy

-- Unit instance for no body - checked first
instance ParseBodyField Unit Unit where
  parseBodyField _ _ _ = Right unit
-- RequestBody instance - unwraps to inner value
else instance ParseRequestBody a => ParseBodyField (RequestBody a) a where
  parseBodyField _ headers bodyMaybe = parseRequestBody headers bodyMaybe
-- ReadForeign instance for direct body parsing - fallback
else instance ReadForeign ty => ParseBodyField ty ty where
  parseBodyField _ _ Nothing = Left "Request body is required"
  parseBodyField _ _ (Just foreignBody) =
    case read foreignBody of
      Left err -> Left $ "Invalid request body: " <> show err
      Right parsed -> Right parsed

--------------------------------------------------------------------------------
-- Endpoint Handler Execution
--------------------------------------------------------------------------------

-- | Execute an endpoint handler with automatic parsing and response sending
-- |
-- | Example:
-- |   FO.postOm (RouteURL "/users") (handleEndpoint2 userEndpoint handler) app
-- |   
-- |   where
-- |     handler { path, query, headers, body } = do
-- |       -- All fields are type-safe and parsed!
-- |       pure response
handleEndpoint2
  :: forall path requestSpec requestSpecList query headers specBody handlerBody response ctx err
   . RowToList requestSpec requestSpecList
  => ParseRequestSpec requestSpecList query headers specBody handlerBody
  => WriteForeign response
  => Endpoint2 path requestSpec response
  -> EndpointHandler2 path query headers handlerBody response ctx err
  -> FastifyReply
  -> Om.Om { httpRequest :: FO.RequestContext | ctx } err Unit
handleEndpoint2 (Endpoint2 spec) handler reply = do
  -- Get raw request data
  reqCtx <- FO.httpRequest
  let
    queryObj = reqCtx.query
    headersObj = reqCtx.headers
    bodyObj = reqCtx.body

  -- Parse URL path
  url <- FO.requestUrl
  case parse spec.pathCodec (unwrapUrl url) of
    Left _ -> do
      void $ liftEffect $ F.status (StatusCode 404) reply
      void $ FO.send (unsafeToForeign "Not found") reply

    Right path -> do
      -- Parse request spec (query, headers, body)
      case parseRequestSpec (Proxy :: Proxy requestSpecList) queryObj headersObj bodyObj of
        Left parseError -> do
          void $ liftEffect $ F.status (StatusCode 400) reply
          void $ FO.send (unsafeToForeign parseError) reply

        Right parsed -> do
          -- Call handler with fully parsed data
          let
            endpointData =
              { path
              , query: parsed.query
              , headers: parsed.headers
              , body: parsed.body
              }

          -- Handler returns response value - we serialize and send it
          responseValue <- handler endpointData

          -- Use yoga-json to encode response
          let encodedResponse = writeImpl responseValue
          void $ liftEffect $ F.status (StatusCode 200) reply
          void $ FO.send encodedResponse reply
  where
  unwrapUrl (RouteURL s) = s
