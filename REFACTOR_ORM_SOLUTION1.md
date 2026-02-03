# ORM Refactor: Kysely Solution 1

## Overview

This refactor replaces the custom ORM abstraction with **Kysely**, a type-safe TypeScript SQL query builder. The solution maintains your DDD architecture while providing better type safety, developer experience, and maintainability.

## Key Changes

### Phase 1: Database Schema & Configuration

#### `src/orm/database.ts` (NEW)
- **Schema definitions** as TypeScript interfaces:
  - `ItemTable` – Items table schema
  - `CategoryTable` – Categories table schema
  - `DatabaseSchema` – Complete schema union
- **Type exports** for CRUD operations:
  - `ItemRow`, `NewItem`, `ItemUpdate`
  - `CategoryRow`, `NewCategory`, `CategoryUpdate`

**Why this matters:**
- ✅ **Compile-time type safety** – Impossible to query non-existent columns
- ✅ **Zero runtime overhead** – Pure type definitions
- ✅ **Single source of truth** – Schema defined once, used everywhere

#### `src/orm/db.ts` (NEW)
- **Kysely database instance** initialization
- **SQLite dialect** configuration with `better-sqlite3`
- **CamelCasePlugin** for automatic `snake_case` ↔ `camelCase` conversion
- Respects `DB_PATH` environment variable

### Phase 3: Repository Pattern Refactored

#### `src/orm/Repository.ts` (REFACTORED)
- **Generic base class** using Kysely query builder
- **Common CRUD operations**:
  - `findById()` – Get by primary key
  - `findAll()` – List with optional limit
  - `create()` – Insert with returning
  - `update()` – Update by id with returning
  - `delete()` – Delete by id
  - `count()` – Get total count
  - `exists()` – Check existence
- **Protected `query()` method** – Allows domain repos to extend base queries

**Architecture benefit:**
- Separation of Concerns: Generic logic in base class, domain logic in subclasses
- DRY principle: No code duplication across repositories

#### `src/orm/repositories/ItemRepository.ts` (NEW)
- **Domain-specific Item queries**:
  - `findByCategory(categoryId)` – Get items in category
  - `findByName(name)` – Exact name match
  - `search(query)` – Partial name/description search
  - `findWithCategory()` – Items with category join
  - `countByCategory(categoryId)` – Count per category
  - `findByPriceRange(min, max)` – Price filtering
  - `createItem()` – Create with timestamps
  - `updateItem()` – Update with timestamp
- **Singleton export** for dependency injection

#### `src/orm/repositories/CategoryRepository.ts` (NEW)
- **Domain-specific Category queries**:
  - `findByName(name)` – Exact name match
  - `searchByName(query)` – Partial search
  - `findAllSorted()` – Sorted by name
  - `createCategory()` – Create with timestamps
  - `updateCategory()` – Update with timestamp
- **Singleton export** for dependency injection

#### `src/orm/index.ts` (UPDATED)
- **Centralized exports** for:
  - Database instance and types
  - Repository classes and singletons
  - Schema types (ItemRow, NewItem, etc.)
  - Error mapper utilities

## Migration Path

If you had existing code using the old ORM:

```typescript
// OLD (TypeORM/custom ORM style)
const item = await itemRepository.find({ where: { id: 1 } })

// NEW (Kysely style)
const item = await itemRepository.findById(1)

// OLD (Custom query builder)
await db.query('SELECT * FROM items WHERE category_id = ?', [catId])

// NEW (Kysely type-safe)
const items = await itemRepository.findByCategory(catId)
```

## Design Principles Applied

### ✅ KISS (Keep It Simple, Stupid)
- No magic decorators – explicit type definitions
- No hidden abstractions – queries are readable SQL
- Direct, predictable API surface

### ✅ YAGNI (You Ain't Gonna Need It)
- Only essential methods in base Repository
- Domain repos extend with specific queries (not pre-emptively added)
- No unused abstraction layers

### ✅ Separation of Concerns
- **Database schema** – `database.ts` (types only)
- **Database instance** – `db.ts` (initialization)
- **Generic persistence** – `Repository.ts` (base abstraction)
- **Domain logic** – `repositories/ItemRepository.ts`, `CategoryRepository.ts` (business queries)
- **Error handling** – `dbErrorMapper.ts` (existing)

## Type Safety Benefits

```typescript
// ✅ COMPILE-TIME ERROR – Cannot query non-existent column
const item = await db
  .selectFrom('items')
  .where('nonExistent', '=', 'value')
  .executeTakeFirst()
  // ^ TypeScript error: Property 'nonExistent' not found

// ✅ COMPILE-TIME ERROR – Wrong table name
const result = await db
  .selectFrom('nonExistentTable')
  .selectAll()
  .execute()
  // ^ TypeScript error: Type '"nonExistentTable"' is not assignable to...

// ✅ COMPILE-TIME SAFETY – Correct queries
const item = await itemRepository.findById(1) // ✓ Works
const items = await itemRepository.findByCategory(2) // ✓ Type-safe
const categories = await categoryRepository.findAllSorted() // ✓ Correct types
```

## Next Steps

1. **Install Kysely dependencies**:
   ```bash
   npm install kysely better-sqlite3
   npm install -D @types/better-sqlite3
   ```

2. **Update your service layer** to use new repositories:
   ```typescript
   import { itemRepository, categoryRepository } from '@/orm'
   
   export class ItemService {
     async getItemsByCategory(categoryId: number) {
       return itemRepository.findByCategory(categoryId)
     }
   }
   ```

3. **Update imports** in controllers/middleware:
   ```typescript
   import { itemRepository } from '@/orm'
   // Instead of: from './orm/ItemRepository'
   ```

4. **Remove deprecated files** when confident:
   - `src/orm/decorators.ts` – No longer needed
   - `src/orm/QueryBuilder.ts` – Replaced by Kysely
   - `src/orm/schemaFactory.ts` – Replaced by `database.ts`
   - `src/orm/Filter.ts` – Replaced by Kysely expressions

## Performance Characteristics

| Metric | Old | New (Kysely) |
|--------|-----|----|
| Query execution | Direct SQL | Direct SQL (identical) |
| Type checking | Runtime | Compile-time |
| Bundle size | Custom builder | Minimal (query builder only) |
| Developer DX | Decorators + runtime | Explicit types + IDE autocomplete |
| Testing difficulty | Mocking ORM | Raw SQL assertions |

## Error Handling

The existing `dbErrorMapper.ts` remains unchanged and should handle Kysely errors correctly since both ultimately throw native database errors.

```typescript
import { mapDbError } from '@/orm'

try {
  await itemRepository.create(data)
} catch (error) {
  const mapped = mapDbError(error)
  // Handle UNIQUE_VIOLATION, FK_VIOLATION, etc.
}
```

## Questions?

- **Q:** Why Kysely over Prisma?
  - **A:** Type-safe without code generation. Better for DDD. Zero config.
  
- **Q:** Why not drizzle-orm?
  - **A:** Kysely is more established, better SQLite support, simpler API.
  
- **Q:** How do I write custom queries?
  - **A:** Extend repositories with domain methods using `this.db` directly.

---

**Commit:** Phase 1 (Schema) + Phase 3 (Repositories)  
**Branch:** `refactor/orm-solution1`
