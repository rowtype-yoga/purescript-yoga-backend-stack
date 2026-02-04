# RequestBody: Automatic Unwrapping

The `RequestBody` wrapper is used only at the type level for specification. Your handlers receive the **unwrapped inner value** directly!

## Before vs After

### ❌ Before: Manual Pattern Matching (What You Didn't Want)

```purescript
type CreateUserSpec = ( body :: RequestBody CreateUserRequest )

handler { path, body } = case body of
  JSONBody user -> do              -- 😞 Manual pattern matching
    createUser user.name user.email
  FormData fields -> do
    createFromForm fields
  _ -> error
```

### ✅ After: Automatic Unwrapping (What You Asked For!)

```purescript
type CreateUserSpec = ( body :: RequestBody CreateUserRequest )

handler { path, body } = do
  -- body :: CreateUserRequest (already unwrapped!) 🎉
  createUser body.name body.email
  -- No pattern matching needed!
```

## How It Works

The `RequestBody` type is a **marker** at the spec level:

1. **Spec Level**: You write `body :: RequestBody CreateUserRequest`
2. **Parsing Stage**: Framework determines Content-Type and parses accordingly
3. **Handler Level**: You receive `body :: CreateUserRequest` (unwrapped!)

```purescript
-- Spec uses RequestBody wrapper
type CreateUserSpec =
  ( body :: RequestBody CreateUserRequest
  )

-- Handler receives unwrapped type!
handler :: EndpointHandler2
  ApiRoute
  ()
  ()
  CreateUserRequest  -- ← No RequestBody wrapper!
  User
  AppContext
  ()
handler { path, body } = do
  -- body :: CreateUserRequest
  let { name, email } = body  -- Direct access!
  newUser <- createUser name email
  pure newUser
```

## Complete Example

```purescript
module Example where

import Prelude
import Data.Generic.Rep (class Generic)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG
import Type.Proxy (Proxy(..))
import Yoga.Fastify.Om.Endpoint2 as E2
import Yoga.Fastify.Om.RequestBody (RequestBody)

-- API Types
type CreateUserRequest = { name :: String, email :: String }
type User = { id :: Int, name :: String, email :: String }

data ApiRoute = CreateUser

derive instance Generic ApiRoute _

apiRoute :: RouteDuplex' ApiRoute
apiRoute = RD.root $ RG.sum
  { "CreateUser": "api" / "users" / RG.noArgs
  }

-- Endpoint Spec (uses RequestBody wrapper)
type CreateUserSpec =
  ( body :: RequestBody CreateUserRequest
  )

createUserEndpoint :: E2.Endpoint2 ApiRoute CreateUserSpec User
createUserEndpoint = E2.endpoint2 apiRoute (Proxy :: Proxy CreateUserSpec) (Proxy :: Proxy User)

-- Handler (receives unwrapped body!)
createUserHandler
  :: E2.EndpointHandler2
       ApiRoute
       ()
       ()
       CreateUserRequest  -- ← Unwrapped! No RequestBody!
       User
       ()
       ()
createUserHandler { path, body } = do
  -- body :: CreateUserRequest (unwrapped!)
  let { name, email } = body
  
  -- No pattern matching needed - just use it directly!
  pure
    { id: 42
    , name
    , email
    }
```

## Testing It

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'

# Response: {"id":42,"name":"Alice","email":"alice@example.com"}
```

## Why This Is Better

### ✅ Clean Handler Logic

No pattern matching clutter:
```purescript
handler { body } = do
  createUser body.name body.email  -- Direct access!
```

### ✅ Type Safety Maintained

The type system still knows what `body` is:
```purescript
handler { body } = do
  let name = body.name   -- ✅ Compiler knows body has .name
  let wrong = body.age   -- ❌ Compiler error: no .age field
  pure response
```

### ✅ Content-Type Handling Automatic

The framework checks `Content-Type` header and parses accordingly:
- `application/json` → parses via `ReadForeign`
- Returns unwrapped typed value to your handler

### ✅ No Boilerplate

Before, you'd need:
```purescript
handler { body } = case body of
  JSONBody user -> doStuff user      -- 3 lines of boilerplate
  _ -> pure errorResponse
```

Now:
```purescript
handler { body } = doStuff body      -- 1 line, direct access
```

## Summary

- **Spec**: Use `RequestBody SomeType` to mark the body field
- **Handler**: Receive `SomeType` directly (unwrapped)
- **No Pattern Matching**: Framework handles it for you
- **Type Safe**: Compiler validates structure

**This is exactly what you asked for!** 🎉
