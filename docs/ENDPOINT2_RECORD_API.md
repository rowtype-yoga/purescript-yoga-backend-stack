# Endpoint2 Record-Based API

The new Endpoint2 API uses a single record type for requests, where body values remain wrapped in RequestBody variants for explicit content-type handling.

## The Pattern

```purescript
-- 1. Define request as a record type
type CreateUserRequest =
  { query :: { notify :: Boolean, source :: Maybe String }
  , headers :: { authorization :: String }
  , body :: RequestBody CreateUserJSON
  }

-- 2. Handler receives the record and pattern matches on body
handler :: EndpointHandler2 ApiRoute CreateUserRequest User ctx err
handler { path, request } = case request.body of
  JSONBody user -> do
    -- Extract fields from request record
    let { notify, source } = request.query
        { authorization } = request.headers
        { name, email } = user
    
    createUser name email
  
  NoBody ->
    pure errorResponse
```

## Complete Example (From Tests)

```purescript
-- API Types
type CreateUserJSON = { name :: String, email :: String }
type User = { id :: Int, name :: String, email :: String }

-- Request Type (record with wrapped body)
type CreateUserJSONRequest =
  { body :: RequestBody CreateUserJSON
  }

-- Endpoint Specification
createUserJSONEndpoint :: Endpoint2 ApiRoute CreateUserJSONRequest User
createUserJSONEndpoint = endpoint2 apiRoute (Proxy :: Proxy CreateUserJSONRequest) (Proxy :: Proxy User)

-- Handler (receives record, pattern matches on wrapped body)
createUserJSONHandler
  :: EndpointHandler2
       ApiRoute
       CreateUserJSONRequest
       User
       AppContext
       ()
createUserJSONHandler { path, request } =
  case path, request.body of
    CreateUserJSON, JSONBody createReq -> do
      -- Body is wrapped - pattern match to extract
      let { name, email } = createReq
      pure { id: 1, name, email }
    
    CreateUserJSON, NoBody -> do
      pure { id: 0, name: "error", email: "no body provided" }
    
    _, _ -> do
      pure { id: 0, name: "error", email: "wrong endpoint" }
```

## Benefits

### 1. Single Record Parameter

**Before (row-based):**
```purescript
EndpointHandler2 path query headers body response ctx err
```

**After (record-based):**
```purescript
EndpointHandler2 path request response ctx err
-- where request is a record: { query :: ..., headers :: ..., body :: ... }
```

### 2. Explicit Body Handling

Body remains wrapped in RequestBody variants, forcing explicit handling:

```purescript
handler { request } = case request.body of
  JSONBody user -> createUser user
  NoBody -> handleMissingBody
  FormData fields -> createFromForm fields
  TextBody text -> importFromText text
  BytesBody bytes -> uploadFile bytes
```

### 3. Clean Field Access

```purescript
handler { request } = case request.body of
  JSONBody user -> do
    let { notify } = request.query          -- Access query
        { authorization } = request.headers  -- Access headers
        { name, email } = user               -- Access body
    createUser name email notify authorization
```

## Request Type Combinations

### Body Only
```purescript
type BodyOnlyRequest = { body :: RequestBody CreateUser }

handler { request } = case request.body of
  JSONBody user -> createUser user
  NoBody -> error
```

### Query + Body
```purescript
type QueryBodyRequest =
  { query :: { page :: Int, limit :: Maybe Int }
  , body :: RequestBody CreateUser
  }

handler { request } = case request.body of
  JSONBody user -> do
    let { page, limit } = request.query
    createUser user page limit
  NoBody -> error
```

### Headers + Body
```purescript
type HeadersBodyRequest =
  { headers :: { authorization :: String }
  , body :: RequestBody CreateUser
  }

handler { request } = case request.body of
  JSONBody user -> do
    let { authorization } = request.headers
    if authorized authorization
      then createUser user
      else error
  NoBody -> error
```

### All Three
```purescript
type FullRequest =
  { query :: { notify :: Boolean }
  , headers :: { authorization :: String }
  , body :: RequestBody CreateUser
  }

handler { request } = case request.body of
  JSONBody user -> do
    let { notify } = request.query
        { authorization } = request.headers
    if authorized authorization && notify
      then createAndNotify user
      else createUser user
  NoBody -> error
```

## RequestBody Variants

The body field uses the RequestBody sum type:

```purescript
data RequestBody a
  = JSONBody a                -- JSON (parsed via ReadForeign)
  | NoBody                    -- No body
  | FormData (Object String)  -- Form data (TODO: implement parsing)
  | TextBody String           -- Plain text (TODO: implement parsing)
  | BytesBody Foreign         -- Binary (TODO: implement parsing)
```

Currently, only `JSONBody` and `NoBody` are fully implemented. Pattern match on the variant you expect:

```purescript
handler { request } = case request.body of
  JSONBody user -> 
    createUser user
  
  NoBody -> 
    pure { error: "Body required" }
  
  _ ->
    pure { error: "Unsupported content type" }
```

## Type Safety

### Compile-Time Checking

```purescript
type Request = { body :: RequestBody CreateUser }

handler { request } = case request.body of
  JSONBody user -> do
    let name = user.name   -- ✅ Compiles
    let wrong = user.age   -- ❌ Compile error: no .age field
```

### Exhaustive Pattern Matching

```purescript
-- ⚠️ Compiler warns if you don't handle all cases
handler { request } = case request.body of
  JSONBody user -> createUser user
  -- Missing: NoBody, FormData, TextBody, BytesBody cases
```

## Field Omission via coerceHandler

You can write handlers with full request types (all three fields) and coerce them to match partial endpoint types:

```purescript
-- Endpoint with partial type (only body):
type PartialReq = { body :: RequestBody User }
endpoint = endpoint2 apiRoute (Proxy :: _ PartialReq) (Proxy :: _ Response)

-- Handler with full type (all three fields):
type FullReq = { query :: Record (), headers :: Record (), body :: RequestBody User }
handlerFull :: EndpointHandler2 ApiRoute FullReq Response ctx err
handlerFull { path, request } = do
  -- Can access all fields, even though endpoint only has body!
  let _ = request.query     -- Record () (parsed from undefined)
  let _ = request.headers   -- Record () (parsed from undefined)
  case request.body of
    JSONBody user -> pure (processUser user)
    NoBody -> pure errorResponse

-- Coerce to partial type (safe via JS runtime equivalence):
handler :: EndpointHandler2 ApiRoute PartialReq Response ctx err
handler = coerceHandler handlerFull
```

### Why This Works

At JavaScript runtime, `{ body: x }` is identical to `{ body: x, query: undefined, headers: undefined }`. The `coerceHandler` function safely bridges these types via `unsafeCoerce`, which is safe because:

1. **Same runtime representation**: Both are JS objects with the same fields
2. **Missing fields are undefined**: JS semantics guarantee this
3. **Parsers provide defaults**: `undefined` is parsed as empty `{}` or `NoBody`

See [`docs/FIELD_OMISSION.md`](./FIELD_OMISSION.md) for complete explanation and examples.

### Union Constraint

The endpoint uses a Union constraint to validate field compatibility:

```purescript
endpoint2
  :: forall path request o_ query headers body response
   . Union request o_ (query :: query, headers :: headers, body :: body)
  => ...
```

This ensures the user's partial request (e.g., `{ body :: ... }`) can be merged with defaults to form a valid full request. The Union constraint validates compatibility without changing the endpoint's type, and `coerceHandler` bridges to full types via JavaScript runtime equivalence.

## Testing

See [`test/RequestBodySpec.purs`](../packages/yoga-fastify-om/test/RequestBodySpec.purs) for complete working examples showing:

- Body-only requests (lines 58-85)
- No-body requests (lines 91-110)  
- Query + Body (lines 116-141)
- Headers + Body (lines 149-175)
- All three fields (lines 182-206)
- Pattern matching on wrapped body
- Type safety demonstrations

**All 55 tests passing!**
