# Query Parameter Architecture

## Problem Statement

How should Fastify query parameters be typed in PureScript bindings?

## TypeScript Reference

In Fastify's TypeScript definitions:

```typescript
// types/utils.d.ts
export type RequestQuerystringDefault = unknown

// types/request.d.ts
export interface FastifyRequest<RouteGeneric...> {
  query: RequestType['query'];  // Generic, defaults to 'unknown'
  // ...
}
```

**Key insight**: TypeScript types query params as `unknown` (not `string`), because:
1. Fastify supports **custom querystring parsers**
2. Default parser (`fast-querystring`) produces `{ [key: string]: string | string[] }`
3. TypeScript forces explicit typing via generics

## Our Architectural Decision

### Layer 1: FFI Bindings (`yoga-fastify`)

**Type query params as `Foreign`** to match TypeScript's `unknown`:

```purescript
-- Yoga.Fastify.Fastify
query :: FastifyRequest -> Effect (Object Foreign)
```

**Rationale**:
- ✅ Matches TypeScript's type (`unknown` ≈ `Foreign`)
- ✅ Supports custom querystring parsers
- ✅ Honest about what JavaScript provides
- ✅ Pushes type safety to higher layers (correct architectural separation)

### Layer 2: High-Level Helpers (`yoga-fastify-om`)

**Provide typed helpers using `yoga-json` for decoding**:

```purescript
-- Current implementation (temporary)
type RequestContext = { query :: Object Foreign, ... }

-- Parse with ParseParam typeclass (simple String -> ty)
requiredQueryParams :: Proxy (page :: Int, limit :: Int) -> Om ctx err { page :: Int, limit :: Int }

-- TODO: Integrate yoga-json's ReadForeign
-- Future: J.readJSON or J.readImpl for Foreign -> ty
```

**Current State**:
- Uses `unsafeCoerce Foreign -> String` (safe for default parser)
- Uses `ParseParam String -> Maybe ty` for parsing
- Accumulates all missing and invalid field errors

**Future State**:
- Replace `unsafeCoerce` with `yoga-json`'s `ReadForeign` typeclass
- Support complex types (nested objects, arrays, custom parsers)
- Type-safe Foreign decoding throughout

## Code Examples

### Current Usage

```purescript
handler :: FastifyReply -> Om { httpRequest :: RequestContext } err Unit
handler reply = do
  -- Single query param
  page <- FO.requiredQueryParam "page"  -- Returns Foreign
  
  -- Multiple query params with type parsing
  { limit, sort } <- FO.requiredQueryParams 
    (Proxy :: Proxy (limit :: Int, sort :: String))
  
  -- With error accumulation
  result <- FO.requiredQueryParams (Proxy :: Proxy (userId :: Int, postId :: String))
    # Om.handleErrors
        { queryParamErrors: \errs -> do
            -- errs.missing :: Array String (all missing fields)
            -- errs.invalid :: Array String (all unparseable fields)
            pure defaultValues
        }
```

### Future with yoga-json

```purescript
-- Define custom query type
type SearchQuery = { q :: String, limit :: Int, tags :: Array String }

-- Derive ReadForeign automatically
derive newtype instance ReadForeign SearchQuery

handler :: FastifyReply -> Om { httpRequest :: RequestContext } err Unit
handler reply = do
  query <- FO.requestQuery  -- Object Foreign
  
  -- Type-safe decoding
  searchQuery <- liftEffect $ J.readJSON query
  -- searchQuery :: Either ForeignErrors SearchQuery
```

## Benefits of This Approach

1. **Correct FFI Layer**: `Foreign` matches TypeScript's `unknown`
2. **Architectural Separation**: Low-level FFI vs high-level type safety
3. **Extensibility**: Supports custom querystring parsers
4. **Type Safety**: yoga-json provides proper Foreign decoding
5. **Error Handling**: Accumulates all parsing errors (not just first failure)

## Migration Path

### Phase 1: Current ✅
- FFI: `query :: Object Foreign`
- Helpers: `unsafeCoerce Foreign -> String` + `ParseParam`
- Works correctly for default Fastify parser

### Phase 2: Future
- Integrate `yoga-json`'s `ReadForeign` typeclass
- Replace `ParseParam String ty` with `ReadForeign ty`
- Remove all `unsafeCoerce` in query param handling
- Support complex nested types

### Phase 3: Advanced
- Auto-derive query param codecs
- Support custom querystring parser configurations
- Integrate with routing DSL for compile-time query validation

## Related Files

- `packages/yoga-fastify/src/Yoga/Fastify/Fastify.purs` - FFI bindings
- `packages/yoga-fastify/src/Yoga/Fastify/Fastify.js` - JavaScript FFI
- `packages/yoga-fastify-om/src/Yoga/Fastify/Om.purs` - Om integration + typed helpers
- `packages/yoga-fastify-om/test/Main.purs` - Usage examples and tests

## See Also

- [Fastify TypeScript Documentation](https://fastify.dev/docs/latest/Reference/TypeScript)
- [Fastify Request Types](https://github.com/fastify/fastify/blob/main/types/request.d.ts)
- [yoga-json Documentation](../packages/yoga-json/) (TODO)
