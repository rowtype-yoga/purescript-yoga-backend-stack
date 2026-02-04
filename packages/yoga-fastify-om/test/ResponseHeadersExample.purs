module Test.Yoga.Fastify.Om.ResponseHeadersExample where

{-
  Endpoint Response API Examples
  ==============================

  This test file demonstrates the Endpoint API with:
  - Type-safe response headers (homogeneous records, all String values)
  - Real HTTP header names using quotes: { "Content-Type": "...", "X-Request-Id": "..." }
  - Status code control
  - Field omission via Union constraint

  Key Features:
  1. Handlers return { status, headers, body }
  2. Headers are homogeneous records (all fields String type)
  3. Use actual HTTP header names with quotes (no conversion)
  4. Empty headers record {} for no custom headers
  5. Union constraint allows omitting query/headers/body fields

  Examples below show:
  - Simple response (no custom headers)
  - Response with custom headers
  - Response with many headers
  - Different status codes
-}

import Prelude
import Data.Generic.Rep (class Generic)
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

-- ============================================================================
-- Example 1: Simple Response - No Custom Headers
-- ============================================================================

type CreateUserRequest = { body :: RequestBody CreateUserReq }

createUserEndpoint :: E.Endpoint ApiRoute CreateUserRequest User
createUserEndpoint = E.endpoint apiRoute (Proxy :: _ CreateUserRequest) (Proxy :: _ User)

createUserHandler
  :: E.EndpointHandler
       ApiRoute
       CreateUserRequest
       () -- No custom headers
       User
       AppContext
       ()
createUserHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> pure
      { status: E.StatusCode 201
      , headers: {} -- Empty headers record
      , body: { id: 1, name, email }
      }
    _, _ -> pure
      { status: E.StatusCode 400
      , headers: {}
      , body: { id: 0, name: "error", email: "error" }
      }

-- ============================================================================
-- Example 2: Response with Custom Headers (Real HTTP Header Names!)
-- ============================================================================

createUserWithHeadersHandler
  :: E.EndpointHandler
       ApiRoute
       CreateUserRequest
       ( "Location" :: String
       , "X-Request-Id" :: String
       ) -- Real HTTP header names with quotes!
       User
       AppContext
       ()
createUserWithHeadersHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      let userId = 123
      pure
        { status: E.StatusCode 201
        , headers:
            { "Location": "/users/" <> show userId
            , "X-Request-Id": "req-abc-123"
            }
        , body: { id: userId, name, email }
        }
    _, _ -> pure
      { status: E.StatusCode 400
      , headers:
          { "Location": ""
          , "X-Request-Id": "req-error"
          }
      , body: { id: 0, name: "error", email: "error" }
      }

-- ============================================================================
-- Example 3: Response with Many Headers
-- ============================================================================

createUserWithManyHeadersHandler
  :: E.EndpointHandler
       ApiRoute
       CreateUserRequest
       ( "Location" :: String
       , "X-Request-Id" :: String
       , "Content-Type" :: String
       , "Cache-Control" :: String
       )
       User
       AppContext
       ()
createUserWithManyHeadersHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
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

-- ============================================================================
-- Example 4: Different Status Codes
-- ============================================================================

getUserHandler
  :: E.EndpointHandler
       ApiRoute
       { body :: RequestBody Unit }
       ()
       User
       AppContext
       ()
getUserHandler { path } =
  case path of
    GetUser ->
      -- Found
      pure
        { status: E.StatusCode 200
        , headers: {}
        , body: { id: 1, name: "Alice", email: "alice@example.com" }
        }
    _ -> pure
      { status: E.StatusCode 400
      , headers: {}
      , body: { id: 0, name: "Bad Request", email: "" }
      }
