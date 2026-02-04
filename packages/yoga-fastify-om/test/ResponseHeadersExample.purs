module Test.Yoga.Fastify.Om.ResponseHeadersExample where

{-
  Endpoint API - Tests as Documentation
  ======================================

  EndpointHandler has 6 type parameters:
  
  EndpointHandler path request responseHeaders response ctx err
                  ^^^^  ^^^^^^^  ^^^^^^^^^^^^^^^  ^^^^^^^^ ^^^ ^^^
                  |     |        |                |        |   error type
                  |     |        |                |        app context
                  |     |        |                response body type
                  |     |        OUTGOING response headers (what YOU send back)
                  |     INCOMING request (query/headers/body) - Union constraint!
                  path type (route matching)

  Examples show:
  1. Minimal request (just body) - Union allows omitting query/headers
  2. Request with query params - Union allows omitting headers  
  3. Request with headers - Union allows omitting query
  4. Full request (all fields)
  5. Different response headers
-}

import Prelude
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint as E
import Yoga.Fastify.Om.RequestBody (RequestBody(..))
import Yoga.JSON (class ReadForeign, class WriteForeign)

-- ============================================================================
-- API Types
-- ============================================================================

type User =
  { id :: Int
  , name :: String
  , email :: String
  }

type CreateUserReq =
  { name :: String
  , email :: String
  }

data ApiRoute = CreateUser | GetUser

derive instance Generic ApiRoute _
derive instance Eq ApiRoute

apiRoute :: RouteDuplex' ApiRoute
apiRoute = RD.root $ RG.sum
  { "CreateUser": "users" / RG.noArgs
  , "GetUser": "users" / "1" / RG.noArgs
  }

type AppContext = ()

-- Example 1: Minimal request - just body (Union allows omitting query/headers)
type CreateUserRequest = { body :: RequestBody CreateUserReq }

createUserHandler :: E.EndpointHandler ApiRoute CreateUserRequest () User AppContext ()
createUserHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> pure
      { status: E.StatusCode 201
      , headers: {}
      , body: { id: 1, name, email }
      }
    _, _ -> pure
      { status: E.StatusCode 400
      , headers: {}
      , body: { id: 0, name: "error", email: "error" }
      }

-- Example 2: Request with query params (Union allows omitting headers)
type ListUsersRequest =
  { query :: Record (page :: Int, limit :: Int)
  , body :: RequestBody Unit
  }

listUsersHandler :: E.EndpointHandler ApiRoute ListUsersRequest () (Array User) AppContext ()
listUsersHandler { path, request } = do
  let { page, limit } = request.query
  pure
    { status: E.StatusCode 200
    , headers: {}
    , body: [ { id: 1, name: "Alice", email: "alice@example.com" }
            , { id: 2, name: "Bob", email: "bob@example.com" }
            ]
    }

-- Example 3: Request with incoming headers (Union allows omitting query)
type AuthenticatedCreateRequest =
  { headers :: Record (authorization :: String)
  , body :: RequestBody CreateUserReq
  }

authenticatedCreateHandler
  :: E.EndpointHandler
       ApiRoute
       AuthenticatedCreateRequest
       ( "Location" :: String, "X-Request-Id" :: String )  -- OUTGOING response headers
       User
       AppContext
       ()
authenticatedCreateHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      let authToken = request.headers.authorization  -- INCOMING request header
      let userId = 123
      pure
        { status: E.StatusCode 201
        , headers:  -- OUTGOING response headers
            { "Location": "/users/" <> show userId
            , "X-Request-Id": "req-abc-123"
            }
        , body: { id: userId, name, email }
        }
    _, _ -> pure
      { status: E.StatusCode 400
      , headers: { "Location": "", "X-Request-Id": "req-error" }
      , body: { id: 0, name: "error", email: "error" }
      }

-- ============================================================================
-- Example 4: Full Request - Query + Headers + Body (Union constraint!)
-- ============================================================================
-- This request specifies ALL fields - nothing omitted

type FullCreateRequest =
  { query :: Record (dryRun :: Maybe Boolean)     -- Query params
  , headers :: Record (authorization :: String)   -- Request headers
  , body :: RequestBody CreateUserReq             -- Body
  }

fullCreateHandler
  :: E.EndpointHandler
       ApiRoute                         -- path type
       FullCreateRequest                -- request with ALL fields!
       ( "Location" :: String           -- many response headers
       , "X-Request-Id" :: String
       , "Content-Type" :: String
       , "Cache-Control" :: String
       )
       User                             -- response body
       AppContext
       ()
fullCreateHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      -- Access ALL request fields!
      let _ = request.headers.authorization  -- Request header
      let _ = request.query.dryRun           -- Query param
      let userId = 123
      pure
        { status: E.StatusCode 201
        , headers:
            { "Location": "/users/" <> show userId
            , "X-Request-Id": "req-abc-123"
            , "Content-Type": "application/json; charset=utf-8"
            , "Cache-Control": "no-cache"
            }
        , body: { id: userId, name, email }
        }
    _, _ -> pure
      { status: E.StatusCode 400
      , headers:
          { "Location": ""
          , "X-Request-Id": "req-error"
          , "Content-Type": "application/json"
          , "Cache-Control": "no-cache"
          }
      , body: { id: 0, name: "error", email: "error" }
      }

-- Example 5: Different status codes
getUserHandler :: E.EndpointHandler ApiRoute { body :: RequestBody Unit } () User AppContext ()
getUserHandler { path } =
  case path of
    GetUser -> pure
      { status: E.StatusCode 200
      , headers: {}
      , body: { id: 1, name: "Alice", email: "alice@example.com" }
      }
    _ -> pure
      { status: E.StatusCode 400
      , headers: {}
      , body: { id: 0, name: "Bad Request", email: "" }
      }
