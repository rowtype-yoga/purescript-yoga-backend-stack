module Test.Yoga.Fastify.Om.ResponseHeadersExample where

import Prelude
import Data.Generic.Rep (class Generic)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint2 as E2
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

createUserEndpoint :: E2.Endpoint2 ApiRoute CreateUserRequest User
createUserEndpoint = E2.endpoint2 apiRoute (Proxy :: _ CreateUserRequest) (Proxy :: _ User)

createUserHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserRequest
       ()  -- No custom headers
       User
       AppContext
       ()
createUserHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> pure
      { status: E2.StatusCode 201
      , headers: {}  -- Empty headers record
      , body: { id: 1, name, email }
      }
    _, _ -> pure
      { status: E2.StatusCode 400
      , headers: {}
      , body: { id: 0, name: "error", email: "error" }
      }

-- ============================================================================
-- Example 2: Response with Custom Headers (Homogeneous Record)
-- ============================================================================

createUserWithHeadersHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserRequest
       ( location :: String
       , xRequestId :: String
       )  -- Homogeneous headers record
       User
       AppContext
       ()
createUserWithHeadersHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      let userId = 123
      pure
        { status: E2.StatusCode 201
        , headers:
            { location: "/users/" <> show userId
            , xRequestId: "req-abc-123"
            }
        , body: { id: userId, name, email }
        }
    _, _ -> pure
      { status: E2.StatusCode 400
      , headers:
          { location: ""
          , xRequestId: "req-error"
          }
      , body: { id: 0, name: "error", email: "error" }
      }

-- ============================================================================
-- Example 3: Response with Many Headers
-- ============================================================================

createUserWithManyHeadersHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserRequest
       ( location :: String
       , xRequestId :: String
       , contentType :: String
       , cacheControl :: String
       )
       User
       AppContext
       ()
createUserWithManyHeadersHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      let userId = 123
      pure
        { status: E2.StatusCode 201
        , headers:
            { location: "/users/" <> show userId
            , xRequestId: "req-abc-123"
            , contentType: "application/json; charset=utf-8"
            , cacheControl: "no-cache"
            }
        , body: { id: userId, name, email }
        }
    _, _ -> pure
      { status: E2.StatusCode 400
      , headers:
          { location: ""
          , xRequestId: "req-error"
          , contentType: "application/json"
          , cacheControl: "no-cache"
          }
      , body: { id: 0, name: "error", email: "error" }
      }

-- ============================================================================
-- Example 4: Different Status Codes
-- ============================================================================

getUserHandler
  :: E2.EndpointHandler2
       ApiRoute
       { body :: RequestBody Unit }
       ()
       User
       AppContext
       ()
getUserHandler { path, request } =
  case path of
    GetUser ->
      -- Found
      pure
        { status: E2.StatusCode 200
        , headers: {}
        , body: { id: 1, name: "Alice", email: "alice@example.com" }
        }
    _ -> pure
      { status: E2.StatusCode 400
      , headers: {}
      , body: { id: 0, name: "Bad Request", email: "" }
      }
