module Yoga.Fastify.Om.Endpoint
  ( -- * Endpoint Specification
    Endpoint
  , endpoint
  -- * Parsed Endpoint Data
  , EndpointData
  -- * Endpoint Handler
  , EndpointHandler
  , handleEndpoint
  -- * Parsing Typeclasses (for instances)
  , class ParseRequiredQuery
  , parseRequiredQuery
  , class ParseOptionalQuery
  , parseOptionalQuery
  , class ParseRequiredHeaders
  , parseRequiredHeaders
  , class ParseOptionalHeaders
  , parseOptionalHeaders
  -- * Re-exports
  , module Routing.Duplex
  ) where

import Prelude

import Control.Monad (void)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol, reflectSymbol)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object as Object
import Prim.Row (class Cons, class Lacks)
import Prim.RowList (class RowToList, RowList)
import Prim.RowList as RL
import Record as Record
import Routing.Duplex (RouteDuplex', parse, print)
import Routing.Duplex as Routing.Duplex
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)
import Yoga.Fastify.Fastify (FastifyReply, StatusCode(..), RouteURL(..))
import Yoga.Fastify.Fastify as F
import Yoga.Fastify.Om as FO
import Yoga.JSON (class ReadForeign, class WriteForeign, read, writeImpl)
import Yoga.Om as Om

--------------------------------------------------------------------------------
-- Endpoint Specification
--------------------------------------------------------------------------------

-- | Complete typed endpoint specification
-- |
-- | Example:
-- |   type UserEndpoint = Endpoint
-- |     UserRoute                      -- path: routing-duplex route
-- |     ( page :: Int )                -- requiredQuery
-- |     ( limit :: Int )               -- optionalQuery (all wrapped in Maybe)
-- |     CreateUserRequest              -- body
-- |     ( authorization :: String )    -- requiredHeaders
-- |     ( x-request-id :: String )     -- optionalHeaders (all wrapped in Maybe)
-- |     User                           -- response: what the handler returns
data Endpoint path reqQuery optQuery body reqHeaders optHeaders response = Endpoint
  { pathCodec :: RouteDuplex' path
  , requiredQuery :: Proxy reqQuery
  , optionalQuery :: Proxy optQuery
  , bodyType :: Proxy body
  , requiredHeaders :: Proxy reqHeaders
  , optionalHeaders :: Proxy optHeaders
  , responseType :: Proxy response
  }

-- | Build an endpoint specification
-- |
-- | Example:
-- |   userEndpoint = endpoint
-- |     { pathCodec: userRoute
-- |     , requiredQuery: Proxy :: Proxy ( page :: Int )
-- |     , optionalQuery: Proxy :: Proxy ( limit :: Int, sort :: String )
-- |     , bodyType: Proxy :: Proxy CreateUserRequest
-- |     , requiredHeaders: Proxy :: Proxy ( authorization :: String )
-- |     , optionalHeaders: Proxy :: Proxy ( x-request-id :: String )
-- |     , responseType: Proxy :: Proxy User
-- |     }
endpoint
  :: forall path reqQuery optQuery body reqHeaders optHeaders response
   . { pathCodec :: RouteDuplex' path
     , requiredQuery :: Proxy reqQuery
     , optionalQuery :: Proxy optQuery
     , bodyType :: Proxy body
     , requiredHeaders :: Proxy reqHeaders
     , optionalHeaders :: Proxy optHeaders
     , responseType :: Proxy response
     }
  -> Endpoint path reqQuery optQuery body reqHeaders optHeaders response
endpoint = Endpoint

--------------------------------------------------------------------------------
-- Parsed Endpoint Data
--------------------------------------------------------------------------------

-- | Result of parsing an endpoint - all components extracted and typed
-- | Optional fields are wrapped in Maybe at the value level
type EndpointData path reqQuery optQuery body reqHeaders optHeaders =
  { path :: path
  , requiredQuery :: Record reqQuery
  , optionalQuery :: Record optQuery -- Fields are Maybe ty at the value level
  , body :: body
  , requiredHeaders :: Record reqHeaders
  , optionalHeaders :: Record optHeaders -- Fields are Maybe String at the value level
  }

--------------------------------------------------------------------------------
-- Endpoint Handler Type
--------------------------------------------------------------------------------

-- | Handler that receives fully parsed endpoint data and returns a response
-- |
-- | Example:
-- |   handler :: EndpointHandler UserPath ( page :: Int ) ( limit :: Int ) Body ( auth :: String ) () User ctx ()
-- |   handler { path: User userId, requiredQuery: { page }, optionalQuery: { limit }, body, requiredHeaders: { auth } } = do
-- |     -- All fields type-safe and parsed!
-- |     user <- createUser userId page body
-- |     pure user  -- Just return the response value!
type EndpointHandler path reqQuery optQuery body reqHeaders optHeaders response ctx err =
  EndpointData path reqQuery optQuery body reqHeaders optHeaders
  -> Om.Om { httpRequest :: FO.RequestContext | ctx } err response

--------------------------------------------------------------------------------
-- Parsing Typeclasses
--------------------------------------------------------------------------------

-- | Parse required query parameters
class ParseRequiredQuery (rl :: RowList Type) (r :: Row Type) | rl -> r where
  parseRequiredQuery :: Proxy rl -> Object Foreign -> Either FO.QueryParamErrors (Record r)

instance ParseRequiredQuery RL.Nil () where
  parseRequiredQuery _ _ = Right {}

instance
  ( IsSymbol name
  , FO.ParseParam ty
  , ParseRequiredQuery tail tailRow
  , Cons name ty tailRow r
  , Lacks name tailRow
  ) =>
  ParseRequiredQuery (RL.Cons name ty tail) r where
  parseRequiredQuery _ qps =
    let
      key = Proxy :: Proxy name
      keyName = reflectSymbol key
      valueResult = case Object.lookup keyName qps of
        Nothing -> Left { missing: [ keyName ], invalid: [] }
        Just foreignVal ->
          let
            valueStr = unsafeCoerce foreignVal :: String
          in
            case FO.parseParam valueStr of
              Nothing -> Left { missing: [], invalid: [ keyName ] }
              Just value -> Right value
      restResult = parseRequiredQuery (Proxy :: Proxy tail) qps
    in
      case valueResult, restResult of
        Right value, Right rest -> Right (Record.insert key value rest)
        Left err1, Left err2 -> Left
          { missing: err1.missing <> err2.missing
          , invalid: err1.invalid <> err2.invalid
          }
        Left err, Right _ -> Left err
        Right _, Left err -> Left err

-- | Parse optional query parameters
-- | Note: The row type specifies base types (Int, String), but the instances
-- | produce Maybe-wrapped values
class ParseOptionalQuery (rl :: RowList Type) (rIn :: Row Type) (rOut :: Row Type) | rl -> rIn rOut where
  parseOptionalQuery :: Proxy rl -> Object Foreign -> Record rOut

instance ParseOptionalQuery RL.Nil () () where
  parseOptionalQuery _ _ = {}

instance
  ( IsSymbol name
  , FO.ParseParam ty
  , ParseOptionalQuery tail tailRowIn tailRowOut
  , Cons name ty tailRowIn rIn
  , Cons name (Maybe ty) tailRowOut rOut
  , Lacks name tailRowOut
  ) =>
  ParseOptionalQuery (RL.Cons name ty tail) rIn rOut where
  parseOptionalQuery _ qps =
    let
      key = Proxy :: Proxy name
      keyName = reflectSymbol key
      value = do
        foreignVal <- Object.lookup keyName qps
        let valueStr = unsafeCoerce foreignVal :: String
        FO.parseParam valueStr
      rest = parseOptionalQuery (Proxy :: Proxy tail) qps
    in
      Record.insert key value rest

-- | Parse required headers
class ParseRequiredHeaders (rl :: RowList Type) (r :: Row Type) | rl -> r where
  parseRequiredHeaders :: Proxy rl -> Object String -> Either FO.HeaderErrors (Record r)

instance ParseRequiredHeaders RL.Nil () where
  parseRequiredHeaders _ _ = Right {}

instance
  ( IsSymbol name
  , ParseRequiredHeaders tail tailRow
  , Cons name String tailRow r
  , Lacks name tailRow
  ) =>
  ParseRequiredHeaders (RL.Cons name String tail) r where
  parseRequiredHeaders _ hdrs =
    let
      key = Proxy :: Proxy name
      keyName = reflectSymbol key
      valueResult = case Object.lookup keyName hdrs of
        Nothing -> Left { missing: [ keyName ], invalid: [] }
        Just value -> Right value
      restResult = parseRequiredHeaders (Proxy :: Proxy tail) hdrs
    in
      case valueResult, restResult of
        Right value, Right rest -> Right (Record.insert key value rest)
        Left err1, Left err2 -> Left
          { missing: err1.missing <> err2.missing
          , invalid: err1.invalid <> err2.invalid
          }
        Left err, Right _ -> Left err
        Right _, Left err -> Left err

-- | Parse optional headers
-- | Note: The row type specifies String, but the instances produce Maybe String values
class ParseOptionalHeaders (rl :: RowList Type) (rIn :: Row Type) (rOut :: Row Type) | rl -> rIn rOut where
  parseOptionalHeaders :: Proxy rl -> Object String -> Record rOut

instance ParseOptionalHeaders RL.Nil () () where
  parseOptionalHeaders _ _ = {}

instance
  ( IsSymbol name
  , ParseOptionalHeaders tail tailRowIn tailRowOut
  , Cons name String tailRowIn rIn
  , Cons name (Maybe String) tailRowOut rOut
  , Lacks name tailRowOut
  ) =>
  ParseOptionalHeaders (RL.Cons name String tail) rIn rOut where
  parseOptionalHeaders _ hdrs =
    let
      key = Proxy :: Proxy name
      keyName = reflectSymbol key
      value = Object.lookup keyName hdrs
      rest = parseOptionalHeaders (Proxy :: Proxy tail) hdrs
    in
      Record.insert key value rest

--------------------------------------------------------------------------------
-- Endpoint Handler Execution
--------------------------------------------------------------------------------

-- | Execute an endpoint handler with automatic parsing and response sending
-- |
-- | Example:
-- |   FO.postOm (RouteURL "/users/:id") (handleEndpoint userEndpoint handler) app
-- |   
-- |   where
-- |     handler { path: User userId, requiredQuery: { page }, body, requiredHeaders: { auth } } = do
-- |       -- All fields are type-safe and parsed!
-- |       user <- createUser userId body
-- |       pure user  -- Framework handles serialization and sending!
handleEndpoint
  :: forall path reqQuery reqQueryRow optQuery optQueryRow optQueryOut body reqHeaders reqHeadersRow optHeaders optHeadersRow optHeadersOut response ctx err
   . RowToList reqQuery reqQueryRow
  => ParseRequiredQuery reqQueryRow reqQuery
  => RowToList optQuery optQueryRow
  => ParseOptionalQuery optQueryRow optQuery optQueryOut
  => RowToList reqHeaders reqHeadersRow
  => ParseRequiredHeaders reqHeadersRow reqHeaders
  => RowToList optHeaders optHeadersRow
  => ParseOptionalHeaders optHeadersRow optHeaders optHeadersOut
  => ReadForeign body
  => WriteForeign response
  => Endpoint path reqQuery optQuery body reqHeaders optHeaders response
  -> EndpointHandler path reqQuery optQueryOut body reqHeaders optHeadersOut response ctx err
  -> FastifyReply
  -> Om.Om { httpRequest :: FO.RequestContext | ctx } err Unit
handleEndpoint (Endpoint spec) handler reply = do
  -- Get raw request data
  reqCtx <- FO.httpRequest
  let
    queryObj = reqCtx.query
    headersObj = reqCtx.headers

  -- Parse URL path
  url <- FO.requestUrl
  case parse spec.pathCodec (unwrapUrl url) of
    Left _ -> do
      void $ liftEffect $ F.status (StatusCode 404) reply
      void $ FO.send (unsafeToForeign "Not found") reply

    Right path -> do
      -- Parse required query params
      case parseRequiredQuery (Proxy :: Proxy reqQueryRow) queryObj of
        Left errs -> do
          void $ liftEffect $ F.status (StatusCode 400) reply
          void $ FO.send (unsafeToForeign ("Missing/invalid query params: " <> show errs.missing <> " " <> show errs.invalid)) reply

        Right requiredQuery -> do
          -- Parse optional query params (never fails)
          let optionalQuery = parseOptionalQuery (Proxy :: Proxy optQueryRow) queryObj

          -- Parse required headers
          case parseRequiredHeaders (Proxy :: Proxy reqHeadersRow) headersObj of
            Left errs -> do
              void $ liftEffect $ F.status (StatusCode 400) reply
              void $ FO.send (unsafeToForeign ("Missing headers: " <> show errs.missing)) reply

            Right requiredHeaders -> do
              -- Parse optional headers (never fails)
              let optionalHeaders = parseOptionalHeaders (Proxy :: Proxy optHeadersRow) headersObj

              -- Parse body using yoga-json (Fastify already parsed JSON -> Foreign)
              bodyResult <- case reqCtx.body of
                Nothing -> do
                  void $ liftEffect $ F.status (StatusCode 400) reply
                  void $ FO.send (unsafeToForeign "Request body is required") reply
                  pure Nothing
                Just foreignBody ->
                  case read foreignBody of
                    Left parseError -> do
                      void $ liftEffect $ F.status (StatusCode 400) reply
                      void $ FO.send (unsafeToForeign ("Invalid request body: " <> show parseError)) reply
                      pure Nothing
                    Right parsed -> pure (Just parsed)

              case bodyResult of
                Nothing -> pure unit
                Just body -> do
                  -- Call handler with fully parsed data!
                  let
                    endpointData =
                      { path
                      , requiredQuery
                      , optionalQuery
                      , body
                      , requiredHeaders
                      , optionalHeaders
                      }

                  -- Handler returns response value - we serialize and send it
                  responseValue <- handler endpointData

                  -- Use yoga-json to encode response
                  let encodedResponse = writeImpl responseValue
                  void $ liftEffect $ F.status (StatusCode 200) reply
                  void $ FO.send encodedResponse reply
  where
  unwrapUrl (RouteURL s) = s
