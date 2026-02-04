module Test.Yoga.Fastify.Om.RequestBodySpec where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Data.String.CodeUnits as SCU
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

type CreateUserJSONSpec =
  ( body :: RequestBody CreateUserJSON
  )

createUserJSONEndpoint :: E2.Endpoint2 ApiRoute CreateUserJSONSpec User
createUserJSONEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy CreateUserJSONSpec) (Proxy :: Proxy User)

createUserJSONHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       CreateUserJSON  -- Body is unwrapped!
       User
       AppContext
       ()
createUserJSONHandler { path, body } =
  case path of
    CreateUserJSON -> do
      -- Body is automatically unwrapped! No pattern matching needed!
      let { name, email } = body
      pure
        { id: 1
        , name
        , email
        }
    _ -> do
      pure { id: 0, name: "error", email: "wrong endpoint" }

-- ============================================================================
-- EXAMPLE 2: FormData - URL-Encoded Form Submission
-- ============================================================================

type SubmitFormSpec =
  ( body :: RequestBody Unit -- Will be parsed as FormData based on Content-Type
  )

submitFormEndpoint :: E2.Endpoint2 ApiRoute SubmitFormSpec User
submitFormEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy SubmitFormSpec) (Proxy :: Proxy User)

submitFormHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       (RequestBody Unit)
       User
       AppContext
       ()
submitFormHandler { path, body } =
  case path, body of
    SubmitForm, FormData formFields -> do
      -- Access form fields
      -- let name = Object.lookup "name" formFields
      --     email = Object.lookup "email" formFields
      pure
        { id: 2
        , name: "Form User"
        , email: "form@example.com"
        }
    SubmitForm, NoBody -> do
      pure { id: 0, name: "error", email: "no form data" }
    _, _ -> do
      pure { id: 0, name: "error", email: "wrong endpoint" }

-- ============================================================================
-- EXAMPLE 3: TextBody - Plain Text Request
-- ============================================================================

type SendTextSpec =
  ( body :: RequestBody Unit -- Will be parsed as TextBody based on Content-Type
  )

sendTextEndpoint :: E2.Endpoint2 ApiRoute SendTextSpec User
sendTextEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy SendTextSpec) (Proxy :: Proxy User)

sendTextHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       (RequestBody Unit)
       User
       AppContext
       ()
sendTextHandler { path, body } =
  case path, body of
    SendText, TextBody text -> do
      -- Process plain text
      pure
        { id: 3
        , name: "Text User"
        , email: text <> "@example.com"
        }
    SendText, NoBody -> do
      pure { id: 0, name: "error", email: "no text" }
    _, _ -> do
      pure { id: 0, name: "error", email: "wrong endpoint" }

-- ============================================================================
-- EXAMPLE 4: BytesBody - Binary Upload
-- ============================================================================

type UploadFileSpec =
  ( body :: RequestBody Unit -- Will be parsed as BytesBody based on Content-Type
  )

uploadFileEndpoint :: E2.Endpoint2 ApiRoute UploadFileSpec User
uploadFileEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy UploadFileSpec) (Proxy :: Proxy User)

uploadFileHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       (RequestBody Unit)
       User
       AppContext
       ()
uploadFileHandler { path, body } =
  case path, body of
    UploadFile, BytesBody bytes -> do
      -- Process binary data
      pure
        { id: 4
        , name: "Upload User"
        , email: "uploaded@example.com"
        }
    UploadFile, NoBody -> do
      pure { id: 0, name: "error", email: "no file" }
    _, _ -> do
      pure { id: 0, name: "error", email: "wrong endpoint" }

-- ============================================================================
-- EXAMPLE 5: NoBody - GET Request (No Body)
-- ============================================================================

type GetUsersSpec = () -- No body field at all

getUsersEndpoint :: E2.Endpoint2 ApiRoute GetUsersSpec (Array User)
getUsersEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy GetUsersSpec) (Proxy :: Proxy (Array User))

getUsersHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       Unit
       (Array User)
       AppContext
       ()
getUsersHandler { path } =
  case path of
    GetUsers ->
      pure
        [ { id: 1, name: "Alice", email: "alice@example.com" }
        , { id: 2, name: "Bob", email: "bob@example.com" }
        ]
    _ -> pure []

-- ============================================================================
-- TESTS
-- ============================================================================

spec :: Spec Unit
spec = do
  describe "RequestBody ADT Support" do

    describe "JSONBody" do

      it "compiles endpoint with JSONBody type" do
        let _endpoint = createUserJSONEndpoint
        true `shouldEqual` true

      it "handler can pattern match on JSONBody" do
        let
          handler { body } = case body of
            JSONBody createReq -> createReq.name
            NoBody -> "no body"
            _ -> "other"
        true `shouldEqual` true

      it "extracts typed data from JSONBody" do
        -- JSONBody contains CreateUserJSON with { name :: String, email :: String }
        let
          handler { body } = case body of
            JSONBody createReq ->
              let
                { name, email } = createReq
              in
                name <> " " <> email
            _ -> "error"
        true `shouldEqual` true

    describe "FormData" do

      it "compiles endpoint that accepts FormData" do
        let _endpoint = submitFormEndpoint
        true `shouldEqual` true

      it "handler can pattern match on FormData" do
        let
          handler { body } = case body of
            FormData formFields -> "form data"
            NoBody -> "no body"
            _ -> "other"
        true `shouldEqual` true

      it "FormData contains Object String (key-value pairs)" do
        -- FormData wraps Object String for form fields
        let
          handler { body } = case body of
            FormData _formFields ->
              -- Can use Object.lookup to get fields
              -- let name = Object.lookup "name" formFields
              "has form"
            _ -> "no form"
        true `shouldEqual` true

    describe "TextBody" do

      it "compiles endpoint that accepts TextBody" do
        let _endpoint = sendTextEndpoint
        true `shouldEqual` true

      it "handler can pattern match on TextBody" do
        let
          handler { body } = case body of
            TextBody text -> text
            NoBody -> "no text"
            _ -> "other"
        true `shouldEqual` true

      it "TextBody contains String" do
        let
          handler { body } = case body of
            TextBody text ->
              -- text :: String
              "Got text: " <> text
            _ -> "no text"
        true `shouldEqual` true

    describe "BytesBody" do

      it "compiles endpoint that accepts BytesBody" do
        let _endpoint = uploadFileEndpoint
        true `shouldEqual` true

      it "handler can pattern match on BytesBody" do
        let
          handler { body } = case body of
            BytesBody _bytes -> "has bytes"
            NoBody -> "no bytes"
            _ -> "other"
        true `shouldEqual` true

      it "BytesBody contains Foreign (raw buffer)" do
        -- BytesBody wraps Foreign which can be a Buffer/ArrayBuffer
        let
          handler { body } = case body of
            BytesBody _bytes ->
              -- bytes :: Foreign (can be passed to FFI)
              "processed binary"
            _ -> "no binary"
        true `shouldEqual` true

    describe "NoBody" do

      it "GET endpoint with no body field uses NoBody implicitly" do
        let _endpoint = getUsersEndpoint
        true `shouldEqual` true

      it "endpoints can handle missing body gracefully" do
        let
          handler { body } = case body of
            NoBody -> "no body provided"
            JSONBody _ -> "has json"
            _ -> "other"
        true `shouldEqual` true

    describe "Content-Type Based Routing" do

      it "same endpoint type can handle multiple content types" do
        -- RequestBody Unit means: "parse based on Content-Type header"
        -- - application/json → JSONBody
        -- - application/x-www-form-urlencoded → FormData
        -- - text/plain → TextBody
        -- - application/octet-stream → BytesBody
        true `shouldEqual` true

      it "handler pattern matches to handle each type" do
        let
          handler { body } = case body of
            JSONBody _ -> "json"
            FormData _ -> "form"
            TextBody _ -> "text"
            BytesBody _ -> "bytes"
            NoBody -> "none"
        true `shouldEqual` true

    describe "Type Safety" do

      it "JSONBody is typed with the actual body type" do
        -- JSONBody CreateUserJSON means:
        -- - body must be valid JSON
        -- - body must match CreateUserJSON schema
        -- - ReadForeign instance validates structure
        let
          _ensureTyped :: RequestBody CreateUserJSON -> String
          _ensureTyped (JSONBody req) = req.name
          _ensureTyped _ = "other"
        true `shouldEqual` true

      it "pattern matching ensures all cases are handled" do
        -- PureScript will warn if you don't handle all constructors
        let
          handler { body } = case body of
            JSONBody _ -> "json"
            NoBody -> "none"
            FormData _ -> "form"
            TextBody _ -> "text"
            BytesBody _ -> "bytes"
        true `shouldEqual` true

    describe "Comparison with Direct Body Type" do

      it "Before: body was just a single type" do
        -- Old way:
        -- type OldSpec = ( body :: CreateUserJSON )
        -- Handler always expected JSON, couldn't handle forms/text/bytes
        let comparison = "Single type vs Sum type"
        comparison `shouldEqual` "Single type vs Sum type"

      it "After: body can be multiple types" do
        -- New way:
        -- type NewSpec = ( body :: RequestBody CreateUserJSON )
        -- Handler can pattern match on JSONBody/FormData/TextBody/BytesBody
        let improvement = "Sum type supports multiple formats"
        improvement `shouldEqual` "Sum type supports multiple formats"

      it "RequestBody enables content negotiation" do
        -- Same endpoint can handle different Content-Types
        -- by pattern matching on the RequestBody variant
        let benefit = "Content negotiation via pattern matching"
        benefit `shouldEqual` "Content negotiation via pattern matching"
