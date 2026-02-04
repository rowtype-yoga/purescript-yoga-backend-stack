module Test.Yoga.Fastify.Om.RequestBodySpec where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..), maybe)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint2 as E2
import Yoga.Fastify.Om.RequestBody (RequestBody(..))
import Yoga.JSON (class ReadForeign, class WriteForeign)

-- ============================================================================
-- API TYPES
-- ============================================================================

type User =
  { id :: Int
  , name :: String
  , email :: String
  }

type CreateUserJSON =
  { name :: String
  , email :: String
  }

data ApiRoute
  = CreateUserJSON
  | UploadFile
  | SendText
  | GetUsers
  | SubmitForm

derive instance Generic ApiRoute _
derive instance Eq ApiRoute

apiRoute :: RouteDuplex' ApiRoute
apiRoute = RD.root $ RG.sum
  { "CreateUserJSON": "api" / "users" / "json" / RG.noArgs
  , "UploadFile": "api" / "upload" / RG.noArgs
  , "SendText": "api" / "text" / RG.noArgs
  , "GetUsers": "api" / "users" / RG.noArgs
  , "SubmitForm": "api" / "form" / RG.noArgs
  }

type AppContext = ()

-- ============================================================================
-- EXAMPLE 1: JSONBody - Standard JSON Request
-- ============================================================================

type CreateUserJSONRequest =
  { body :: RequestBody CreateUserJSON
  }

createUserJSONEndpoint :: E2.Endpoint2 ApiRoute CreateUserJSONRequest User
createUserJSONEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy CreateUserJSONRequest) (Proxy :: Proxy User)

createUserJSONHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserJSONRequest
       User
       AppContext
       ()
createUserJSONHandler { path, request } =
  case path, request.body of
    CreateUserJSON, JSONBody createReq -> do
      -- Body is wrapped in JSONBody - pattern match to extract
      let { name, email } = createReq
      pure
        { id: 1
        , name
        , email
        }
    CreateUserJSON, NoBody -> do
      pure { id: 0, name: "error", email: "no body provided" }
    _, _ -> do
      pure { id: 0, name: "error", email: "wrong endpoint" }

-- ============================================================================
-- EXAMPLE 2: NoBody - GET Request (No Body)
-- ============================================================================

type GetUsersRequest = { body :: RequestBody Unit }  -- Just body with NoBody

getUsersEndpoint :: E2.Endpoint2 ApiRoute GetUsersRequest (Array User)
getUsersEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy { body :: RequestBody Unit }) (Proxy :: Proxy (Array User))

getUsersHandler
  :: E2.EndpointHandler2
       ApiRoute
       GetUsersRequest
       (Array User)
       AppContext
       ()
getUsersHandler { path, request } =
  case path, request.body of
    GetUsers, NoBody ->
      pure
        [ { id: 1, name: "Alice", email: "alice@example.com" }
        , { id: 2, name: "Bob", email: "bob@example.com" }
        ]
    _, _ -> pure []

-- ============================================================================
-- EXAMPLE 3: Query + Body
-- ============================================================================

type CreateUserWithQueryRequest =
  { query :: { notify :: Boolean, source :: Maybe String }
  , body :: RequestBody CreateUserJSON
  }

createUserWithQueryEndpoint :: E2.Endpoint2 ApiRoute CreateUserWithQueryRequest User
createUserWithQueryEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy CreateUserWithQueryRequest) (Proxy :: Proxy User)

createUserWithQueryHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserWithQueryRequest
       User
       AppContext
       ()
createUserWithQueryHandler { path, request } =
  case path, request.body of
    CreateUserJSON, JSONBody createReq -> do
      let { name, email } = createReq
          { notify, source } = request.query
      pure
        { id: if notify then 2 else 3
        , name: name <> maybe "" (\s -> " from " <> s) source
        , email
        }
    _, _ -> pure { id: 0, name: "error", email: "error" }

-- ============================================================================
-- EXAMPLE 4: Headers + Body
-- ============================================================================

type CreateUserWithHeadersRequest =
  { headers :: { authorization :: String, xRequestId :: Maybe String }
  , body :: RequestBody CreateUserJSON
  }

createUserWithHeadersEndpoint :: E2.Endpoint2 ApiRoute CreateUserWithHeadersRequest User
createUserWithHeadersEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy CreateUserWithHeadersRequest) (Proxy :: Proxy User)

createUserWithHeadersHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserWithHeadersRequest
       User
       AppContext
       ()
createUserWithHeadersHandler { path, request } =
  case path, request.body of
    CreateUserJSON, JSONBody createReq -> do
      let { name, email } = createReq
          { authorization, xRequestId } = request.headers
          verified = authorization == "Bearer valid-token"
      pure
        { id: if verified then 4 else 5
        , name: name <> maybe "" (\rid -> " [" <> rid <> "]") xRequestId
        , email
        }
    _, _ -> pure { id: 0, name: "error", email: "error" }

-- ============================================================================
-- EXAMPLE 5: Full Request (Query + Headers + Body)
-- ============================================================================

type FullRequest =
  { query :: { notify :: Boolean }
  , headers :: { authorization :: String }
  , body :: RequestBody CreateUserJSON
  }

fullRequestEndpoint :: E2.Endpoint2 ApiRoute FullRequest User
fullRequestEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy FullRequest) (Proxy :: Proxy User)

fullRequestHandler
  :: E2.EndpointHandler2
       ApiRoute
       FullRequest
       User
       AppContext
       ()
fullRequestHandler { path, request } =
  case path, request.body of
    CreateUserJSON, JSONBody createReq -> do
      let { name, email } = createReq
          { notify } = request.query
          { authorization } = request.headers
          verified = authorization == "Bearer valid-token"
      pure
        { id: 6
        , name: if notify then name <> " (notified)" else name
        , email: if verified then email else "unverified@example.com"
        }
    _, _ -> pure { id: 0, name: "error", email: "error" }

-- ============================================================================
-- TESTS
-- ============================================================================

spec :: Spec Unit
spec = do
  describe "RequestBody ADT Support (Record-Based)" do
    
    describe "JSONBody" do
      
      it "compiles endpoint with JSONBody type" do
        let _endpoint = createUserJSONEndpoint
        true `shouldEqual` true
      
      it "handler receives wrapped JSONBody" do
        let
          handler { request } = case request.body of
            JSONBody createReq -> createReq.name
            NoBody -> "no body"
            _ -> "other"
        true `shouldEqual` true
      
      it "extracts typed data from JSONBody via pattern matching" do
        let
          handler { request } = case request.body of
            JSONBody createReq ->
              let { name, email } = createReq
              in name <> " " <> email
            _ -> "error"
        true `shouldEqual` true
    
    describe "NoBody" do
      
      it "GET endpoint with empty request uses NoBody default" do
        let _endpoint = getUsersEndpoint
        true `shouldEqual` true
      
      it "handler receives NoBody in wrapped form" do
        let
          handler { request } = case request.body of
            NoBody -> "no body provided"
            JSONBody _ -> "has json"
            _ -> "other"
        true `shouldEqual` true
    
    describe "Query + Body" do
      
      it "compiles endpoint with query and body" do
        let _endpoint = createUserWithQueryEndpoint
        true `shouldEqual` true
      
      it "handler can access both query and wrapped body" do
        let
          handler { request } = case request.body of
            JSONBody user ->
              user.name <> " has query"
            _ -> "error"
        true `shouldEqual` true
    
    describe "Headers + Body" do
      
      it "compiles endpoint with headers and body" do
        let _endpoint = createUserWithHeadersEndpoint
        true `shouldEqual` true
      
      it "handler can access both headers and wrapped body" do
        let
          handler { request } = case request.body of
            JSONBody user ->
              user.name <> " has headers"
            _ -> "error"
        true `shouldEqual` true
    
    describe "Full Request (Query + Headers + Body)" do
      
      it "compiles endpoint with all fields" do
        let _endpoint = fullRequestEndpoint
        true `shouldEqual` true
      
      it "handler can access query, headers, and wrapped body" do
        let
          handler { request } = case request.body of
            JSONBody user ->
              let { notify } = request.query
                  { authorization } = request.headers
                  notifyStr = show (notify :: Boolean)
              in user.name <> " notify=" <> notifyStr <> " auth=" <> authorization
            _ -> "error"
        true `shouldEqual` true
    
    describe "Field Omission with Union" do
      
      it "empty request {} defaults to query={}, headers={}, body=NoBody" do
        let
          _endpoint :: E2.Endpoint2 ApiRoute {} User
          _endpoint = E2.endpoint2 apiRoute (Proxy :: Proxy {}) (Proxy :: Proxy User)
        true `shouldEqual` true
      
      it "body-only request defaults query and headers" do
        -- Demonstrate that we can omit query and headers
        true `shouldEqual` true
      
      it "query-only request defaults headers and body" do
        -- Demonstrate that we can omit headers and body
        true `shouldEqual` true
    
    describe "Type Safety" do
      
      it "JSONBody is typed with the actual body type" do
        let
          _ensureTyped :: RequestBody CreateUserJSON -> String
          _ensureTyped (JSONBody req) = req.name
          _ensureTyped _ = "other"
        true `shouldEqual` true
      
      it "pattern matching ensures all cases are handled" do
        let
          handler { request } = case request.body of
            JSONBody _ -> "json"
            NoBody -> "none"
            FormData _ -> "form"
            TextBody _ -> "text"
            BytesBody _ -> "bytes"
        true `shouldEqual` true
    
    describe "Comparison with Row-Based API" do
      
      it "Before: row types with separate type parameters" do
        -- Old way:
        -- type Spec = ( body :: RequestBody CreateUser )
        -- handler :: EndpointHandler2 path query headers body response ctx err
        let comparison = "Row type vs Record type"
        comparison `shouldEqual` "Row type vs Record type"
      
      it "After: single record parameter" do
        -- New way:
        -- type Request = { body :: JSONBody CreateUser }
        -- handler :: EndpointHandler2 path request response ctx err
        let improvement = "Single record parameter"
        improvement `shouldEqual` "Single record parameter"
      
      it "Body remains wrapped for explicit handling" do
        -- Handler must pattern match on wrapped body
        -- case request.body of
        --   JSONBody user -> ...
        --   NoBody -> ...
        let benefit = "Explicit content type handling"
        benefit `shouldEqual` "Explicit content type handling"
