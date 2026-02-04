# Response API with Homogeneous Headers

## Completed Implementation ✅

The Endpoint2 API now supports custom response headers using a **homogeneous record** (all fields are `String`).

## Type Signature

```purescript
type Response headers body =
  { status :: StatusCode
  , headers :: Record headers  -- Homogeneous record!
  , body :: body
  }

type EndpointHandler2 path request responseHeaders response ctx err =
  { path :: path
  , request :: request
  } -> Om { httpRequest :: RequestContext | ctx } err (Response responseHeaders response)
```

## Examples

### 1. No Custom Headers

```purescript
createUserHandler
  :: EndpointHandler2
       ApiRoute
       CreateUserRequest
       ()  -- Empty headers row
       User
       AppContext
       ()
createUserHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> pure
      { status: StatusCode 201
      , headers: {}  -- Empty record
      , body: { id: 1, name, email }
      }
```

### 2. Custom Headers (Homogeneous Record)

```purescript
createUserWithHeadersHandler
  :: EndpointHandler2
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
        { status: StatusCode 201
        , headers:
            { location: "/users/" <> show userId
            , xRequestId: "req-abc-123"
            }
        , body: { id: userId, name, email }
        }
```

### 3. Many Headers

```purescript
handler
  :: EndpointHandler2
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
handler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> pure
      { status: StatusCode 201
      , headers:
          { location: "/users/123"
          , xRequestId: "req-abc-123"
          , contentType: "application/json; charset=utf-8"
          , cacheControl: "no-cache"
          }
      , body: { id: 123, name, email }
      }
```

## Header Name Conversion

Field names in camelCase are automatically converted to HTTP header names:

```purescript
{ contentType: "application/json" }       → Content-Type: application/json
{ xRequestId: "123" }                     → X-Request-Id: 123
{ cacheControl: "no-cache" }              → Cache-Control: no-cache
{ location: "/users/123" }                → Location: /users/123
```

## Benefits

### ✅ Type-Safe Headers
```purescript
-- Compiler checks header names!
{ location: "/users/123"
, xRequestId: "abc"
}  -- ✓ Compiles

{ loaction: "/users/123" }  -- ❌ Typo caught at compile time!
```

### ✅ Clean Syntax
```purescript
-- No Object.fromFoldable or Tuple nonsense!
headers: { location: "/users/123", xRequestId: "abc" }
```

### ✅ Flexible
```purescript
-- No headers
headers: {}

// One header
headers: { location: "/users/123" }

-- Many headers
headers: { location: "/users/123", xRequestId: "abc", contentType: "..." }
```

### ✅ All Values Must Be Strings
```purescript
// ❌ Won't compile - wrong type
headers: { age: 42 }

// ✅ Compiles - all strings
headers: { age: "42" }
```

## Complete Example

```purescript
module Example.UserAPI where

import Prelude
import Yoga.Fastify.Om.Endpoint2 as E2
import Yoga.Fastify.Om.RequestBody (RequestBody(..))

type CreateUserReq = { name :: String, email :: String }
type User = { id :: Int, name :: String, email :: String }

type CreateUserRequest = { body :: RequestBody CreateUserReq }

createUserEndpoint :: E2.Endpoint2 ApiRoute CreateUserRequest User
createUserEndpoint = E2.endpoint2 apiRoute 
  (Proxy :: _ CreateUserRequest) 
  (Proxy :: _ User)

-- Handler with custom headers
createUserHandler
  :: E2.EndpointHandler2
       ApiRoute
       CreateUserRequest
       ( location :: String
       , xRequestId :: String
       )
       User
       AppContext
       ()
createUserHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      -- Business logic
      userId <- insertUser name email
      requestId <- generateRequestId
      
      -- Return response with status, headers, and body
      pure
        { status: E2.StatusCode 201
        , headers:
            { location: "/users/" <> show userId
            , xRequestId: requestId
            }
        , body: { id: userId, name, email }
        }
    
    _, _ -> pure
      { status: E2.StatusCode 400
      , headers: { location: "", xRequestId: "" }
      , body: { id: 0, name: "error", email: "error" }
      }
```

## Status Codes

Full control over HTTP status codes:

```purescript
-- Success
pure { status: StatusCode 200, headers: {}, body: result }  -- OK
pure { status: StatusCode 201, headers: {...}, body: result }  -- Created
pure { status: StatusCode 204, headers: {}, body: unit }  -- No Content

-- Client Errors
pure { status: StatusCode 400, headers: {}, body: error }  -- Bad Request
pure { status: StatusCode 401, headers: {}, body: error }  -- Unauthorized
pure { status: StatusCode 404, headers: {}, body: error }  -- Not Found

-- Server Errors
pure { status: StatusCode 500, headers: {}, body: error }  -- Internal Server Error
```

## Implementation Details

### SetHeaders Typeclass

Automatically converts record fields to HTTP headers using RowList:

```purescript
class SetHeaders (headers :: Row Type) where
  setHeaders :: Record headers -> FastifyReply -> Effect FastifyReply

-- Implemented with RowToList for compile-time traversal
instance (RowToList headers rl, SetHeadersRL rl headers) => SetHeaders headers where
  setHeaders = setHeadersRL (Proxy :: Proxy rl)
```

### Header Name Conversion

```purescript
toHeaderName :: String -> String
-- contentType    → Content-Type
// xRequestId     → X-Request-Id
-- cacheControl   → Cache-Control
```

## Migration from Old API

### Before (No Headers Support)
```purescript
handler { path, request } =
  case path, request.body of
    CreateUser, JSONBody data -> do
      pure { id: 1, name: data.name }  -- ❌ No way to set headers
```

### After (With Headers)
```purescript
handler { path, request } =
  case path, request.body of
    CreateUser, JSONBody data -> do
      pure
        { status: StatusCode 201
        , headers: { location: "/users/1" }  -- ✓ Headers!
        , body: { id: 1, name: data.name }
        }
```

## See Also

- `test/ResponseHeadersExample.purs` - Complete working examples
- `ENDPOINT2_ERGONOMICS_EXAMPLE.md` - Full API ergonomics guide
- `docs/ENDPOINT2_RECORD_API.md` - Record-based API documentation
