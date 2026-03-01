# TypeScript → Bun + ReScript Migration

## Overview

This branch (`migration/bun-rescript`) is a complete architectural redesign of demo-api:

**FROM:** TypeScript + Node.js + better-sqlite3 + Zod + Express + class-based errors
**TO:** ReScript + Bun + Bun.sql + rescript-schema + Express + variant-based errors

## Key Architectural Changes

### 1. Concrete QueryBuilder (No Generics)

**Previous (TypeScript):** Generic `QueryBuilder<T>` with type parameters, dynamic column bindings, escape hatches via `unknown`.

**New (ReScript):** Explicit, concrete query functions:
- `selectAll()`, `findById()`, `findByCategory()`, `findByName()`, `findWithPagination()`
- `insertItem()`, `updateItem()`, `deleteById()`
- Utility: `exists()`, `count()`

**Benefits:**
- ✅ All query logic visible and debuggable
- ✅ No abstraction complexity
- ✅ Scales easily (add `CategoryQueryBuilder`, etc.)
- ✅ Type signatures are explicit

### 2. Type-Safe Error Handling

**Previous:** `AppError` class with `instanceof` checks and null guards.

**New:** `AppError.t` variant with exhaustive pattern matching:
```rescript
type t =
  | NotFound(string)
  | ValidationError(array<string>)
  | Conflict(string)
  | Unauthorized(string)
  | Forbidden(string)
  | Internal(string)
```

**Benefits:**
- ✅ Compiler forces you to handle all cases
- ✅ No missed error scenarios at runtime
- ✅ `statusCode()`, `message()` are pure functions, not methods
- ✅ JSON error responses have correct structure

### 3. Result<T, E> Everywhere

**Previous:** Exceptions thrown and caught, or nested `.catch()` handlers.

**New:** All service functions return `Result<T, AppError.t>`:
```rescript
let getOne = (id: int): result<Item.item, AppError.t> => { ... }
let create = (input: createItemInput): result<Item.item, AppError.t> => { ... }
let update = (...): result<Item.item, AppError.t> => { ... }
let delete = (...): result<unit, AppError.t> => { ... }
```

**Benefits:**
- ✅ Errors are values, not side effects
- ✅ `Result.flatMap` chains operations with guaranteed error propagation
- ✅ Impossible to accidentally return `null` or `undefined`
- ✅ Controllers always know whether operation succeeded

### 4. Fully Type-Safe Validation

**Previous:** Zod with `z.any()` escape hatches, coercion, type inference ambiguities.

**New:** `rescript-schema` where `S.Output.t<typeof schema>` is PROVEN correct:
```rescript
let createItemSchema = schema(s => {
  {
    "name": s.field("name", s.string()->min(~length=3, ())->max(~length=100, ())),
    "description": s.field("description", s.option(s.string())),
    "categoryId": s.field("categoryId", s.int()),
  }
})

type createItemInput = S.Output.t<typeof createItemSchema> // No escape hatch
```

**Benefits:**
- ✅ Type soundness is mathematical, not heuristic
- ✅ No runtime surprises from coercion
- ✅ Validation failure messages are structured

### 5. Bun Runtime + Bun.sql

**Previous:** Node.js + better-sqlite3 (separate driver).

**New:** Bun runtime + Bun.sql (built-in, high-performance).

**Benefits:**
- ✅ No dependency on native modules
- ✅ Faster startup (Bun bootstraps in milliseconds)
- ✅ SQL bindings are optimized for Bun's event loop
- ✅ Simpler deployment (single binary concept)

## Project Structure

```
src/
├── index.res              ← Entry point (Express setup, DB init)
├── orm/
│   ├── Bun.sqlite.res    ← FFI bindings to Bun.sql
│   └── QueryBuilder.res  ← Concrete Item queries (no generics)
├── entities/
│   └── Item.res          ← Domain model + schema
├── data-source/
│   └── AppDataSource.res ← DB lifecycle, schema initialization
├── core/
│   ├── services/
│   │   └── ItemService.res  ← Business logic (Result<T, AppError>)
│   ├── dto/
│   │   └── ItemDto.res      ← Validation schemas (rescript-schema)
│   └── errors/
│       └── AppError.res     ← Type-safe error variants
├── http/
│   └── Express.res       ← Express FFI bindings
└── interface/
    └── rest/
        ├── ItemsController.res  ← Request handlers
        └── ItemsRouter.res      ← Route registration
```

## Commit Sequence

Each commit is **atomic and reviewable**. The stack follows **bottom-up layer construction**:

| # | Commit | What | Layer |
|---|--------|------|-------|
| 1 | Initialize ReScript config | `rescript.json`, ESM output | Foundation |
| 2 | Update dependencies | Add rescript, rescript-schema; remove TypeScript, tsx | Toolchain |
| 3 | Bun.sqlite FFI bindings | `Bun.sqlite.res` — database API | Database layer |
| 4 | Concrete QueryBuilder | `QueryBuilder.res` — Item-specific queries | Query layer |
| 5 | Item entity + schema | `Item.res` — domain model + SQL | Entity layer |
| 6 | rescript-schema DTOs | `ItemDto.res` — validation (replaces Zod) | Validation layer |
| 7 | Type-safe errors | `AppError.res` — variants, Result handling | Error layer |
| 8 | Business logic | `ItemService.res` — queries, mutations (Result<T, E>) | Service layer |
| 9 | DB initialization | `AppDataSource.res` — schema setup, service injection | Lifecycle layer |
| 10 | Express bindings | `Express.res` — minimal FFI for HTTP | HTTP layer |
| 11 | Controllers | `ItemsController.res` — request handlers | Handler layer |
| 12 | Router setup | `ItemsRouter.res` — route registration | Routing layer |
| 13 | Entry point | `index.res` — main app initialization | Application layer |

## Testing the Migration

### Prerequisites
```bash
install Bun: curl -fsSL https://bun.sh/install | bash
cd demo-api
git checkout migration/bun-rescript
bun install  # Install rescript, rescript-schema, dependencies
```

### Build
```bash
bun run build         # Compile ReScript → .res.js files
bun run build:watch   # Watch mode during development
```

### Run
```bash
bun run dev           # Start server (bun --watch src/index.res.js)
```

Server starts on `http://localhost:3001`.

### Test Endpoints

```bash
# Create item
curl -X POST http://localhost:3001/rest/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Widget", "description": "A useful widget", "categoryId": 1}'

# List items
curl http://localhost:3001/rest/items

# Get item by ID
curl http://localhost:3001/rest/items/1

# Update item
curl -X PUT http://localhost:3001/rest/items/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Widget"}'

# Delete item
curl -X DELETE http://localhost:3001/rest/items/1
```

## Architecture Highlights

### Dependency Injection (Simple)

```rescript
// AppDataSource.res
let initialize = async () => {
  let db = Bun.sqlite.open("./data.db")
  db->exec(Item.createTableSQL)  // Create schema
  ItemService.setDatabase(db)    // Inject DB into service
  // ...
}
```

Services get DB reference once, at startup. No factories, no complex DI.

### Error Propagation Chain

```
QueryBuilder returns itemRow
    ↓
ItemService.getOne wraps in Result<Item, AppError>
    ↓
ItemsController handles Result, converts to HTTP response
    ↓
Client gets JSON with status code, message, optional errors array
```

Every step is type-safe. Impossible to leak undefined/null or wrong HTTP status.

### No Runtime Type Coercion

```rescript
// Request body comes in as JSON
let json = { "name": "Widget", "categoryId": "1" }  // Note: categoryId is a string

// Validation fails type-safely
switch ItemDto.validateCreateItem(json) {
| Ok(input) => ... // input["categoryId"] is proven to be int
| Error(msg) => res->status(400)->json({"error": msg})
}
```

No silent coercion, no `.parseInt()` surprises.

## Next Steps (Post-Review)

### Immediate
- [ ] Test all endpoints with real HTTP clients
- [ ] Verify database file is created and schema initialized
- [ ] Check ReScript compilation time (should be fast)
- [ ] Review error messages from rescript-schema (user-friendly?)

### Short-term
- [ ] Add Category entity and queries
- [ ] Implement pagination on list endpoint
- [ ] Add request logging middleware
- [ ] Set up integration tests (if needed)

### Long-term
- [ ] Consider switching from Express to Bun.serve for better perf
- [ ] Add more entities following the same pattern
- [ ] Explore ReScript's module system for code organization
- [ ] Consider moving validation to a shared schema module

## Design Decisions

### Why Concrete QueryBuilder, Not Generic?

**Reasoning:**
- Generic types add abstraction complexity that isn't justified for 1-2 queries per entity
- Concrete functions are easier to debug and profile
- New developers can understand the code immediately
- If genericism is needed later, patterns will be clear

**Trade-off:** More code (duplicate functions per entity), but simpler code (each function is obvious).

### Why Express, Not Bun.serve?

**Reasoning:**
- Lower risk during migration (Express is battle-tested on Bun)
- Allows us to focus on business logic first, HTTP layer second
- Switch to Bun.serve is a single-commit refactor later

**Note:** Once everything works, we can profile and decide if the performance gains justify the switch.

### Why Not Classes in ReScript?

**Reasoning:**
- ReScript doesn't have traditional classes (by design)
- Variants + pattern matching are safer and more expressive than enums + instanceof
- Records for data, functions for behavior (functional style)
- Compiler forces exhaustiveness

## Potential Gotchas

### 1. FFI Bindings Are Assertions

Our Express and Bun.sqlite bindings are type assertions against JavaScript. We're saying "trust me, Express.get works like this." If the JS API changes, the bindings break silently (no type error).

**Mitigation:** Keep bindings minimal and well-tested. Consider adding runtime checks for critical APIs.

### 2. ReScript Compiler Is Strict

ReScript will not let you:
- Return `None` where a value is expected
- Match a variant without covering all cases
- Use undefined in typed contexts

This is a **feature**, but it takes adjustment if you're used to TypeScript's escape hatches.

### 3. Bun.sql Is New

Bun.sql (bun:sqlite) is actively developed. Edge cases or performance regressions may occur.

**Mitigation:** We've isolated all Bun.sql calls to `Bun.sqlite.res`. If needed, we can replace the implementation without touching business logic.

## Questions to Ask During Review

1. **Architecture clarity:** Does the bottom-up layer structure make sense? Is each commit's purpose obvious?
2. **Concrete QueryBuilder:** Is the trade-off (less abstraction, more code) acceptable?
3. **Error handling:** Is Result<T, E> too verbose, or is it the right balance?
4. **Validation:** Does rescript-schema feel right compared to Zod?
5. **Database lifecycle:** Does the AppDataSource pattern work, or should it be different?
6. **Testing strategy:** Should we add integration tests before moving to production?

## Summary

This migration trades:
- **Dynamic generics** for **explicit clarity**
- **Exceptions** for **Result<T, E>**
- **Type coercion** for **proven validation**
- **Node.js + better-sqlite3** for **Bun + Bun.sql**
- **Classes + instanceof** for **Variants + pattern matching**

The result is a codebase that is:
- ✅ Easier to understand
- ✅ Impossible to misuse (compiler enforces correctness)
- ✅ Faster to execute (Bun runtime, no type transpilation)
- ✅ Safer to refactor (exhaustive matching everywhere)
- ✅ More maintainable (less magic, more explicit intent)
