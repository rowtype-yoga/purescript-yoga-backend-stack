# Endpoint2 API Ergonomics Examples

## Complete Working Example

```purescript
module Example.UserAPI where

import Prelude
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Routing.Duplex.Generic.Syntax ((/))
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint2 as E2
import Yoga.Fastify.Om.RequestBody (RequestBody(..))

-- ============================================================================
-- 1. Define your API routes
-- ============================================================================

data ApiRoute
  = CreateUser
  | GetUser Int
  | UpdateUser Int
  | ListUsers

apiRoute :: RouteDuplex' ApiRoute
apiRoute = RD.root $ RG.sum
  { "CreateUser": "users" / RG.noArgs
  , "GetUser": "users" / RG.int RG.segment
  , "UpdateUser": "users" / RG.int RG.segment
  , "ListUsers": "users" / RG.noArgs
  }

-- ============================================================================
-- 2. Define your types
-- ============================================================================

type User = { id :: Int, name :: String, email :: String }
type CreateUserReq = { name :: String, email :: String }
type UpdateUserReq = { name :: String }

-- ============================================================================
-- 3. Simple JSON endpoint - Just body
-- ============================================================================

-- MINIMAL TYPE: Only specify what you need!
type CreateUserRequest = { body :: RequestBody CreateUserReq }

-- ENDPOINT: One line!
createUserEndpoint :: E2.Endpoint2 ApiRoute CreateUserRequest User
createUserEndpoint = E2.endpoint2 apiRoute (Proxy :: _ CreateUserRequest) (Proxy :: _ User)

-- HANDLER: Pattern match on body, get typed data
createUserHandler :: E2.EndpointHandler2 ApiRoute CreateUserRequest User ctx ()
createUserHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      -- Create user logic here
      pure { id: 1, name, email }
    
    CreateUser, NoBody -> 
      -- Handle missing body
      throwError "Body required"
    
    _, _ -> 
      throwError "Wrong endpoint"

-- ============================================================================
-- 4. With query parameters
-- ============================================================================

type ListUsersRequest =
  { query :: { page :: Int, limit :: Maybe Int, search :: Maybe String }
  , body :: RequestBody Unit  -- No body needed
  }

listUsersEndpoint :: E2.Endpoint2 ApiRoute ListUsersRequest (Array User)
listUsersEndpoint = E2.endpoint2 apiRoute (Proxy :: _ ListUsersRequest) (Proxy :: _ (Array User))

listUsersHandler :: E2.EndpointHandler2 ApiRoute ListUsersRequest (Array User) ctx ()
listUsersHandler { path, request } =
  case path of
    ListUsers -> do
      let { page, limit, search } = request.query
      -- Use query params
      pure []  -- Return users
    _ -> 
      throwError "Wrong endpoint"

-- ============================================================================
-- 5. With authentication headers
-- ============================================================================

type UpdateUserRequest =
  { headers :: { authorization :: String }
  , body :: RequestBody UpdateUserReq
  }

updateUserEndpoint :: E2.Endpoint2 ApiRoute UpdateUserRequest User
updateUserEndpoint = E2.endpoint2 apiRoute (Proxy :: _ UpdateUserRequest) (Proxy :: _ User)

updateUserHandler :: E2.EndpointHandler2 ApiRoute UpdateUserRequest User ctx ()
updateUserHandler { path, request } =
  case path, request.body of
    UpdateUser userId, JSONBody { name } -> do
      let { authorization } = request.headers
      
      -- Verify auth
      when (authorization /= "Bearer valid-token") do
        throwError "Unauthorized"
      
      -- Update user
      pure { id: userId, name, email: "unchanged@example.com" }
    
    _, _ -> 
      throwError "Wrong endpoint"

-- ============================================================================
-- 6. Full request with everything
-- ============================================================================

type CreateUserFullRequest =
  { query :: { notify :: Boolean }
  , headers :: { authorization :: String, xRequestId :: Maybe String }
  , body :: RequestBody CreateUserReq
  }

createUserFullEndpoint :: E2.Endpoint2 ApiRoute CreateUserFullRequest User
createUserFullEndpoint = E2.endpoint2 apiRoute (Proxy :: _ CreateUserFullRequest) (Proxy :: _ User)

createUserFullHandler :: E2.EndpointHandler2 ApiRoute CreateUserFullRequest User ctx ()
createUserFullHandler { path, request } =
  case path, request.body of
    CreateUser, JSONBody { name, email } -> do
      let 
        { notify } = request.query
        { authorization, xRequestId } = request.headers
        verified = authorization == "Bearer valid-token"
      
      -- All fields available and typed!
      when (not verified) do
        throwError "Unauthorized"
      
      when notify do
        -- Send notification
        pure unit
      
      pure { id: 1, name, email }
    
    _, _ -> 
      throwError "Wrong endpoint"

-- ============================================================================
-- 7. Register endpoints with Fastify
-- ============================================================================

registerRoutes :: FastifyInstance -> Effect Unit
registerRoutes app = launchAff_ do
  -- POST /users - Create user
  FO.post app "/users" \reply -> 
    E2.handleEndpoint2 createUserEndpoint createUserHandler reply
  
  -- GET /users - List users with query params
  FO.get app "/users" \reply ->
    E2.handleEndpoint2 listUsersEndpoint listUsersHandler reply
  
  -- PATCH /users/:id - Update user with auth
  FO.patch app "/users/:id" \reply ->
    E2.handleEndpoint2 updateUserEndpoint updateUserHandler reply
```

## What Makes It Ergonomic?

### ✅ Minimal Type Specifications

```purescript
-- Only specify what you need!
type SimpleRequest = { body :: RequestBody CreateUser }

-- Union constraint fills in the rest
-- Union { body :: RequestBody CreateUser } o_ { query :: q, headers :: h, body :: RequestBody CreateUser }
```

### ✅ Single Record Parameter

```purescript
-- Before (multiple params):
handler query headers body -> ...

-- After (one record):
handler { path, request } -> ...
```

### ✅ Pattern Matching on Body Type

```purescript
case path, request.body of
  CreateUser, JSONBody data -> ...  -- Type-safe!
  CreateUser, NoBody -> ...         -- Handle missing body
  _, FormData fields -> ...         -- Other content types
```

### ✅ Clean Field Access

```purescript
let { page, limit } = request.query      -- Typed query params
let { authorization } = request.headers  -- Typed headers
let { name, email } = userData           -- Typed body
```

### ✅ Type Safety Everywhere

```purescript
-- Compiler checks:
✓ Request type matches endpoint
✓ Handler signature matches endpoint
✓ All pattern matches are exhaustive
✓ Field access is type-safe
✓ No typos in field names
```

### ✅ Field Omission via Union

```purescript
-- Can omit fields you don't use
type BodyOnly = { body :: RequestBody A }               -- ✅
type QueryAndBody = { query :: Q, body :: RequestBody A }  -- ✅
type Full = { query :: Q, headers :: H, body :: RequestBody A }  -- ✅

-- Union constraint ensures they all work!
```

## Comparison with Other Approaches

### Old Approach (Multiple Type Parameters)

```purescript
-- ❌ Verbose type signatures
type Endpoint path query headers body response = ...

-- ❌ Handler receives 5+ parameters
handler :: path -> query -> headers -> body -> Maybe error -> Effect response

-- ❌ Hard to add new fields
```

### Endpoint2 Approach (Single Record)

```purescript
-- ✅ Clean type signature
type Endpoint2 path request response = ...

-- ✅ Handler receives 1 parameter
handler :: { path :: path, request :: request } -> Om ctx err response

-- ✅ Easy to extend with new fields
```

## Real-World Example: REST API

```purescript
-- POST /api/posts - Create post with auth
type CreatePostRequest =
  { headers :: { authorization :: String }
  , body :: RequestBody { title :: String, content :: String }
  }

createPost :: E2.Endpoint2 ApiRoute CreatePostRequest Post
createPost = E2.endpoint2 apiRoute (Proxy :: _ CreatePostRequest) (Proxy :: _ Post)

handleCreatePost :: E2.EndpointHandler2 ApiRoute CreatePostRequest Post ctx ()
handleCreatePost { path, request } =
  case path, request.body of
    CreatePost, JSONBody { title, content } -> do
      -- Auth check
      userId <- verifyAuth request.headers.authorization
      
      -- Create post
      postId <- insertPost { userId, title, content }
      
      pure { id: postId, title, content, authorId: userId }
    
    _, _ -> throwError "Invalid request"

-- GET /api/posts - List posts with filtering
type ListPostsRequest =
  { query :: { authorId :: Maybe Int, tag :: Maybe String, page :: Int }
  , body :: RequestBody Unit
  }

listPosts :: E2.Endpoint2 ApiRoute ListPostsRequest (Array Post)
listPosts = E2.endpoint2 apiRoute (Proxy :: _ ListPostsRequest) (Proxy :: _ (Array Post))

handleListPosts :: E2.EndpointHandler2 ApiRoute ListPostsRequest (Array Post) ctx ()
handleListPosts { path, request } =
  case path of
    ListPosts -> do
      let { authorId, tag, page } = request.query
      
      -- Build query with filters
      posts <- queryPosts
        # filterByAuthor authorId
        # filterByTag tag
        # paginate page 20
      
      pure posts
    
    _ -> throwError "Wrong endpoint"
```

## Verdict: ✅ Very Ergonomic!

1. **Minimal boilerplate** - Only specify fields you need
2. **Type-safe** - Compiler catches all mistakes
3. **Clean syntax** - Single record parameter, pattern matching
4. **Flexible** - Field omission via Union constraint
5. **Explicit** - RequestBody wrapper makes content types clear
6. **Extensible** - Easy to add new field types

**Ready to replace the old endpoint system!**
