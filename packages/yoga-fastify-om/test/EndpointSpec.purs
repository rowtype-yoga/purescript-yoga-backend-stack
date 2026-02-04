module Test.Yoga.Fastify.Om.EndpointSpec where

import Prelude

import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Fastify as F
import Yoga.Fastify.Om as FO
import Yoga.Fastify.Om.Endpoint as E
import Yoga.JSON (class ReadForeign, class WriteForeign)
import Yoga.Om as Om

-- | Example request body type
type CreateUserRequest =
  { name :: String
  , email :: String
  , age :: Int
  }

-- | Example response type
type UserResponse =
  { id :: Int
  , name :: String
  , email :: String
  , age :: Int
  , verified :: Boolean
  }

-- | Path route for user endpoints
data UserRoute
  = Users -- GET /users (list)
  | CreateUser -- POST /users (create)
  | UserById Int -- GET /users/:id
  | UpdateUser Int -- PUT /users/:id

derive instance Generic UserRoute _
derive instance Eq UserRoute

instance Show UserRoute where
  show Users = "Users"
  show CreateUser = "CreateUser"
  show (UserById id) = "UserById " <> show id
  show (UpdateUser id) = "UpdateUser " <> show id

-- | routing-duplex codec for user routes
userRoute :: RouteDuplex' UserRoute
userRoute = RD.root $ RG.sum
  { "Users": "users" / RG.noArgs
  , "CreateUser": "users" / RG.noArgs
  , "UserById": "users" / RD.int RD.segment
  , "UpdateUser": "users" / RD.int RD.segment
  }

-- | Application context (empty row for this example)
type AppContext = ()

-- ============================================================================
-- EXAMPLE 1: POST with Body, Query Params, and Headers
-- ============================================================================

createUserEndpoint
  :: E.Endpoint
       UserRoute -- path
       (notify :: Boolean) -- required query: ?notify=true
       (source :: String) -- optional query: ?source=web
       CreateUserRequest -- body (JSON)
       (authorization :: String) -- required header
       (xRequestId :: String) -- optional header: x-request-id
       UserResponse -- response (JSON)
createUserEndpoint = E.endpoint
  { pathCodec: userRoute
  , requiredQuery: Proxy :: Proxy (notify :: Boolean)
  , optionalQuery: Proxy :: Proxy (source :: String)
  , bodyType: Proxy :: Proxy CreateUserRequest
  , requiredHeaders: Proxy :: Proxy (authorization :: String)
  , optionalHeaders: Proxy :: Proxy (xRequestId :: String)
  , responseType: Proxy :: Proxy UserResponse
  }

-- | Handler for creating users
-- | Shows how all data is automatically parsed and available!
createUserHandler
  :: E.EndpointHandler
       UserRoute
       (notify :: Boolean)
       (source :: Maybe String)
       CreateUserRequest
       (authorization :: String)
       (xRequestId :: Maybe String)
       UserResponse
       AppContext
       ()
createUserHandler req =
  case req.path of
    CreateUser -> do
      -- Extract all the parsed, typed data!
      let
        { notify } = req.requiredQuery
        { source } = req.optionalQuery
        { name, email, age } = req.body
        { authorization } = req.requiredHeaders
        { xRequestId } = req.optionalHeaders

      -- Log what we received (in real app, you'd verify auth, save to DB, etc.)
      let
        userId = 42
        verified = notify && authorization == "Bearer secret-token"
        actualSource = case source of
          Just s -> s
          Nothing -> "unknown"
        requestId = case xRequestId of
          Just rid -> rid
          Nothing -> "no-request-id"

      -- Return the response - framework handles JSON encoding!
      pure
        { id: userId
        , name: name
        , email: email
        , age: age
        , verified: verified
        }
    _ -> pure { id: 0, name: "", email: "", age: 0, verified: false } -- Shouldn't happen

-- ============================================================================
-- EXAMPLE 2: GET with Path Params and Optional Query
-- ============================================================================

getUserEndpoint
  :: E.Endpoint
       UserRoute -- path with param
       () -- no required query
       (includeDeleted :: Boolean) -- optional query: ?includeDeleted=true
       Unit -- no body
       () -- no required headers
       () -- no optional headers
       UserResponse -- response (JSON)
getUserEndpoint = E.endpoint
  { pathCodec: userRoute
  , requiredQuery: Proxy :: Proxy ()
  , optionalQuery: Proxy :: Proxy (includeDeleted :: Boolean)
  , bodyType: Proxy :: Proxy Unit
  , requiredHeaders: Proxy :: Proxy ()
  , optionalHeaders: Proxy :: Proxy ()
  , responseType: Proxy :: Proxy UserResponse
  }

-- | Handler for getting a single user
getUserHandler
  :: E.EndpointHandler
       UserRoute
       ()
       (includeDeleted :: Maybe Boolean)
       Unit
       ()
       ()
       UserResponse
       AppContext
       ()
getUserHandler req =
  case req.path of
    UserById userId -> do
      let { includeDeleted } = req.optionalQuery

      -- In real app, fetch from database
      let
        shouldIncludeDeleted = case includeDeleted of
          Just true -> true
          _ -> false

      -- Return mock user
      pure
        { id: userId
        , name: "John Doe"
        , email: "john@example.com"
        , age: 30
        , verified: not shouldIncludeDeleted -- Just for demo
        }
    _ -> pure { id: 0, name: "", email: "", age: 0, verified: false } -- Shouldn't happen

-- ============================================================================
-- EXAMPLE 3: Simple GET List (minimal example)
-- ============================================================================

listUsersEndpoint
  :: E.Endpoint
       UserRoute
       ()
       (page :: Int, limit :: Int)
       Unit
       ()
       ()
       (Array UserResponse)
listUsersEndpoint = E.endpoint
  { pathCodec: userRoute
  , requiredQuery: Proxy :: Proxy ()
  , optionalQuery: Proxy :: Proxy (page :: Int, limit :: Int)
  , bodyType: Proxy :: Proxy Unit
  , requiredHeaders: Proxy :: Proxy ()
  , optionalHeaders: Proxy :: Proxy ()
  , responseType: Proxy :: Proxy (Array UserResponse)
  }

-- | Handler for listing users
listUsersHandler
  :: E.EndpointHandler
       UserRoute
       ()
       (page :: Maybe Int, limit :: Maybe Int)
       Unit
       ()
       ()
       (Array UserResponse)
       AppContext
       ()
listUsersHandler req =
  case req.path of
    Users -> do
      let
        { page, limit } = req.optionalQuery

        -- Default pagination
        pageNum = case page of
          Just p -> p
          Nothing -> 1
        limitNum = case limit of
          Just l -> l
          Nothing -> 10

      -- Return mock users array
      pure
        [ { id: 1, name: "Alice", email: "alice@example.com", age: 25, verified: true }
        , { id: 2, name: "Bob", email: "bob@example.com", age: 35, verified: false }
        ]
    _ -> pure [] -- Shouldn't happen due to routing, but compiler needs this

-- ============================================================================
-- Tests
-- ============================================================================

spec :: Spec Unit
spec = do
  describe "Tapir-Style Typed Endpoints" do

    it "demonstrates the endpoint type system" do
      -- The endpoint specification itself is type-checked at compile time!
      -- If any types don't match, it won't compile.

      -- This test just verifies the types compile correctly
      let _endpointExists = createUserEndpoint
      true `shouldEqual` true

    it "demonstrates handler type safety" do
      -- The handler is type-checked against the endpoint spec
      -- If handler tries to access fields not in the spec, it won't compile!

      let _handlerExists = createUserHandler
      true `shouldEqual` true

    it "shows the complete workflow" do
      -- In a real integration test, you would:
      -- 1. Start a Fastify server
      -- 2. Register the endpoint: FO.postOm (RouteURL "/users") (E.handleEndpoint createUserEndpoint createUserHandler) app
      -- 3. Make HTTP request with curl or fetch
      -- 4. Verify response

      -- For this spec, we just verify types compile
      let workflow = "Endpoint -> Handler -> handleEndpoint -> Fastify"
      workflow `shouldEqual` "Endpoint -> Handler -> handleEndpoint -> Fastify"

    describe "Type Safety Examples" do

      it "ensures all required fields are present in endpoint spec" do
        -- ✅ Compiles: All fields specified
        let
          _valid = E.endpoint
            { pathCodec: userRoute
            , requiredQuery: Proxy :: Proxy ()
            , optionalQuery: Proxy :: Proxy ()
            , bodyType: Proxy :: Proxy Unit
            , requiredHeaders: Proxy :: Proxy ()
            , optionalHeaders: Proxy :: Proxy ()
            , responseType: Proxy :: Proxy UserResponse
            }

        -- ❌ Won't compile if you forget a field:
        -- let invalid = E.endpoint { pathCodec: userRoute }

        true `shouldEqual` true

      it "ensures handler signature matches endpoint" do
        -- The handler MUST match the endpoint's type signature
        -- Wrong types = compile error!

        -- ✅ This compiles:
        let
          correctHandler :: E.EndpointHandler UserRoute () () Unit () () UserResponse AppContext ()
          correctHandler _ = pure { id: 1, name: "Test", email: "test@example.com", age: 25, verified: true }

        -- ❌ This won't compile (wrong response type):
        -- let wrongHandler :: EndpointHandler UserRoute () () Unit () () String AppContext ()
        -- wrongHandler _ = pure "wrong type"

        true `shouldEqual` true

      it "demonstrates accessing parsed data is type-safe" do
        -- Inside handler, all fields are typed and autocomplete works!
        let
          exampleHandler :: E.EndpointHandler UserRoute () () Unit () () UserResponse AppContext ()
          exampleHandler req = case req.path of
            Users -> do
              let
                _query = req.requiredQuery -- ✅ Type: {}
                _body = req.body -- ✅ Type: Unit

              -- ❌ Won't compile: req.nonExistentField

              pure { id: 1, name: "Test", email: "test@example.com", age: 25, verified: true }
            _ -> pure { id: 0, name: "", email: "", age: 0, verified: false }

        true `shouldEqual` true

    describe "Real-World Patterns" do

      it "shows POST with full validation" do
        -- This is what your real handlers look like!
        let
          realWorldHandler
            :: E.EndpointHandler
                 UserRoute
                 (notify :: Boolean)
                 (source :: Maybe String)
                 CreateUserRequest
                 (authorization :: String)
                 (xRequestId :: Maybe String)
                 UserResponse
                 AppContext
                 ()
          realWorldHandler { path, requiredQuery, optionalQuery, body, requiredHeaders, optionalHeaders } = do
            -- All fields automatically parsed and typed!
            let
              { notify } = requiredQuery
              { source } = optionalQuery
              { name, email, age } = body
              { authorization } = requiredHeaders

            -- Business logic here (validate, save to DB, etc)

            pure { id: 42, name, email, age, verified: notify }

        true `shouldEqual` true

      it "shows simple GET with minimal config" do
        -- Minimal endpoint for simple GET
        let
          simpleEndpoint = E.endpoint
            { pathCodec: userRoute
            , requiredQuery: Proxy :: Proxy ()
            , optionalQuery: Proxy :: Proxy ()
            , bodyType: Proxy :: Proxy Unit
            , requiredHeaders: Proxy :: Proxy ()
            , optionalHeaders: Proxy :: Proxy ()
            , responseType: Proxy :: Proxy (Array UserResponse)
            }

        let
          simpleHandler :: E.EndpointHandler UserRoute () () Unit () () (Array UserResponse) AppContext ()
          simpleHandler _ = pure []

        true `shouldEqual` true
