# RequestBody ADT: Multiple Content Type Support

The `RequestBody` sum type enables endpoints to accept different content formats (JSON, forms, text, binary) with full type safety.

## The RequestBody Type

```purescript
data RequestBody a
  = JSONBody a                -- JSON body (parsed via yoga-json ReadForeign)
  | NoBody                    -- No body provided
  | FormData (Object String)  -- URL-encoded form data
  | TextBody String           -- Plain text body
  | BytesBody Foreign         -- Binary data (Buffer/ArrayBuffer)
```

## Content-Type Based Parsing

The framework automatically parses the request body based on the `Content-Type` header:

| Content-Type | RequestBody Variant | Parsed As |
|-------------|-------------------|-----------|
| `application/json` | `JSONBody a` | Typed JSON via `ReadForeign` |
| `application/x-www-form-urlencoded` | `FormData` | Key-value pairs |
| `text/plain` | `TextBody` | Raw string |
| `application/octet-stream` | `BytesBody` | Raw binary (Foreign) |
| (missing) | `NoBody` | Unit |

## Examples

### Example 1: JSON API (Standard)

```purescript
type CreateUserRequest = { name :: String, email :: String }

type CreateUserSpec =
  ( body :: RequestBody CreateUserRequest
  )

createUserEndpoint = endpoint2 route (Proxy :: Proxy CreateUserSpec) (Proxy :: Proxy User)

handler { body } = case body of
  JSONBody user -> do
    -- user :: CreateUserRequest (fully typed!)
    let { name, email } = user
    newUser <- createUser name email
    pure newUser
  
  NoBody -> 
    -- Handle missing body
    pure errorResponse
  
  _ ->
    -- Reject other content types for this endpoint    pure unsupportedMediaResponse
```

### Example 2: File Upload (Binary)

```purescript
type UploadSpec =
  ( headers :: { contentType :: String, filename :: Maybe String }
  , body :: RequestBody Unit  -- Unit means: parse based on Content-Type
  )

uploadEndpoint = endpoint2 route (Proxy :: Proxy UploadSpec) (Proxy :: Proxy UploadResponse)

handler { headers, body } = case body of
  BytesBody buffer -> do
    -- buffer :: Foreign (raw bytes)
    let { contentType, filename } = headers
    fileId <- saveFile buffer contentType filename
    pure { success: true, fileId }
  
  NoBody ->
    pure { success: false, error: "No file provided" }
  
  _ ->
    pure { success: false, error: "Expected binary upload" }
```

### Example 3: Form Submission

```purescript
type SubmitFormSpec =
  ( body :: RequestBody Unit  -- Will be parsed as FormData
  )

formEndpoint = endpoint2 route (Proxy :: Proxy SubmitFormSpec) (Proxy :: Proxy FormResponse)

handler { body } = case body of
  FormData fields -> do
    -- fields :: Object String
    let name = Object.lookup "name" fields
        email = Object.lookup "email" fields
    
    case name, email of
      Just n, Just e -> do
        user <- createUser n e
        pure { success: true, userId: user.id }
      _, _ ->
        pure { success: false, error: "Missing fields" }
  
  _ ->
    pure { success: false, error: "Expected form data" }
```

### Example 4: Plain Text Processing

```purescript
type ProcessTextSpec =
  ( body :: RequestBody Unit  -- Will be parsed as TextBody
  )

textEndpoint = endpoint2 route (Proxy :: Proxy ProcessTextSpec) (Proxy :: Proxy ProcessResponse)

handler { body } = case body of
  TextBody text -> do
    -- text :: String
    result <- analyzeText text
    pure { wordCount: result.words, sentiment: result.sentiment }
  
  NoBody ->
    pure { wordCount: 0, sentiment: "neutral" }
  
  _ ->
    pure errorResponse
```

### Example 5: Multi-Format Endpoint

Handle multiple content types in a single endpoint:

```purescript
type MultiFormatSpec =
  ( body :: RequestBody CreateUserRequest
  )

multiEndpoint = endpoint2 route (Proxy :: Proxy MultiFormatSpec) (Proxy :: Proxy User)

handler { body } = case body of
  JSONBody user -> do
    -- Standard JSON API
    createUser user.name user.email
  
  FormData fields -> do
    -- HTML form submission
    case Object.lookup "name" fields, Object.lookup "email" fields of
      Just n, Just e -> createUser n e
      _, _ -> pure errorResponse
  
  TextBody csv -> do
    -- CSV import
    users <- parseCSV csv
    createManyUsers users
  
  BytesBody buffer -> do
    -- Binary import (e.g., Protobuf, MessagePack)
    users <- deserializeBinary buffer
    createManyUsers users
  
  NoBody ->
    pure errorResponse
```

## Type Safety

### Typed JSON Bodies

```purescript
type UserSpec = ( body :: RequestBody CreateUserRequest )

handler { body } = case body of
  JSONBody user -> do
    -- user :: CreateUserRequest
    -- Compiler knows the exact type!    -- If CreateUserRequest changes, handler must change
    let { name, email } = user  -- Autocomplete works!
    pure response
  _ -> pure error
```

### Content-Type Validation

The framework validates Content-Type headers and returns appropriate errors:

- Missing required body → 400 "Request body is required"
- Invalid JSON → 400 "Invalid JSON body: <details>"
- Unsupported Content-Type → 400 "Unsupported Content-Type: <type>"

## Pattern Matching Best Practices

### Handle All Variants

```purescript
-- ✅ Good: Handle all cases
handler { body } = case body of
  JSONBody user -> createFromJSON user
  FormData fields -> createFromForm fields
  TextBody text -> createFromText text
  BytesBody bytes -> createFromBytes bytes
  NoBody -> pure errorResponse

-- ⚠️ Compiler warns if you forget a case
handler { body } = case body of
  JSONBody user -> createFromJSON user
  _ -> pure errorResponse  -- Others fallback to error
```

### Type-Specific Handling

```purescript
-- For JSON-only endpoints
handler { body } = case body of
  JSONBody user -> do
    -- Only accept JSON
    createUser user
  _ -> 
    -- Reject other formats    pure { error: "Only JSON is supported" }
```

## Advanced: Custom Body Parsers

You can extend `ParseRequestBody` for custom types:

```purescript
instance ParseRequestBody MyCustomType where
  parseRequestBody headers bodyMaybe =
    case Object.lookup "content-type" headers of
      Just "application/x-my-format" ->
        -- Custom parsing logic
        case bodyMaybe of
          Just foreign -> Right (JSONBody (customParse foreign))
          Nothing -> Right NoBody
      _ -> Left "Unsupported content type"
```

## Testing

See [`test/RequestBodySpec.purs`](../packages/yoga-fastify-om/test/RequestBodySpec.purs) for comprehensive examples showing:

- JSONBody with typed request
- FormData with key-value pairs
- TextBody with plain strings
- BytesBody with binary data
- NoBody for endpoints without bodies
- Pattern matching strategies
- Type safety demonstrations

All tests pass, proving the RequestBody ADT works across all content types!

## Benefits

1. ✅ **Content negotiation** - Single endpoint handles multiple formats
2. ✅ **Type safety** - JSONBody is typed, compiler validates structure
3. ✅ **Pattern matching** - Exhaustive case analysis ensures all formats handled
4. ✅ **Extensible** - Add custom content types via instances
5. ✅ **Clear intent** - Handler explicitly shows what formats it supports
