# Kysely ORM Usage Guide

## Quick Start

### Basic CRUD with Repositories

```typescript
import { itemRepository, categoryRepository } from '@/orm'

// CREATE
const newItem = await itemRepository.createItem({
  name: 'Wireless Headphones',
  description: 'Premium audio device',
  categoryId: 1,
  price: 199.99,
})
// Returns: { id: 1, name, description, categoryId, price, createdAt, updatedAt }

// READ
const item = await itemRepository.findById(1)
const allItems = await itemRepository.findAll(10) // limit 10
const itemsByCategory = await itemRepository.findByCategory(1)
const results = await itemRepository.search('headphones')

// UPDATE
const updated = await itemRepository.updateItem(1, {
  price: 179.99,
  description: 'Updated description',
})
// Note: createdAt is NOT updated, updatedAt is auto-set

// DELETE
await itemRepository.delete(1)

// CHECK
const exists = await itemRepository.exists(1)
const count = await itemRepository.count()
const categoryCount = await itemRepository.countByCategory(1)
```

### Category Operations

```typescript
// CREATE
const category = await categoryRepository.createCategory({
  name: 'Electronics',
  description: 'Electronic devices and accessories',
})

// READ
const all = await categoryRepository.findAllSorted() // ordered by name
const byName = await categoryRepository.findByName('Electronics')
const search = await categoryRepository.searchByName('elec') // partial match

// UPDATE
const updated = await categoryRepository.updateCategory(1, {
  description: 'New description',
})

// DELETE
await categoryRepository.delete(1)
```

## Advanced Queries

### Custom Queries in Domain Repositories

Extend repositories with business-specific methods:

```typescript
// In ItemRepository
export class ItemRepository extends Repository<'items'> {
  // Existing methods...

  async findExpensiveItems(threshold: number) {
    return this.db
      .selectFrom('items')
      .selectAll()
      .where('price', '>', threshold)
      .orderBy('price', 'desc')
      .execute()
  }

  async findItemsCreatedAfter(date: Date) {
    return this.db
      .selectFrom('items')
      .selectAll()
      .where('createdAt', '>', date)
      .orderBy('createdAt', 'desc')
      .execute()
  }

  async getItemStatsByCategory() {
    return this.db
      .selectFrom('items')
      .select([
        'categoryId',
        eb => eb.fn.count<number>('*').as('count'),
        eb => eb.fn('avg', [eb.ref('price')]).as('avgPrice'),
      ])
      .groupBy('categoryId')
      .execute()
  }
}
```

### Direct Database Queries

For complex queries, use `db` directly:

```typescript
import { db } from '@/orm/db'

// Complex join with conditions
const result = await db
  .selectFrom('items')
  .innerJoin('categories', 'items.categoryId', 'categories.id')
  .select([
    'items.id',
    'items.name',
    'items.price',
    'categories.name as categoryName',
  ])
  .where('items.price', '>', 100)
  .orderBy('items.price', 'desc')
  .execute()

// Subqueries
const expensive = await db
  .selectFrom('items')
  .selectAll()
  .where(
    'price',
    '>',
    db.selectFrom('items').select(eb => eb.fn('avg', [eb.ref('price')]))
  )
  .execute()

// Transactions
await db.transaction().execute(async trx => {
  const newItem = await trx
    .insertInto('items')
    .values(itemData)
    .returningAll()
    .executeTakeFirstOrThrow()

  await trx
    .updateTable('categories')
    .set({ updatedAt: new Date() })
    .where('id', '=', itemData.categoryId)
    .execute()

  return newItem
})
```

## Type Safety Examples

### Typed Results

```typescript
import type { ItemRow, NewItem, ItemUpdate } from '@/orm'

// Result is typed as ItemRow[]
const items: ItemRow[] = await itemRepository.findAll()

// Each item has proper type hints
items.forEach(item => {
  console.log(item.id) // number
  console.log(item.name) // string
  console.log(item.createdAt) // Date
  // item.nonExistent // TypeScript error!
})

// New item data type
const newItemData: NewItem = {
  id: 1, // Generated, required in interface
  name: 'Product',
  categoryId: 1,
  price: 9.99,
  createdAt: new Date(), // Generated
  description: null, // Optional field
  updatedAt: new Date(),
}

// Update data type
const update: ItemUpdate = {
  name: 'Updated Name',
  price: 19.99,
  // Other fields optional
}
```

## Error Handling

```typescript
import { mapDbError } from '@/orm'

try {
  await itemRepository.createItem({
    name: 'Duplicate Name', // violates unique constraint
    categoryId: 1,
    price: 99.99,
  })
} catch (error) {
  const mapped = mapDbError(error)
  if (mapped.code === 'UNIQUE_VIOLATION') {
    console.log('Item name already exists')
  }
}
```

## Common Patterns

### Pagination

```typescript
const page = 2
const pageSize = 20
const offset = (page - 1) * pageSize

const items = await db
  .selectFrom('items')
  .selectAll()
  .limit(pageSize)
  .offset(offset)
  .execute()

const total = await itemRepository.count()
const totalPages = Math.ceil(total / pageSize)
```

### Filtering

```typescript
const filters = {
  categoryId: 1,
  minPrice: 50,
  maxPrice: 500,
  search: 'wireless',
}

let query = db.selectFrom('items').selectAll()

if (filters.categoryId) {
  query = query.where('categoryId', '=', filters.categoryId)
}

if (filters.minPrice) {
  query = query.where('price', '>=', filters.minPrice)
}

if (filters.maxPrice) {
  query = query.where('price', '<=', filters.maxPrice)
}

if (filters.search) {
  query = query.where(eb =>
    eb.or([
      eb(eb.fn('lower', [eb.ref('name')]), 'like', `%${filters.search.toLowerCase()}%`),
      eb(eb.fn('lower', [eb.ref('description')]), 'like', `%${filters.search.toLowerCase()}%`),
    ])
  )
}

const results = await query.execute()
```

### Bulk Operations

```typescript
// Batch insert
const items = [
  { name: 'Item 1', categoryId: 1, price: 10 },
  { name: 'Item 2', categoryId: 1, price: 20 },
  { name: 'Item 3', categoryId: 2, price: 30 },
]

const inserted = await db
  .insertInto('items')
  .values(
    items.map(item => ({
      ...item,
      createdAt: new Date(),
      updatedAt: new Date(),
    }))
  )
  .returningAll()
  .execute()

// Batch delete
await db
  .deleteFrom('items')
  .where('id', 'in', [1, 2, 3])
  .execute()
```

## Testing

```typescript
import { db } from '@/orm/db'
import type { ItemRow } from '@/orm'

describe('ItemRepository', () => {
  beforeEach(async () => {
    // Clear tables
    await db.deleteFrom('items').execute()
    await db.deleteFrom('categories').execute()
  })

  it('should find items by category', async () => {
    const category = await db
      .insertInto('categories')
      .values({ name: 'Electronics', createdAt: new Date(), updatedAt: new Date() })
      .returningAll()
      .executeTakeFirstOrThrow()

    const item = await db
      .insertInto('items')
      .values({
        name: 'Laptop',
        categoryId: category.id,
        price: 999,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returningAll()
      .executeTakeFirstOrThrow()

    const result = await itemRepository.findByCategory(category.id)
    expect(result).toHaveLength(1)
    expect(result[0].id).toBe(item.id)
  })
})
```

## Resources

- [Kysely Documentation](https://kysely.dev)
- [SQLite Dialect Guide](https://kysely.dev/docs/dialects/sqlite)
- [Type Safety Best Practices](https://kysely.dev/docs/type-safety)
