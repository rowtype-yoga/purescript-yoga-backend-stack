# Union Constraint Implementation TODO

## Current Status

The record-based API is working with **all 55 tests passing**, but currently requires users to specify all three fields (`query`, `headers`, `body`) explicitly:

```purescript
-- ✅ Current (works)
type MyRequest =
  { query :: Record ()
  , headers :: Record ()
  , body :: RequestBody CreateUser
  }

-- ❌ Desired (blocked)
type MyRequest = { body :: RequestBody CreateUser }
-- Should auto-fill: query :: Record (), headers :: Record ()
```

## The Problem

PureScript's `Union` constraint cannot merge rows with overlapping field names:

```purescript
type UserInput = ( body :: RequestBody CreateUser )
type Defaults = ( body :: RequestBody Unit, query :: Record (), headers :: Record () )

-- ❌ Union UserInput Defaults result
-- Error: "body" appears in both rows
```

## The Solution (Opt + UnsafeCoerce)

Using `undefined-is-not-a-problem`'s `Opt` type with `unsafeCoerce`:

### Step 1: Define Parameterized Request Type

```purescript
-- Already implemented:
type OptsR :: (Type -> Type) -> Type -> Type -> Type -> Type
type OptsR f q h b =
  { query :: f q
  , headers :: f h
  , body :: f b
  }

type OptsOpt q h b = OptsR Opt q h b  -- Optional (Opt-wrapped)
type Opts q h b = OptsR Id q h b      -- Actual (Id-wrapped)
```

### Step 2: Wrap Defaults in Opt

```purescript
-- Already implemented:
type EndpointDefaults =
  ( query :: Opt (Record ())
  , headers :: Opt (Record ())
  , body :: Opt (RequestBody Unit)
  )
```

### Step 3: Transform User Input (TODO)

Need a typeclass to wrap user's fields in `Opt`:

```purescript
class WrapInOpt (input :: Row Type) (output :: Row Type) | input -> output

-- Example instances:
instance WrapInOpt ( body :: RequestBody A )
                   ( body :: Opt (RequestBody A) )

instance WrapInOpt ( query :: Record Q, body :: RequestBody A )
                   ( query :: Opt (Record Q), body :: Opt (RequestBody A) )
```

### Step 4: Union + Coerce

```purescript
endpoint2
  :: forall path request requestOpt request' response
   . WrapInOpt request requestOpt              -- Wrap user fields in Opt
  => Union requestOpt EndpointDefaults request' -- Union (no overlap now!)
  => Nub request' request'
  => RouteDuplex' path
  -> Proxy (Record request)
  -> Proxy response
  -> Endpoint2 path (OptsOpt ??? ??? ???) response  -- Result is Opt-wrapped
endpoint2 pathCodec _ responseType =
  let
    -- After Union: all fields in Opt
    optVersion :: Proxy (OptsOpt q h b)
    optVersion = Proxy
    
    -- UnsafeCoerce: Opt → Id (undefined becomes default)
    idVersion :: Proxy (Opts q h b)
    idVersion = unsafeCoerce optVersion
  in
    Endpoint2
      { pathCodec
      , requestType: idVersion  -- Or just coerce the whole thing?
      , responseType
      }
```

### Step 5: Update Parsing

ParseRequest needs to handle both `Opt` and `Id` wrapped values, providing defaults for undefined:

```purescript
class ParseRequest (r :: Row Type) where
  parseRequest :: Object Foreign -> Object String -> Maybe Foreign -> Either String (Record r)

-- Handle Opt-wrapped fields:
-- - If undefined at runtime → use default
-- - If present → extract value
```

## Alternative Approaches

### 1. Type-Level Row Difference

Instead of Union, compute `Defaults \ UserInput` and merge:

```purescript
class RowDifference (a :: Row Type) (b :: Row Type) (diff :: Row Type) | a b -> diff
-- diff = fields in b that are NOT in a

-- Then:
class MergeWithDefaults (user :: Row Type) (defaults :: Row Type) (result :: Row Type)
  | user defaults -> result where
  -- result = user + (defaults \ user)
```

### 2. HList-Style Explicit Construction

Build the record incrementally using `Record.Builder`:

```purescript
endpoint2Builder
  :: forall path response
   . RouteDuplex' path
  -> Proxy response
  -> { withQuery :: forall q. Proxy q -> ...
     , withHeaders :: forall h. Proxy h -> ...
     , withBody :: forall b. Proxy b -> ...
     }
```

### 3. Accept Runtime Coercion

Current approach: just `unsafeCoerce` and trust runtime behavior:

```purescript
endpoint2 pathCodec (Proxy :: Proxy { body :: RequestBody A }) responseProxy
-- At runtime: unsafeCoerce to { query :: ???, headers :: ???, body :: RequestBody A }
-- Missing fields are `undefined` in JS
-- Parsers handle undefined gracefully
```

## References

- `undefined-is-not-a-problem`: https://pursuit.purescript.org/packages/purescript-undefined-is-not-a-problem
- `forgetmenot` (Id type): https://pursuit.purescript.org/packages/purescript-forgetmenot
- PureScript Union constraint: https://github.com/purescript/documentation/blob/master/language/Types.md#constrained-types

## Next Steps

1. Implement `WrapInOpt` typeclass with RowList traversal
2. Update `endpoint2` signature with WrapInOpt + Union
3. Add ParseRequest handling for Opt-wrapped fields  
4. Test field omission patterns
5. Update documentation with examples

## Current Workaround

For now, specify all three fields explicitly:

```purescript
type MyRequest =
  { query :: Record ()       -- Explicitly empty
  , headers :: Record ()     -- Explicitly empty  
  , body :: RequestBody CreateUser
  }
```

This works perfectly and all tests pass (55/55).
