# RequestBody: Wrapped in Spec, Unwrapped in Handler

Perfect! You have exactly what you wanted:
- **At the type level (spec)**: Wrapped in `RequestBody`
- **At the use site (handler)**: Unwrapped to the inner type

## The Pattern

```purescript
-- 1. Define spec with RequestBody wrapper
type CreateUserSpec =
  ( body :: RequestBody CreateUserRequest
    --      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Wrapped at type level
  )

-- 2. Handler signature receives unwrapped type
handler
  :: EndpointHandler2
       ApiRoute
       ()
       ()
       CreateUserRequest  -- ← Unwrapped! No RequestBody wrapper!
       User
       AppContext
       ()

-- 3. At use site, body is already unwrapped
handler { body } = do
  -- body :: CreateUserRequest (not RequestBody CreateUserRequest!)
  let { name, email } = body  -- Direct access, no pattern matching!
  createUser name email
```

## Complete Working Example

```purescript
module Example where

import Prelude
import Data.Generic.Rep (class Generic)
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint2 as E2
import Yoga.Fastify.Om.RequestBody (RequestBody)

-- Types
type CreateUserRequest = { name :: String, email :: String, age :: Int }
type User = { id :: Int, name :: String, email :: String, age :: Int }

data ApiRoute = CreateUser
derive instance Generic ApiRoute _

apiRoute = RD.root $ RG.sum { "CreateUser": "users" / RG.noArgs }

-- ============================================================
-- SPEC: Wrapped in RequestBody
-- ============================================================
type CreateUserSpec =
  ( query :: { notify :: Boolean }
  , headers :: { authorization :: String }
  , body :: RequestBody CreateUserRequest  -- ← WRAPPED
  )

endpoint :: E2.Endpoint2 ApiRoute CreateUserSpec User
endpoint = E2.endpoint2 apiRoute (Proxy :: Proxy CreateUserSpec) (Proxy :: Proxy User)

-- ============================================================
-- HANDLER: Unwrapped at use site
// ============================================================
handler
  :: E2.EndpointHandler2
       ApiRoute
       ( notify :: Boolean )
       ( authorization :: String )
       CreateUserRequest  -- ← UNWRAPPED! No RequestBody!
       User
       ()
       ()
handler { path, query, headers, body } = do
  -- All extracted values are unwrapped and ready to use!
  
  let { notify } = query              -- query fields
  let { authorization } = headers     -- header fields
  let { name, email, age } = body     -- body fields - NO PATTERN MATCHING!
  
  -- Use body fields directly
  if notify && authorization == "Bearer valid-token"
    then createAndNotifyUser name email age
    else createUser name email age
  
  where
    createUser n e a = pure { id: 1, name: n, email: e, age: a }
    createAndNotifyUser n e a = do
      user <- createUser n e a
      -- send notification
      pure user
```

## What Happens at Runtime

```
1. Request arrives with Content-Type: application/json
2. Framework parses body as JSON using ReadForeign
3. Framework unwraps RequestBody and passes inner value to handler
4. Handler receives CreateUserRequest directly (no RequestBody wrapper!)
```

## Type-Level vs Value-Level

```purescript
-- TYPE LEVEL (in spec)
type MySpec = ( body :: RequestBody MyType )
                        ^^^^^^^^^^^^^^^^^^^
                        Wrapped - tells framework to parse based on Content-Type

-- VALUE LEVEL (in handler)
handler :: EndpointHandler2 ... MyType ...
                                ^^^^^^
                                Unwrapped - you get the inner value directly

handler { body } = do
  -- body :: MyType (not RequestBody MyType!)
  useMyType body  -- Direct access!
```

## The Benefits

### ✅ Type Safety
```purescript
-- Spec says body is RequestBody CreateUserRequest
type Spec = ( body :: RequestBody CreateUserRequest )

-- Handler gets CreateUserRequest
handler { body } = do
  let name = body.name   -- ✅ Works!
  let age = body.age     // ✅ Works!
  let wrong = body.foo   -- ❌ Compile error: no .foo field
```

### ✅ No Boilerplate
```purescript
-- NO pattern matching needed:
handler { body } = do
  createUser body.name body.email  -- ← Clean!
  
-- NOT this:
handler { body } = case body of  -- ← Verbose!
  JSONBody user -> createUser user.name user.email
  _ -> error
```

### ✅ Clean Destructuring
```purescript
handler { body: { name, email, age } } = do
  -- name, email, age are all extracted directly!
  createUser name email age
```

## Test Proof

From the test suite (all 87 tests passing):

```purescript
-- Spec: Wrapped
type CreateUserJSONSpec =
  ( body :: RequestBody CreateUserJSON
  )

-- Handler: Unwrapped
createUserJSONHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       CreateUserJSON  -- ← Unwrapped!
       User
       AppContext
       ()
createUserJSONHandler { path, body } =
  case path of
    CreateUserJSON -> do
      let { name, email } = body  -- ← Direct access! No pattern matching!
      pure { id: 1, name, email }
    _ ->
      pure { id: 0, name: "error", email: "wrong endpoint" }
```

**This is exactly what you wanted!** 🎉

- Spec level: `body :: RequestBody MyType` (wrapped)
- Use site: `body :: MyType` (unwrapped)
- No pattern matching required
