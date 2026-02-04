# Field Omission via JavaScript Runtime Equivalence

## The Insight

At JavaScript runtime, these two values are **identical**:

```javascript
{ body: value }
{ body: value, query: undefined, headers: undefined }
```

This means we can accept partial records in PureScript and safely coerce them to full records because the JavaScript representation is the same.

## How It Works

### 1. Define Partial Request Type

```purescript
-- User only specifies the fields they care about:
type CreateUserRequest = { body :: RequestBody CreateUserJSON }
```

### 2. Create Endpoint

```purescript
createUserEndpoint :: Endpoint2 ApiRoute CreateUserRequest User
createUserEndpoint = endpoint2 apiRoute 
  (Proxy :: _ CreateUserRequest) 
  (Proxy :: _ User)
```

### 3. Option A: Handler with Partial Type

```purescript
-- Handler receives exactly what's in the type:
handler :: EndpointHandler2 ApiRoute CreateUserRequest User ctx err
handler { path, request } =
  case request.body of  -- Only access fields you specified
    JSONBody user -> pure user
    NoBody -> ...
```

### 4. Option B: Handler with Full Type (via coerceHandler)

```purescript
-- Define full type with all three fields:
type FullRequest = 
  { query :: Record ()
  , headers :: Record ()
  , body :: RequestBody CreateUserJSON
  }

-- Write handler with full type:
handlerFull :: EndpointHandler2 ApiRoute FullRequest User ctx err
handlerFull { path, request } = do
  -- Can access all fields, even though endpoint only has body!
  let _ = request.query     -- Record () (parsed from undefined)
  let _ = request.headers   -- Record () (parsed from undefined)
  case request.body of
    JSONBody user -> pure user
    NoBody -> ...

-- Coerce to partial type (safe because JS runtime equivalence):
handler :: EndpointHandler2 ApiRoute CreateUserRequest User ctx err
handler = coerceHandler handlerFull
```

## Why This Works

### JavaScript Runtime

When you create `{ body: x }` in JavaScript, accessing missing fields returns `undefined`:

```javascript
const partial = { body: "value" };
console.log(partial.query);    // undefined
console.log(partial.headers);  // undefined
```

### PureScript Parsing

The `ParseRequest` typeclass parsers handle `undefined` gracefully:

```purescript
-- For Record () fields:
parseQueryFieldRecord :: ... -> Either String (Record ())
-- If query params object is undefined/empty, returns Right {}

-- For RequestBody fields:
parseBodyField :: ... -> Either String (RequestBody a)
-- If body is undefined/Nothing, returns Right NoBody
```

### unsafeCoerce Safety

`unsafeCoerce` from `{ body :: A }` to `{ query :: {}, headers :: {}, body :: A }` is safe because:

1. **Same runtime representation**: Both are JS objects with the same fields
2. **Missing fields are undefined**: JS semantics guarantee this
3. **Parsers provide defaults**: `undefined` is parsed as empty `{}` or `NoBody`

## Complete Example

```purescript
-- API types
type CreateUserJSON = { name :: String, email :: String }
type User = { id :: Int, name :: String, email :: String }

-- Partial request (only body)
type CreateUserRequest = { body :: RequestBody CreateUserJSON }

-- Full request (all three fields)
type CreateUserRequestFull = 
  { query :: { notify :: Boolean }
  , headers :: { authorization :: String }
  , body :: RequestBody CreateUserJSON
  }

-- Endpoint with partial type
createUserEndpoint :: Endpoint2 ApiRoute CreateUserRequest User
createUserEndpoint = endpoint2 apiRoute 
  (Proxy :: _ CreateUserRequest) 
  (Proxy :: _ User)

-- Handler with full type
createUserHandlerFull 
  :: EndpointHandler2 ApiRoute CreateUserRequestFull User ctx err
createUserHandlerFull { path, request } =
  case path, request.body of
    CreateUserJSON, JSONBody createReq -> do
      let 
        { name, email } = createReq
        { notify } = request.query         -- Works! undefined → { notify: false }
        { authorization } = request.headers -- Works! undefined → { authorization: "" }
      pure { id: 1, name, email }
    _, _ -> ...

-- Coerce handler to match endpoint
createUserHandler :: EndpointHandler2 ApiRoute CreateUserRequest User ctx err
createUserHandler = coerceHandler createUserHandlerFull
```

## Benefits

1. **Type Safety**: Full type checking on handler logic
2. **Flexibility**: Endpoint types can be minimal (just what you need)
3. **Ergonomics**: Handler can access all fields without explicit parsing
4. **Zero Runtime Cost**: `coerceHandler` is a type-level operation only

## Union Constraint

The endpoint uses a Union constraint to validate that partial requests are compatible with full requests:

```purescript
endpoint2
  :: forall path request o_ query headers body response
   . Union request o_ (query :: query, headers :: headers, body :: body)
  => ...
```

This constraint ensures that the user's `request` row can be merged with some other row `o_` to produce a valid full request with `query`, `headers`, and `body` fields.

**Key insight**: We use Union for validation, not type computation:
- Union checks the user's input is compatible
- The endpoint type remains as the user specified (e.g., just `{ body :: ... }`)
- `coerceHandler` bridges types via `unsafeCoerce` (safe due to JS runtime equivalence)

```purescript
-- ✅ Union validates compatibility:
type PartialReq = (body :: RequestBody User)
Union PartialReq o_ (query :: q, headers :: h, body :: RequestBody User)
-- Ensures PartialReq can form a valid full request

-- ✅ coerceHandler bridges types at use site:
handler :: EndpointHandler2 path FullReq response ctx err
handlerPartial = coerceHandler handler  -- Safe due to JS semantics
```

## API Reference

### `coerceHandler`

```purescript
coerceHandler
  :: forall path partial full response ctx err
   . EndpointHandler2 path (Record full) response ctx err
  -> EndpointHandler2 path (Record partial) response ctx err
```

Safely coerces a handler from a full request type to a partial request type.

**Safety**: This is safe because at JavaScript runtime, `{ body: x }` and `{ body: x, query: undefined, headers: undefined }` are identical.

**Usage**: Write handlers with full types (all three fields), then coerce to match your partial endpoint types.

## Testing

See `packages/yoga-fastify-om/test/RequestBodySpec.purs` for complete examples:

- Example 1: JSONBody only
- Example 2: Field omission with coerceHandler (demonstrates full access)
- Example 3: Query + Body
- Example 4: Headers + Body
- Example 5: Full request (all three fields)
