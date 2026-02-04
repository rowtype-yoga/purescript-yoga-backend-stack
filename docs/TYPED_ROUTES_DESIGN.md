# Typed Route Specifications (Tapir-style)

## Vision

Create a type-level API specification system similar to Scala's Tapir, but leveraging PureScript's row types:

```purescript
-- Define a complete typed endpoint specification
type UserEndpoint = RouteSpec
  { path :: User Int                    -- routing-duplex route with user ID
  , query :: ( page :: Int              -- required query param
             , limit :: Maybe Int       -- optional query param  
             )
  , body :: CreateUserRequest           -- typed request body
  , headers :: ( authorization :: String         -- required header
               , x-request-id :: Maybe String    -- optional header
               )
  }

-- Handler receives fully parsed, typed data
userHandler :: ParsedRoute UserEndpoint -> FastifyReply -> Om ctx () Unit
userHandler { path: User userId, query: { page, limit }, body, headers } reply = do
  -- All fields are type-checked and parsed!
  -- userId :: Int
  -- page :: Int
  -- limit :: Maybe Int
  -- body :: CreateUserRequest
  -- headers.authorization :: String
  -- headers.x-request-id :: Maybe String
  
  user <- createUser userId body
  FO.sendJson reply user

-- Register the endpoint
main = do
  app <- FO.createOmFastify appContext fastify
  FO.postOm (RouteURL "/users/:id") (handleRoute userEndpoint userHandler) app
```

## Design Challenges

### 1. Distinguishing Required vs Optional Fields

**Problem**: In row types, we want:
- `page :: Int` = required query param
- `limit :: Maybe Int` = optional query param

**Current PureScript Limitation**: Type class instance resolution can't easily distinguish between `ty` and `Maybe ty` without overlapping instances.

**Solutions**:
1. **Explicit marker types**:
   ```purescript
   type query :: ( page :: Required Int, limit :: Optional Int )
   ```

2. **Separate rows**:
   ```purescript
   { requiredQuery :: ( page :: Int )
   , optionalQuery :: ( limit :: Int )  -- All wrapped in Maybe during parsing
   }
   ```

3. **Custom type-level reflection** (complex)

### 2. Body Parsing

**Challenge**: Bodies can be:
- JSON (needs yoga-json ReadForeign)
- Form data
- Binary/streams
- No body (Unit)

**Solution**: Type-level dispatch based on body type:
```purescript
class ParseBody body where
  parseBody :: Foreign -> Om ctx (bodyError :: String) body

instance ParseBody Unit where
  parseBody _ = pure unit

instance ReadForeign a => ParseBody a where
  parseBody = J.readJSON
```

### 3. Complete Type Safety

**The Dream**:
```purescript
-- Endpoint specification is the single source of truth
userEndpoint :: EndpointSpec
  { method :: POST
  , path :: "/users/:id"
  , pathParams :: ( id :: Int )
  , query :: ( page :: Int, limit :: Maybe Int )
  , body :: CreateUserRequest
  , headers :: ( auth :: String )
  , response :: User
  , errors :: ( notFound :: UserNotFoundError, unauthorized :: AuthError )
  }

-- Handler type is derived from spec!
handler :: EndpointHandler userEndpoint
handler = ...

-- Client function generated automatically
callUserEndpoint :: Int -> CreateUserRequest -> Aff (Either Errors User)
```

## Pragmatic Implementation (Phase 1)

Given PureScript's current capabilities, here's a practical first version:

```purescript
-- Separate required and optional explicitly
type UserRouteSpec = RouteSpec
  UserPath                               -- routing-duplex path
  ( page :: Int )                        -- required query params
  ( limit :: Int )                       -- optional query params (wrapped in Maybe)
  CreateUserRequest                      -- body
  ( authorization :: String )            -- required headers
  ( x-request-id :: String )             -- optional headers (wrapped in Maybe)

userRoute :: UserRouteSpec
userRoute = RouteSpec
  { pathCodec: userPathCodec
  , requiredQuery: Proxy :: Proxy ( page :: Int )
  , optionalQuery: Proxy :: Proxy ( limit :: Int )
  , body: Proxy :: Proxy CreateUserRequest
  , requiredHeaders: Proxy :: Proxy ( authorization :: String )
  , optionalHeaders: Proxy :: Proxy ( x-request-id :: String )
  }

-- Parsed result
type ParsedRoute spec =
  { path :: PathType spec
  , requiredQuery :: Record (RequiredQueryType spec)
  , optionalQuery :: Record (OptionalQueryType spec)  -- All Maybe-wrapped
  , body :: BodyType spec
  , requiredHeaders :: Record (RequiredHeadersType spec)
  , optionalHeaders :: Record (OptionalHeadersType spec)  -- All Maybe-wrapped
  }
```

## Implementation Roadmap

### Phase 1: Basic Structure ✅ (Skeleton exists)
- [x] Route spec type
- [x] Query/header parsing typeclasses
- [x] Integration with Om error handling

### Phase 2: Separate Required/Optional
- [ ] Split query into `requiredQuery` and `optionalQuery`
- [ ] Split headers into `requiredHeaders` and `optionalHeaders`
- [ ] Update ParsedRoute type
- [ ] Test with real endpoints

### Phase 3: Body Parsing
- [ ] Integrate yoga-json ReadForeign
- [ ] Support different content types
- [ ] Handle form data
- [ ] Handle file uploads

### Phase 4: Response Types
- [ ] Specify response type in spec
- [ ] Type-safe response encoding
- [ ] Status code inference

### Phase 5: Error Types
- [ ] Specify error variants in spec
- [ ] Automatic Om error handling
- [ ] Error response encoding

### Phase 6: Documentation Generation
- [ ] OpenAPI/Swagger generation from specs
- [ ] Automatic API docs
- [ ] Type-safe client generation

## Comparison with Other Systems

### Scala Tapir
```scala
val userEndpoint: Endpoint[Int, ErrorInfo, User, Any] =
  endpoint.get
    .in("users" / path[Int]("userId"))
    .in(query[Int]("page"))
    .in(header[String]("Authorization"))
    .out(jsonBody[User])
    .errorOut(jsonBody[ErrorInfo])
```

### Haskell Servant
```haskell
type UserAPI = 
  "users" :> Capture "userId" Int 
          :> QueryParam "page" Int 
          :> Header "Authorization" String 
          :> Get '[JSON] User
```

### Our PureScript Version
```purescript
type UserEndpoint = RouteSpec
  (User Int)                           -- path
  ( page :: Int )                      -- query
  User                                  -- response body
  ( authorization :: String )          -- headers
```

## Benefits

1. **Type Safety**: Impossible to access undefined fields
2. **Single Source of Truth**: Route spec defines everything
3. **Refactor-Friendly**: Change type → compiler finds all issues
4. **Documentation**: Types are the documentation
5. **Testing**: Mock handlers with correct types
6. **Client Generation**: Generate type-safe client functions
7. **OpenAPI**: Generate specs automatically

## Current Status

**Skeleton exists** in `packages/yoga-fastify-om/src/Yoga/Fastify/Om/Route.purs`

**Blocked by**: Instance overlap for required vs optional fields

**Next Steps**: 
1. Redesign with explicit required/optional split
2. Implement body parsing with yoga-json
3. Create working example
4. Write comprehensive tests

## Open Questions

1. Should we use wrapper types (`Required Int`, `Optional Int`) or separate rows?
2. How to handle complex body types (multipart, streaming)?
3. Should response type be part of spec or separate?
4. How to generate OpenAPI from specs?
5. Can we generate type-safe client functions?

## References

- [Tapir Documentation](https://tapir.softwaremill.com/)
- [Servant Documentation](https://docs.servant.dev/)
- [purescript-routing-duplex](https://pursuit.purescript.org/packages/purescript-routing-duplex)
- [purescript-yoga-json](../packages/yoga-json) (TODO)
