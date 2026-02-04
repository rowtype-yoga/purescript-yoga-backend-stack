# Endpoint2: Record-Based Typed Endpoints

Endpoint2 provides a cleaner, more ergonomic API for defining type-safe Fastify endpoints with support for multiple content types (JSON, forms, text, binary) via the RequestBody ADT.

## Quick Comparison

### Before (Endpoint)

```purescript
-- 7 type parameters - verbose!
type UserEndpoint = Endpoint
  UserRoute                      -- path
  ( page :: Int )                -- required query
  ( limit :: Int )               -- optional query  
  CreateUserRequest              -- body
  ( authorization :: String )    -- required headers
  ( x-request-id :: String )     -- optional headers
  UserResponse                   -- response

createUserEndpoint = endpoint
  { pathCodec: userRoute
  , requiredQuery: Proxy :: Proxy ( page :: Int )
  , optionalQuery: Proxy :: Proxy ( limit :: Int )
  , bodyType: Proxy :: Proxy CreateUserRequest
  , requiredHeaders: Proxy :: Proxy ( authorization :: String )
  , optionalHeaders: Proxy :: Proxy ( x-request-id :: String )
  , responseType: Proxy :: Proxy UserResponse
  }

-- Handler has nested structure
handler { path, requiredQuery, optionalQuery, body, requiredHeaders, optionalHeaders } = do
  let { page } = requiredQuery           -- separate record
      { limit } = optionalQuery          -- separate record
      { authorization } = requiredHeaders -- separate record
  pure response
```

### After (Endpoint2)

```purescript
-- 3 type parameters - clean!
type UserRequestSpec =
  ( query :: { page :: Int, limit :: Maybe Int }
  , headers :: { authorization :: String }
  , body :: CreateUserRequest
  )

type UserEndpoint = Endpoint2 UserRoute UserRequestSpec UserResponse

createUserEndpoint = endpoint2 userRoute (Proxy :: Proxy UserRequestSpec) (Proxy :: Proxy UserResponse)

-- Handler has flat structure
handler { path, query, headers, body } = do
  let { page, limit } = query      -- single record, Maybe for optional
      { authorization } = headers  -- single record
  pure response
```

## Key Features

### 1. RequestBody ADT - Multiple Content Types

Handle JSON, form data, plain text, and binary uploads with a single sum type:

```purescript
data RequestBody a
  = JSONBody a                -- JSON parsed via yoga-json
  | NoBody                    -- No body (GET/DELETE)
  | FormData (Object String)  -- URL-encoded forms
  | TextBody String           // Plain text
  | BytesBody Foreign         -- Binary data (files, images, etc.)
```

Example:
```purescript
type UploadSpec =
  ( body :: RequestBody CreateUserJSON )

handler { body } = case body of
  JSONBody user -> createUser user          -- application/json
  FormData fields -> createFromForm fields  -- application/x-www-form-urlencoded
  TextBody text -> createFromText text      -- text/plain
  BytesBody bytes -> uploadFile bytes       -- application/octet-stream
  NoBody -> pure errorResponse
```

### 2. Record-Based Request Specification

Group related request data (query, headers, body) in a single row type:

```purescript
type MyRequestSpec =
  ( query :: { id :: Int, filter :: Maybe String }
  , headers :: { authorization :: String }
  , body :: UpdateRequest
  )
```

### 3. Maybe for Optional Fields

No more separate required/optional row types. Use `Maybe` directly:

```purescript
-- Required: page :: Int
-- Optional: limit :: Maybe Int
type QuerySpec = ( query :: { page :: Int, limit :: Maybe Int } )
```

### 4. Omit Entire Fields

Don't need query params? Just leave it out:

```purescript
-- Only headers, no query or body
type HeadersOnlySpec = ( headers :: { authorization :: String } )

-- Completely empty - just path!
type MinimalSpec = ()
```

When fields are omitted, they default to:
- `query` → `{}` (empty record)
- `headers` → `{}` (empty record)
- `body` → `Unit`

### 5. Simpler Handler Signature

```purescript
-- Before: 7 type parameters
EndpointHandler path reqQ optQ body reqH optH response ctx err

-- After: 5 type parameters (query/headers are combined)
EndpointHandler2 path query headers body response ctx err
```

## Examples

### Example 1: POST with Full Specification

```purescript
type CreateUserSpec =
  ( query :: { notify :: Boolean, source :: Maybe String }
  , headers :: { authorization :: String, xRequestId :: Maybe String }
  , body :: CreateUserRequest
  )

createUserEndpoint :: Endpoint2 UserRoute CreateUserSpec UserResponse
createUserEndpoint = endpoint2 userRoute (Proxy :: Proxy CreateUserSpec) (Proxy :: Proxy UserResponse)

createUserHandler { path, query, headers, body } = do
  let { notify, source } = query
      { authorization, xRequestId } = headers
      { name, email, age } = body
  
  -- Business logic
  user <- createUser name email age
  pure user
```

### Example 2: GET with Query Only

```purescript
type GetUserSpec =
  ( query :: { id :: Int, includeDeleted :: Maybe Boolean }
  )

getUserEndpoint :: Endpoint2 UserRoute GetUserSpec UserResponse
getUserEndpoint = endpoint2 userRoute (Proxy :: Proxy GetUserSpec) (Proxy :: Proxy UserResponse)

getUserHandler { path, query } = do
  let { id, includeDeleted } = query
  user <- fetchUser id includeDeleted
  pure user
```

### Example 3: DELETE with Headers Only

```purescript
type DeleteUserSpec =
  ( headers :: { authorization :: String }
  )

deleteUserEndpoint :: Endpoint2 UserRoute DeleteUserSpec UserResponse
deleteUserEndpoint = endpoint2 userRoute (Proxy :: Proxy DeleteUserSpec) (Proxy :: Proxy UserResponse)

deleteUserHandler { path, headers } = do
  let { authorization } = headers
  -- headers defaults to {} if omitted from spec
  result <- deleteUser path authorization
  pure result
```

### Example 4: Simple List (No Request Data)

```purescript
type ListUsersSpec = ()

listUsersEndpoint :: Endpoint2 UserRoute ListUsersSpec (Array UserResponse)
listUsersEndpoint = endpoint2 userRoute (Proxy :: Proxy ListUsersSpec) (Proxy :: Proxy (Array UserResponse))

listUsersHandler { path } = do
  -- query, headers, body all default to empty
  users <- fetchAllUsers
  pure users
```

## Migration Guide: Endpoint → Endpoint2

### Step 1: Combine Request Specifications

**Before:**
```purescript
endpoint
  { pathCodec: route
  , requiredQuery: Proxy :: Proxy ( page :: Int )
  , optionalQuery: Proxy :: Proxy ( limit :: Int, sort :: String )
  , bodyType: Proxy :: Proxy CreateUser
  , requiredHeaders: Proxy :: Proxy ( auth :: String )
  , optionalHeaders: Proxy :: Proxy ( requestId :: String )
  , responseType: Proxy :: Proxy User
  }
```

**After:**
```purescript
type RequestSpec =
  ( query :: { page :: Int, limit :: Maybe Int, sort :: Maybe String }
  , headers :: { auth :: String, requestId :: Maybe String }
  , body :: CreateUser
  )

endpoint2 route (Proxy :: Proxy RequestSpec) (Proxy :: Proxy User)
```

### Step 2: Update Handler Signature

**Before:**
```purescript
handler :: EndpointHandler 
  UserRoute 
  ( page :: Int ) 
  ( limit :: Int, sort :: String ) 
  CreateUser 
  ( auth :: String ) 
  ( requestId :: String )
  User 
  ctx 
  err
handler { path, requiredQuery, optionalQuery, body, requiredHeaders, optionalHeaders } = ...
```

**After:**
```purescript
handler :: EndpointHandler2 
  UserRoute 
  ( page :: Int, limit :: Maybe Int, sort :: Maybe String )
  ( auth :: String, requestId :: Maybe String )
  CreateUser 
  User 
  ctx 
  err
handler { path, query, headers, body } = ...
```

### Step 3: Update Handler Implementation

**Before:**
```purescript
handler data = do
  let { page } = data.requiredQuery
      { limit, sort } = data.optionalQuery
      { auth } = data.requiredHeaders
      { requestId } = data.optionalHeaders
  -- ...
```

**After:**
```purescript
handler { query, headers, body } = do
  let { page, limit, sort } = query
      { auth, requestId } = headers
  -- ...
```

## Detailed Comparison

| Aspect | Endpoint (Original) | Endpoint2 (New) |
|--------|-------------------|-----------------|
| **Type Parameters** | 7 (path, reqQ, optQ, body, reqH, optH, resp) | 3 (path, requestSpec, response) |
| **Request Spec** | Separate row types for req/opt | Single record with Maybe for optional |
| **Builder Arguments** | 7 Proxy values in record | 3 arguments (codec, spec, response) |
| **Handler Destructuring** | Nested: `requiredQuery`, `optionalQuery`, etc. | Flat: `query`, `headers`, `body` |
| **Field Omission** | Use `()` for empty | Completely omit field from row type |
| **Type Inference** | Can be verbose | Cleaner with row types |
| **Error Messages** | Can be complex with 7 type params | Simpler with 3 type params |

## Benefits

### 1. Reduced Type Complexity

**Endpoint:** 7 type parameters → verbose type signatures
**Endpoint2:** 3 type parameters → cleaner, more maintainable

### 2. Better Developer Experience

- Single destructuring: `{ query, headers, body }`
- Intuitive: `Maybe` means optional
- Matches common API specification patterns (Tapir, Servant, tRPC)

### 3. Type Inference

Row types provide better type inference and error messages than multiple separate type parameters.

### 4. Flexibility

Omit any combination of query/headers/body fields based on your endpoint needs.

## Implementation Notes

### Parsing Strategy

Endpoint2 uses instance chains (PureScript 0.15+) to distinguish required from optional fields:

```purescript
-- Optional field (Maybe type) - checked first
instance ParseQueryFieldValue (Maybe ty) where
  parseQueryFieldValue _ key obj = Right $ Object.lookup key obj

-- Required field (non-Maybe) - fallback
else instance ParseParam ty => ParseQueryFieldValue ty where
  parseQueryFieldValue _ key obj = 
    case Object.lookup key obj of
      Nothing -> Left $ "Missing required parameter: " <> key
      Just val -> parseParam val
```

### Defaults for Omitted Fields

When you omit fields from the request spec, the base case instances provide defaults:

```purescript
-- Base case: empty request spec defaults to empty records/Unit
instance ParseRequestSpec RL.Nil () () Unit where
  parseRequestSpec _ _ _ _ = Right { query: {}, headers: {}, body: unit }
```

### yoga-json Integration

Both request parsing and response encoding use yoga-json:

- **Request body:** `ReadForeign` constraint
- **Response:** `WriteForeign` constraint
- **Query params:** Parsed via `ParseParam` with `Maybe` for optional

## When to Use Which

### Use Endpoint2 When:

- Building new endpoints
- You want cleaner, more maintainable code
- You prefer row types and type-level programming
- Your team is familiar with Tapir/Servant-style APIs

### Use Endpoint (Original) When:

- Working with existing codebase using Endpoint
- You need the explicit separation of required/optional
- Migration cost outweighs benefits

## Complete Example

```purescript
module MyAPI where

import Yoga.Fastify.Om.Endpoint2 as E2

-- Define your route type
data UserRoute = UserById Int | CreateUser

-- Define routing codec
userRoute :: RouteDuplex' UserRoute
userRoute = RD.root $ RG.sum
  { "UserById": "users" / RD.int RD.segment
  , "CreateUser": "users" / RG.noArgs
  }

-- Define request/response types
type CreateUserRequest = { name :: String, email :: String }
type UserResponse = { id :: Int, name :: String, email :: String }

-- Define endpoint specification
type CreateUserSpec =
  ( query :: { notify :: Boolean }
  , headers :: { authorization :: String }
  , body :: CreateUserRequest
  )

-- Create endpoint
createUserEndpoint :: E2.Endpoint2 UserRoute CreateUserSpec UserResponse
createUserEndpoint = E2.endpoint2 userRoute (Proxy :: Proxy CreateUserSpec) (Proxy :: Proxy UserResponse)

-- Implement handler
createUserHandler { path, query, headers, body } = do
  let CreateUser = path
      { notify } = query
      { authorization } = headers
      { name, email } = body
  
  { db } <- Om.ask
  user <- liftAff $ DB.createUser db name email
  
  when notify do
    sendNotification user
  
  pure user

-- Register with Fastify
main = do
  app <- createOmFastify { db } =<< fastify {}
  postOm (RouteURL "/users") (E2.handleEndpoint2 createUserEndpoint createUserHandler) app
  listen 3000 app
```

## Testing

The test suite includes examples of all field omission patterns:

- Full spec (query + headers + body)
- Query only
- Headers only
- Body + query
- Minimal (no fields)

Run tests:
```bash
bunx spago test -p yoga-fastify-om
```

All 52 tests pass, demonstrating the type safety and flexibility of Endpoint2!
