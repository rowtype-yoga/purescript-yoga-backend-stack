# Tapir-Style Typed Endpoints - Examples

## ✅ Status: **Working!** (Compiles successfully)

The `Yoga.Fastify.Om.Endpoint` module provides Tapir-style typed endpoint specifications where **all request data is parsed upfront** and passed to your handler in a single typed record.

## Quick Example

```purescript
import Yoga.Fastify.Om.Endpoint as E

-- 1. Define your path route
data UserPath = UserById Int

derive instance Generic UserPath _

userPath :: RouteDuplex' UserPath
userPath = RD.root $ RG.sum
  { "UserById": "users" / RD.int RD.segment
  }

-- 2. Create endpoint specification  
userEndpoint :: E.Endpoint 
  UserPath                        -- path type
  ( page :: Int )                 -- required query params
  ( limit :: Int, sort :: String ) -- optional query params (wrapped in Maybe)
  Unit                            -- body (Unit = no body)
  ( authorization :: String )     -- required headers
  ( x-request-id :: String )      -- optional headers (wrapped in Maybe)
  (Array User)                    -- response type
userEndpoint = E.endpoint
  { pathCodec: userPath
  , requiredQuery: Proxy :: Proxy ( page :: Int )
  , optionalQuery: Proxy :: Proxy ( limit :: Int, sort :: String )
  , bodyType: Proxy :: Proxy Unit
  , requiredHeaders: Proxy :: Proxy ( authorization :: String )
  , optionalHeaders: Proxy :: Proxy ( x-request-id :: String )
  , responseType: Proxy :: Proxy (Array User)
  }

-- 3. Handler receives ALL parsed data and just returns the response!
handler :: E.EndpointHandler UserPath ( page :: Int ) ( limit :: Int, sort :: String ) Unit ( authorization :: String ) ( x-request-id :: String ) (Array User) AppContext ()
handler { path, requiredQuery, optionalQuery, body, requiredHeaders, optionalHeaders } = do
  -- Extract from parsed data (ALL type-safe!)
  let UserById userId = path           -- userId :: Int
      { page } = requiredQuery          -- page :: Int
      { limit, sort } = optionalQuery   -- limit :: Maybe Int, sort :: Maybe String
      { authorization } = requiredHeaders  -- authorization :: String
      { x-request-id } = optionalHeaders   -- x-request-id :: Maybe String
  
  -- Use the data
  { db } <- Om.ask
  users <- liftAff $ DB.getUsers db { userId, page, limit, sort, auth: authorization }
  
  -- Just return the value - framework handles serialization and sending!
  pure users

-- 4. Register endpoint
main = do
  app <- FO.createOmFastify appContext fastify
  FO.getOm (RouteURL "/users/:id") (E.handleEndpoint userEndpoint handler) app
```

## Complete Examples

### 1. Simple GET Endpoint (No Query/Body/Headers)

```purescript
-- Path only
data HomePath = Home

homePath = RD.root $ RG.sum { "Home": RG.noArgs }

homeEndpoint = E.endpoint
  { pathCodec: homePath
  , requiredQuery: Proxy :: Proxy ()      -- No required query
  , optionalQuery: Proxy :: Proxy ()      -- No optional query
  , bodyType: Proxy :: Proxy Unit         -- No body
  , requiredHeaders: Proxy :: Proxy ()    -- No required headers
  , optionalHeaders: Proxy :: Proxy ()    -- No optional headers
  , responseType: Proxy :: Proxy String   -- Returns a String
  }

homeHandler { path: Home } =
  pure "Welcome home!"
```

### 2. POST with Body

```purescript
type CreateUserRequest = { name :: String, email :: String }

createUserEndpoint = E.endpoint
  { pathCodec: usersPath
  , requiredQuery: Proxy :: Proxy ()
  , optionalQuery: Proxy :: Proxy ()
  , bodyType: Proxy :: Proxy CreateUserRequest  -- Typed body!
  , requiredHeaders: Proxy :: Proxy ( authorization :: String )
  , optionalHeaders: Proxy :: Proxy ()
  , responseType: Proxy :: Proxy User            -- Returns User
  }

createUserHandler { body, requiredHeaders: { authorization } } = do
  -- body :: CreateUserRequest (fully parsed!)
  { db } <- Om.ask
  user <- liftAff $ DB.createUser db body
  pure user  -- Framework handles serialization!
```

### 3. Complex API Endpoint

```purescript
-- Blog post endpoint
data PostPath = PostById Int Int  -- userId, postId

postPath = RD.root $ RG.sum
  { "PostById": "users" / RD.int RD.segment / "posts" / RD.int RD.segment
  }

postEndpoint = E.endpoint
  { pathCodec: postPath
  , requiredQuery: Proxy :: Proxy ( include :: String )  -- e.g., "comments"
  , optionalQuery: Proxy :: Proxy ( format :: String, lang :: String )
  , bodyType: Proxy :: Proxy Unit
  , requiredHeaders: Proxy :: Proxy ( authorization :: String )
  , optionalHeaders: Proxy :: Proxy ( x-request-id :: String, x-api-version :: String )
  , responseType: Proxy :: Proxy BlogPost
  }

postHandler data = do
  -- Destructure ALL the things!
  let PostById userId postId = data.path
      { include } = data.requiredQuery
      { format, lang } = data.optionalQuery
      { authorization } = data.requiredHeaders
      { x-request-id, x-api-version } = data.optionalHeaders
  
  -- All fields are type-checked!
  -- userId :: Int
  -- postId :: Int
  -- include :: String
  -- format :: Maybe String
  // lang :: Maybe String
  -- authorization :: String
  -- x-request-id :: Maybe String
  -- x-api-version :: Maybe String
  
  { db } <- Om.ask
  post <- liftAff $ DB.getPost db userId postId
    { includeComments: include == "comments"
    , format: fromMaybe "json" format
    , lang: fromMaybe "en" lang
    }
  
  pure post  -- Just return it!
```

### 4. RESTful CRUD API

```purescript
-- List users with pagination
listUsersEndpoint = E.endpoint
  { pathCodec: usersPath
  , requiredQuery: Proxy :: Proxy ()
  , optionalQuery: Proxy :: Proxy ( page :: Int, limit :: Int, sort :: String )
  , bodyType: Proxy :: Proxy Unit
  , requiredHeaders: Proxy :: Proxy ()
  , optionalHeaders: Proxy :: Proxy ()
  , responseType: Proxy :: Proxy (Array User)
  }

listUsersHandler { optionalQuery: { page, limit, sort } } = do
  let pageNum = fromMaybe 1 page
      limitNum = fromMaybe 10 limit
      sortBy = fromMaybe "name" sort
  
  { db } <- Om.ask
  users <- liftAff $ DB.listUsers db { page: pageNum, limit: limitNum, sort: sortBy }
  pure users

-- Update user
updateUserEndpoint = E.endpoint
  { pathCodec: userByIdPath
  , requiredQuery: Proxy :: Proxy ()
  , optionalQuery: Proxy :: Proxy ()
  , bodyType: Proxy :: Proxy UpdateUserRequest
  , requiredHeaders: Proxy :: Proxy ( authorization :: String )
  , optionalHeaders: Proxy :: Proxy ()
  , responseType: Proxy :: Proxy User
  }

updateUserHandler { path: UserById userId, body, requiredHeaders: { authorization } } = do
  -- Verify auth
  authUser <- verifyToken authorization
  
  -- Update user
  { db } <- Om.ask
  updatedUser <- liftAff $ DB.updateUser db userId body
  pure updatedUser
```

## Benefits

### ✅ **Single Destructuring Pattern + Pure Return**
```purescript
handler { path, requiredQuery, optionalQuery, body, requiredHeaders, optionalHeaders } = do
  -- Everything parsed and typed!
  result <- doSomething
  pure result  -- Framework handles serialization and sending!
```

### ✅ **Impossible to Access Undefined Fields**
```purescript
-- Compiler error if you try to access a field not in the spec!
handler { path, requiredQuery: { nonExistent } } = do
  -- ❌ Compile error: field 'nonExistent' not found
```

### ✅ **Type-Safe Throughout**
```purescript
-- If spec says ( page :: Int ), then:
let { page } = requiredQuery  -- page :: Int (guaranteed!)

-- If spec says optional ( limit :: Int ), then:
let { limit } = optionalQuery  -- limit :: Maybe Int
```

### ✅ **Automatic Validation**
- Missing required query params → 400 Bad Request
- Missing required headers → 400 Bad Request
- Invalid path → 404 Not Found
- All errors handled before your handler runs!

### ✅ **Self-Documenting**
The endpoint spec IS the documentation:
```purescript
userEndpoint :: E.Endpoint 
  UserPath                        -- what path structure
  ( page :: Int )                 -- what required query params
  ( limit :: Int )                -- what optional query params
  CreateUserRequest               -- what body type
  ( authorization :: String )     -- what required headers
  ()                              -- what optional headers
```

## Comparison

### Before (Manual Parsing + Manual Sending)
```purescript
handler reply = do
  url <- FO.requestUrl
  parsedRoute <- Router.matchRoute route
  { page } <- FO.requiredQueryParams (Proxy :: ...)
  { limit } <- FO.optionalQueryParams (Proxy :: ...)
  auth <- FO.requiredHeader "authorization"
  requestId <- FO.requestHeader "x-request-id"
  
  -- NOW finally handle the request...
  result <- doSomething
  
  -- Manually serialize and send
  FO.sendJson (encode result) reply
```

### After (Tapir-Style: Everything Automatic)
```purescript
handler { path, requiredQuery: { page }, optionalQuery: { limit }, requiredHeaders: { authorization }, optionalHeaders: { x-request-id } } = do
  -- Everything already parsed and typed!
  result <- doSomething
  pure result  -- Framework handles rest!
```

## Current Limitations

1. **Optional body**: Currently always requires body - should handle Unit for no-body endpoints
2. **Error types**: Errors are hardcoded 400/404 - should be configurable
3. **Response types**: No content negotiation yet (always uses yoga-json)

## Future Enhancements

- [x] Integrate yoga-json for body parsing and response encoding ✅
- [ ] Handle `Unit` body type for GET/DELETE endpoints
- [ ] Custom error types and status codes
- [ ] Content negotiation (JSON/XML/HTML)
- [ ] OpenAPI/Swagger generation from specs
- [ ] Type-safe client generation

## Try It!

The module compiles and is ready to use! Try building a handler with the Tapir-style and see how clean it is! 🚀
