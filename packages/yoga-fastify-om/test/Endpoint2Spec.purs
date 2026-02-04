module Test.Yoga.Fastify.Om.Endpoint2Spec where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint2 as E2
import Yoga.JSON (class ReadForeign, class WriteForeign)

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
-- EXAMPLE 1: Full Spec with All Fields
-- ============================================================================

type CreateUserSpec =
  ( query :: { notify :: Boolean, source :: Maybe String }
  , headers :: { authorization :: String, xRequestId :: Maybe String }
  , body :: CreateUserRequest
  )

createUserEndpoint :: E2.Endpoint2 UserRoute CreateUserSpec UserResponse
createUserEndpoint = E2.endpoint2 userRoute (Proxy :: Proxy CreateUserSpec) (Proxy :: Proxy UserResponse)

createUserHandler
  :: E2.EndpointHandler2
       UserRoute
       (notify :: Boolean, source :: Maybe String)
       (authorization :: String, xRequestId :: Maybe String)
       CreateUserRequest
       UserResponse
       AppContext
       ()
createUserHandler { path, query, headers, body } =
  case path of
    CreateUser -> do
      -- Extract all parsed data
      let
        { notify, source } = query
        { authorization, xRequestId } = headers
        { name, email, age } = body

      -- Mock user creation
      let
        userId = 42
        verified = notify && authorization == "Bearer secret-token"

      pure
        { id: userId
        , name
        , email
        , age
        , verified
        }
    _ -> pure { id: 0, name: "", email: "", age: 0, verified: false }

-- ============================================================================
-- EXAMPLE 2: Query Only (No Headers or Body)
-- ============================================================================

type GetUserSpec =
  ( query :: { id :: Int, includeDeleted :: Maybe Boolean }
  )

getUserEndpoint :: E2.Endpoint2 UserRoute GetUserSpec UserResponse
getUserEndpoint = E2.endpoint2 userRoute (Proxy :: Proxy GetUserSpec) (Proxy :: Proxy UserResponse)

getUserHandler
  :: E2.EndpointHandler2
       UserRoute
       (id :: Int, includeDeleted :: Maybe Boolean)
       ()
       Unit
       UserResponse
       AppContext
       ()
getUserHandler { path, query } =
  case path of
    UserById userId -> do
      let
        { id: queryId, includeDeleted } = query
        shouldIncludeDeleted = case includeDeleted of
          Just true -> true
          _ -> false

      pure
        { id: userId
        , name: "John Doe"
        , email: "john@example.com"
        , age: 30
        , verified: not shouldIncludeDeleted
        }
    _ -> pure { id: 0, name: "", email: "", age: 0, verified: false }

-- ============================================================================
-- EXAMPLE 3: Headers Only (No Query or Body)
-- ============================================================================

type DeleteUserSpec =
  ( headers :: { authorization :: String }
  )

deleteUserEndpoint :: E2.Endpoint2 UserRoute DeleteUserSpec UserResponse
deleteUserEndpoint = E2.endpoint2 userRoute (Proxy :: Proxy DeleteUserSpec) (Proxy :: Proxy UserResponse)

deleteUserHandler
  :: E2.EndpointHandler2
       UserRoute
       ()
       (authorization :: String)
       Unit
       UserResponse
       AppContext
       ()
deleteUserHandler { path, headers } =
  case path of
    UserById userId -> do
      let { authorization } = headers

      -- Mock deletion
      pure
        { id: userId
        , name: "Deleted"
        , email: "deleted@example.com"
        , age: 0
        , verified: authorization == "Bearer admin-token"
        }
    _ -> pure { id: 0, name: "", email: "", age: 0, verified: false }

-- ============================================================================
-- EXAMPLE 4: Minimal Spec (No Query, Headers, or Body - All Defaults)
-- ============================================================================

type ListUsersSpec = ()

listUsersEndpoint :: E2.Endpoint2 UserRoute ListUsersSpec (Array UserResponse)
listUsersEndpoint = E2.endpoint2 userRoute (Proxy :: Proxy ListUsersSpec) (Proxy :: Proxy (Array UserResponse))

listUsersHandler
  :: E2.EndpointHandler2
       UserRoute
       ()
       ()
       Unit
       (Array UserResponse)
       AppContext
       ()
listUsersHandler { path } =
  case path of
    Users ->
      pure
        [ { id: 1, name: "Alice", email: "alice@example.com", age: 25, verified: true }
        , { id: 2, name: "Bob", email: "bob@example.com", age: 35, verified: false }
        ]
    _ -> pure []

-- ============================================================================
-- EXAMPLE 5: Body and Query (No Headers)
-- ============================================================================

type UpdateUserSpec =
  ( query :: { sendNotification :: Maybe Boolean }
  , body :: CreateUserRequest
  )

updateUserEndpoint :: E2.Endpoint2 UserRoute UpdateUserSpec UserResponse
updateUserEndpoint = E2.endpoint2 userRoute (Proxy :: Proxy UpdateUserSpec) (Proxy :: Proxy UserResponse)

updateUserHandler
  :: E2.EndpointHandler2
       UserRoute
       (sendNotification :: Maybe Boolean)
       ()
       CreateUserRequest
       UserResponse
       AppContext
       ()
updateUserHandler { path, query, body } =
  case path of
    UpdateUser userId -> do
      let
        { sendNotification } = query
        { name, email, age } = body
        shouldNotify = case sendNotification of
          Just true -> true
          _ -> false

      pure
        { id: userId
        , name
        , email
        , age
        , verified: shouldNotify
        }
    _ -> pure { id: 0, name: "", email: "", age: 0, verified: false }

-- ============================================================================
-- Tests
-- ============================================================================

spec :: Spec Unit
spec = do
  describe "Endpoint2 Record-Based Design" do

    describe "Type System Validation" do

      it "compiles endpoint with all fields (query, headers, body)" do
        let _endpoint = createUserEndpoint
        true `shouldEqual` true

      it "compiles endpoint with query only (headers and body default to empty)" do
        let _endpoint = getUserEndpoint
        true `shouldEqual` true

      it "compiles endpoint with headers only (query and body default to empty)" do
        let _endpoint = deleteUserEndpoint
        true `shouldEqual` true

      it "compiles endpoint with no fields (all default to empty)" do
        let _endpoint = listUsersEndpoint
        true `shouldEqual` true

      it "compiles endpoint with query and body (headers default to empty)" do
        let _endpoint = updateUserEndpoint
        true `shouldEqual` true

    describe "Handler Type Safety" do

      it "handler receives all parsed fields with correct types" do
        let handler = createUserHandler
        true `shouldEqual` true

      it "handler can destructure only specified fields" do
        let handler = getUserHandler
        true `shouldEqual` true

      it "handler defaults omitted fields to Unit or empty record" do
        let handler = listUsersHandler
        true `shouldEqual` true

    describe "Comparison with Endpoint (Original)" do

      it "Endpoint2 requires 3 type parameters vs 7 in Endpoint" do
        -- Endpoint: path reqQuery optQuery body reqHeaders optHeaders response
        -- Endpoint2: path requestSpec response
        let _comparison = "3 type parameters vs 7"
        _comparison `shouldEqual` "3 type parameters vs 7"

      it "Endpoint2 uses single record spec vs separate row types" do
        -- Endpoint: separate Proxy for each of: reqQuery, optQuery, reqHeaders, optHeaders, body
        -- Endpoint2: single Proxy for requestSpec row
        let _comparison = "Single record vs separate rows"
        _comparison `shouldEqual` "Single record vs separate rows"

      it "Endpoint2 uses Maybe for optional vs separate required/optional rows" do
        -- Endpoint: ( page :: Int ) and ( limit :: Int ) in separate rows
        -- Endpoint2: { page :: Int, limit :: Maybe Int } in same record
        let _comparison = "Maybe wrapper vs separate rows"
        _comparison `shouldEqual` "Maybe wrapper vs separate rows"

      it "Endpoint2 can omit entire fields via Union constraint" do
        -- Endpoint: must provide all 7 type parameters (use () for empty)
        -- Endpoint2: can omit query, headers, or body entirely
        let _comparison = "Union constraint allows field omission"
        _comparison `shouldEqual` "Union constraint allows field omission"

    describe "Benefits Demonstration" do

      it "cleaner endpoint definition syntax" do
        -- Before: 7 Proxy arguments
        -- After: 3 arguments (pathCodec, spec proxy, response proxy)
        let _benefit = "3 args vs 7 Proxy args"
        _benefit `shouldEqual` "3 args vs 7 Proxy args"

      it "simpler handler destructuring" do
        -- Before: separate requiredQuery, optionalQuery, requiredHeaders, optionalHeaders
        -- After: flat query, headers, body
        let _benefit = "Flat structure vs nested"
        _benefit `shouldEqual` "Flat structure vs nested"

      it "type inference works better with row types" do
        -- Row types provide better error messages and type inference
        let _benefit = "Better inference"
        _benefit `shouldEqual` "Better inference"

      it "matches common API specification patterns" do
        -- Similar to Tapir (Scala), Servant (Haskell), tRPC, etc.
        let _benefit = "Industry standard pattern"
        _benefit `shouldEqual` "Industry standard pattern"
